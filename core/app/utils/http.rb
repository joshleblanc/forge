# Forge::Http — async HTTP client backed by DragonRuby's GTK API.
#
#   req = Forge::Http.get("https://forge.game/api/packages/health/latest")
#   req.on_complete do |response|
#     puts response.code     # 200
#     puts response.body     # "..."
#     puts response.success? # true
#   end
#
# All requests are asynchronous (DragonRuby's only HTTP API is async). The
# callback fires the first time `Forge::Http.tick` polls and observes the
# underlying GTK handle's `:complete => true`. `Forge.tick(args)` calls
# `Forge::Http.tick` automatically every frame, so as long as your game's
# `tick` is running, pending requests will resolve.

module Forge
  module Http
    # Outcome of a completed HTTP request.
    class Response
      attr_reader :code, :body, :error

      def initialize(code:, body:, error: nil)
        @code  = code.to_i
        @body  = body.to_s
        @error = error
      end

      def success?;    @error.nil? && @code >= 200 && @code < 300; end
      def not_found?;  @code == 404; end
      def forbidden?;  @code == 403; end
    end

    # A pending HTTP request. Use `#on_complete { |response| ... }` to
    # register a callback. Already-fulfilled requests fire the callback
    # immediately.
    class Request
      attr_reader :response

      def initialize(handle)
        @handle    = handle
        @callbacks = []
        @response  = nil
        @complete  = false
      end

      def complete?; @complete; end

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
        return false unless @handle && @handle[:complete]

        if @handle[:http_response_code].to_i.zero?
          fulfill(Response.new(code: 0, body: "", error: "request failed"))
        else
          fulfill(Response.new(code: @handle[:http_response_code], body: @handle[:response_data].to_s))
        end
        true
      end

      private

      def fulfill(response)
        return if @complete
        @complete = true
        @response = response
        @callbacks.each { |cb| cb.call(response) }
        @callbacks.clear
      end
    end

    class << self
      # Issue a GET. Headers is a Hash {"Accept" => "application/json"};
      # converted to the array-of-strings format GTK expects.
      def get(url, headers: {})
        register(Request.new(GTK.http_get(url, gtk_headers(headers))))
      end

      # POST a raw body. headers must include the Content-Type.
      def post_body(url, body, headers: {})
        headers = headers.merge("Content-Length" => body.bytesize.to_s)
        register(Request.new(GTK.http_post_body(url, body, gtk_headers(headers))))
      end

      # POST form-encoded fields.
      def post_form(url, fields, headers: {})
        unless headers.any? { |k, _| k.to_s.downcase == "content-type" }
          headers = headers.merge("Content-Type" => "application/x-www-form-urlencoded")
        end
        register(Request.new(GTK.http_post(url, fields, gtk_headers(headers))))
      end

      # Drive every pending request once. Called from Forge.tick.
      def tick
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
    end
  end
end
