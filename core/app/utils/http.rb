# frozen_string_literal: true

# Forge::Http — unified HTTP client for both DragonRuby (async via GTK) and MRI
# (sync via Net::HTTP). All callers use the same Request object:
#
#   req = Forge::Http.get("https://forge.game/api/packages/health/latest")
#   req.on_complete do |response|
#     puts response.code
#     puts response.body
#   end
#
# On MRI the request is performed synchronously and the callback runs
# immediately. On DragonRuby the callback fires the first time
# `Forge::Http.tick` (driven by `Forge.tick(args)`) polls and observes the
# underlying GTK handle's `:complete => true`.
#
# This means library code can be written once in a callback style and works
# on both runtimes. To "block" on MRI, just call `req.body` — it's already
# populated. On DragonRuby, callers must wait for the callback to fire.

module Forge
  module Http
    DR_RUNTIME = defined?(GTK) && GTK.respond_to?(:http_get)

    # Outcome of a completed HTTP request — uniform shape regardless of runtime.
    class Response
      attr_reader :code, :body, :error

      def initialize(code:, body:, error: nil)
        @code  = code.to_i
        @body  = body.to_s
        @error = error
      end

      def success?
        @error.nil? && @code >= 200 && @code < 300
      end

      def not_found?
        @code == 404
      end

      def forbidden?
        @code == 403
      end
    end

    # A pending HTTP request. Already-complete on MRI; backed by a GTK handle
    # on DragonRuby. Use `#on_complete { |response| ... }` to register a
    # callback. If the request is already complete the callback fires
    # immediately.
    class Request
      attr_reader :response

      def initialize
        @callbacks = []
        @response  = nil
        @complete  = false
      end

      def complete?
        @complete
      end

      def on_complete(&block)
        if @complete
          block.call(@response)
        else
          @callbacks << block
        end
        self
      end

      # Internal: drive the request forward. Returns true once complete.
      def poll
        return true if @complete
        do_poll
      end

      protected

      # Subclasses override to advance the underlying request and call
      # `#fulfill(response)` when done.
      def do_poll
        false
      end

      def fulfill(response)
        return if @complete
        @complete = true
        @response = response
        @callbacks.each { |cb| cb.call(response) }
        @callbacks.clear
      end
    end

    # Sync request — already complete by the time it's constructed (MRI).
    class SyncRequest < Request
      def initialize(response)
        super()
        fulfill(response)
      end
    end

    # Async request — wraps a GTK http_* handle (DragonRuby).
    class GtkRequest < Request
      def initialize(handle)
        super()
        @handle = handle
      end

      protected

      def do_poll
        return false unless @handle && @handle[:complete]

        if @handle[:http_response_code].to_i.zero?
          fulfill(Response.new(code: 0, body: "", error: "request failed"))
        else
          fulfill(Response.new(code: @handle[:http_response_code], body: @handle[:response_data].to_s))
        end
        true
      end
    end

    class << self
      # Issue a GET request. Headers is a Hash {"Accept" => "application/json"};
      # converted to the array-of-strings format GTK expects.
      def get(url, headers: {})
        if DR_RUNTIME
          handle = GTK.http_get(url, gtk_headers(headers))
          register(GtkRequest.new(handle))
        else
          SyncRequest.new(net_http_get(url, headers))
        end
      end

      # POST a raw body. headers must include the Content-Type.
      def post_body(url, body, headers: {})
        if DR_RUNTIME
          headers = headers.merge("Content-Length" => body.bytesize.to_s)
          handle = GTK.http_post_body(url, body, gtk_headers(headers))
          register(GtkRequest.new(handle))
        else
          SyncRequest.new(net_http_post_body(url, body, headers))
        end
      end

      # POST form-encoded fields.
      def post_form(url, fields, headers: {})
        if DR_RUNTIME
          headers = headers.merge("Content-Type" => "application/x-www-form-urlencoded") unless headers.any? { |k, _| k.to_s.downcase == "content-type" }
          handle = GTK.http_post(url, fields, gtk_headers(headers))
          register(GtkRequest.new(handle))
        else
          SyncRequest.new(net_http_post_form(url, fields, headers))
        end
      end

      # Drive every pending async request once. Called from Forge.tick.
      # No-op on MRI (sync requests are already complete).
      def tick
        return unless DR_RUNTIME
        pending.reject!(&:poll)
      end

      def pending
        @pending ||= []
      end

      private

      def register(request)
        pending << request
        request
      end

      def gtk_headers(headers)
        headers.map { |k, v| "#{k}: #{v}" }
      end

      # ---- MRI fallback (Net::HTTP) ------------------------------------

      def net_http_get(url, headers)
        require_net_http
        uri = URI(url)
        req = Net::HTTP::Get.new(uri)
        headers.each { |k, v| req[k.to_s] = v.to_s }
        run_net_http(uri, req)
      end

      def net_http_post_body(url, body, headers)
        require_net_http
        uri = URI(url)
        req = Net::HTTP::Post.new(uri)
        headers.each { |k, v| req[k.to_s] = v.to_s }
        req["Content-Type"] ||= "application/octet-stream"
        req.body = body
        run_net_http(uri, req)
      end

      def net_http_post_form(url, fields, headers)
        require_net_http
        uri = URI(url)
        req = Net::HTTP::Post.new(uri)
        headers.each { |k, v| req[k.to_s] = v.to_s }
        req["Content-Type"] ||= "application/x-www-form-urlencoded"
        req.set_form_data(fields)
        run_net_http(uri, req)
      end

      def run_net_http(uri, req)
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |h| h.request(req) }
        Response.new(code: res.code, body: res.body)
      rescue => e
        Response.new(code: 0, body: "", error: e.message)
      end

      def require_net_http
        return if defined?(Net::HTTP)
        require "net/http"
        require "uri"
      end
    end
  end
end
