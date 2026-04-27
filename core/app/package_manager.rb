# Forge Package Manager
# Handles installing, removing, and publishing packages from forge.game
#
# Usage:
#   Forge.add_package("health-system")
#   Forge.remove_package("health-system")
#   Forge.update_packages
#   Forge.list_installed
#   Forge.publish_package(name: "my-script", version: "1.0.0", ...)
#
# All API calls use the user's API key from api_key.rb (generated on project download).

# Stdlib requires only when running outside DragonRuby (e.g., tooling, tests).
# DragonRuby's mruby runtime doesn't ship these — JSON is replaced by Forge::JSON
# and HTTP by Forge::Http (which dispatches to GTK.http_get / GTK.http_post on
# DragonRuby and Net::HTTP elsewhere).
unless defined?(GTK)
  # Zlib is used by the ZipReader to inflate DEFLATE entries on MRI. On
  # DragonRuby (mruby) zlib is unavailable; the server is configured to
  # serve STORED (uncompressed) archives, so the inflate path is never
  # taken there.
  require "zlib"
end

require_relative "utils/json"
require_relative "utils/http"
require_relative "utils/fs"

module Forge
  class PackageManager
    class Error < StandardError; end
    class PublishError < Error; end
    class PackageNotFound < Error; end
    class VersionNotFound < Error; end
    class AuthenticationRequired < PublishError
      def message
        "Anonymous API keys cannot publish. Register at https://forge.game to enable publishing."
      end
    end

    # Result handle for any network-touching public method.
    #
    # On MRI: Forge::Http requests complete synchronously, so `op.complete?`
    # is already true by the time the method returns; `op.result` has the
    # payload (or `op.error` if the chain failed).
    #
    # On DragonRuby: GTK.http_* requests are async, so the op resolves over
    # the next several ticks (driven by `Forge.tick(args)` polling
    # `Forge::Http.tick`). Callers must use the callback style:
    #
    #   Forge.add_package("health") do |op|
    #     if op.failed?
    #       puts "Error: #{op.error.message}"
    #     else
    #       puts "Installed #{op.result[:name]}@#{op.result[:version]}"
    #     end
    #   end
    #
    # If no block is given, completion logs to the console by default.
    class Op
      attr_reader :result, :error

      def initialize(&default_callback)
        @done       = false
        @result     = nil
        @error      = nil
        @callbacks  = []
        @callbacks << default_callback if default_callback
      end

      def complete?; @done; end
      def failed?;   @done && !@error.nil?; end
      def succeeded?; @done && @error.nil?; end

      def on_complete(&block)
        if @done
          block.call(self)
        else
          @callbacks << block
        end
        self
      end

      # Internal: complete with success.
      def fulfill_result(value)
        return if @done
        @done   = true
        @result = value
        run_callbacks
      end

      # Internal: complete with failure.
      def fail(err)
        return if @done
        @done  = true
        @error = err.is_a?(Exception) ? err : Error.new(err.to_s)
        run_callbacks
      end

      private

      def run_callbacks
        @callbacks.each { |cb| cb.call(self) }
        @callbacks.clear
      end
    end

    class << self
      # Install a package by name.
      #
      #   Forge.add_package("health-system")
      #   Forge.add_package("health-system", version: "1.2.0")
      #
      def add_package(name, version: nil, &block)
        name = normalize_name(name)
        op = Op.new(&block)

        log "Installing package: #{name}#{version ? " (version #{version})" : ""}"

        # 1. Fetch package manifest
        fetch_package_manifest(name, version) do |manifest_op|
          if manifest_op.failed?
            op.fail(manifest_op.error)
            next
          end

          manifest = manifest_op.result
          resolved_version = version || manifest["latest_version"] || manifest["version"]
          log "Resolved to version: #{resolved_version}"

          # 2. Install dependencies first (synchronous on MRI; sequential async on DR).
          deps = (manifest["dependencies"] || {}).reject { |dep, _| installed?(dep) }
          install_dependencies(deps.keys) do |deps_op|
            if deps_op.failed?
              op.fail(deps_op.error)
              next
            end

            # 3. Download zip
            download_package(name, resolved_version) do |dl_op|
              if dl_op.failed?
                op.fail(dl_op.error)
                next
              end

              # 4. Extract & 5. Register (local — no HTTP)
              extract_package(name, resolved_version, dl_op.result, manifest)
              register_package(name, resolved_version, manifest)
              log "Installed #{name}@#{resolved_version}"
              op.fulfill_result(name: name, version: resolved_version)
            end
          end
        end

        op
      end

      # Remove an installed package.
      #
      #   Forge.remove_package("health-system")
      #
      def remove_package(name)
        name = normalize_name(name)

        unless installed?(name)
          raise PackageNotFound, "Package not installed: #{name}"
        end

        # Remove package directory
        package_dir = package_path(name)
        Forge::Fs.rm_rf(package_dir) if Forge::Fs.directory?(package_dir)

        # Update lock file (the bootstrap packages.rb walks this on next start).
        lock = read_lock
        lock["packages"].delete(name)
        write_lock(lock)

        log "Removed package: #{name}"
        { name: name }
      end

      # Update all installed packages to their latest versions.
      #
      #   Forge.update_packages
      #
      def update_packages(&block)
        lock = read_lock
        updates = []
        errors = []
        op = Op.new(&block)

        names = lock["packages"].keys
        check_each = lambda do |idx|
          if idx >= names.length
            op.fulfill_result(updated: updates, errors: errors)
            next
          end
          name = names[idx]
          info = lock["packages"][name]
          fetch_latest_version(name) do |latest_op|
            if latest_op.failed?
              errors << { name: name, error: latest_op.error.message }
              check_each.call(idx + 1)
              next
            end
            latest = latest_op.result
            if version_gt?(latest, info["version"])
              add_package(name, version: latest) do |inst_op|
                if inst_op.failed?
                  errors << { name: name, error: inst_op.error.message }
                else
                  updates << { name: name, from: info["version"], to: latest }
                end
                check_each.call(idx + 1)
              end
            else
              check_each.call(idx + 1)
            end
          end
        end
        check_each.call(0)

        op
      end

      # List all installed packages.
      #
      #   Forge.list_installed
      #   # => [{ name: "health-system", version: "1.0.0", manifest: {...} }, ...]
      #
      def list_installed
        lock = read_lock
        lock["packages"].map do |name, info|
          {
            name: name,
            version: info["version"],
            manifest: info["manifest"] || {}
          }
        end
      end

      # Check if a package is installed.
      def installed?(name)
        name = normalize_name(name)
        lock = read_lock
        lock["packages"].key?(name)
      end

      # Search packages on the registry.
      #
      #   Forge.search("health")
      #   # => [{ name: "health-system", latest_version: "1.2.0", description: "..." }, ...]
      #
      def search(query, &block)
        op = Op.new(&block)
        url = api_url_for("/packages?q=#{url_encode(query)}")
        Forge::Http.get(url, headers: json_accept_headers).on_complete do |res|
          if res.success?
            data = Forge::JSON.parse(res.body) || {}
            op.fulfill_result(data["packages"] || [])
          else
            op.fail(Error.new("Search failed (#{res.code}): #{res.body}"))
          end
        end
        op
      end

      # Publish a package to the registry.
      #
      #   Forge.publish_package(
      #     name: "my-cool-script",
      #     version: "1.0.0",
      #     description: "Does cool things",
      #     scripts: ["MyCoolScript"],
      #     tags: ["gameplay"]
      #   )
      #
      # Requires a registered API key (not anonymous).
      # Anonymous keys will raise AuthenticationRequired.
      #
      def publish_package(name:, version:, description: "", scripts: [], widgets: [], assets: [], dependencies: {}, tags: [], &block)
        name = normalize_name(name)
        op = Op.new(&block)

        verify_auth do |auth_op|
          if auth_op.failed?
            op.fail(auth_op.error)
            next
          end
          unless auth_op.result["can_publish"]
            op.fail(AuthenticationRequired.new)
            next
          end

          body = Forge::JSON.generate(
            package: {
              name: name,
              latest_version: version,
              description: description,
              dragonruby_version: ">= 3.0",
              dependencies_text: dependencies.map { |k, v| "#{k} (#{v})" }.join("\n"),
              scripts_text: scripts.join("\n"),
              tags_text: tags.join(", ")
            }
          )
          Forge::Http.post_body(
            api_url_for("/packages/publish"),
            body,
            headers: json_authed_headers
          ).on_complete do |res|
            if res.forbidden?
              data = Forge::JSON.parse(res.body) || {}
              op.fail(PublishError.new(data["error"] || "forbidden"))
            elsif res.success?
              log "Published #{name}@#{version}"
              op.fulfill_result(Forge::JSON.parse(res.body) || {})
            else
              op.fail(PublishError.new("Server returned #{res.code}: #{res.body}"))
            end
          end
        end

        op
      end

      # Verify the current API key and return auth info.
      #
      #   Forge.verify_auth
      #   # => { "valid" => true, "can_publish" => true, "username" => "..." }
      #
      def verify_auth(&block)
        op = Op.new(&block)
        Forge::Http.post_body(
          api_url_for("/auth/verify"),
          Forge::JSON.generate(key: api_key),
          headers: json_authed_headers
        ).on_complete do |res|
          if res.success?
            op.fulfill_result(Forge::JSON.parse(res.body) || {})
          else
            op.fail(Error.new("Auth verify failed (#{res.code}): #{res.body}"))
          end
        end
        op
      end

      # Check if the current API key can publish. Returns an Op; .result is true/false.
      def can_publish?(&block)
        op = Op.new(&block)
        verify_auth do |auth_op|
          if auth_op.failed?
            op.fail(auth_op.error)
          else
            op.fulfill_result(auth_op.result["can_publish"] == true)
          end
        end
        op
      end

      # Get info about the current user/API key.
      def whoami(&block)
        op = Op.new(&block)
        Forge::Http.get(api_url_for("/auth/me"), headers: json_authed_headers).on_complete do |res|
          if res.success?
            op.fulfill_result(Forge::JSON.parse(res.body) || {})
          else
            op.fail(Error.new("whoami failed (#{res.code}): #{res.body}"))
          end
        end
        op
      end

      private

      def api_key
        Forge::API_KEY
      end

      def api_url
        Forge::API_URL || "https://forge.game/api"
      end

      def api_url_for(path)
        "#{api_url}#{path}"
      end

      def json_accept_headers
        { "Accept" => "application/json" }
      end

      def json_authed_headers
        {
          "Accept"        => "application/json",
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }
      end

      # Minimal URL-encoder used for query strings (URI.encode_www_form_component
      # is unavailable in DragonRuby's mruby).
      def url_encode(str)
        str.to_s.gsub(/[^A-Za-z0-9\-._~]/) { |c| c.bytes.map { |b| format("%%%02X", b) }.join }
      end

      def fetch_package_manifest(name, version = nil, &block)
        op = Op.new(&block)
        path = version ? "/packages/#{name}/versions/#{version}" : "/packages/#{name}/latest"
        Forge::Http.get(api_url_for(path), headers: json_accept_headers).on_complete do |res|
          if res.not_found?
            op.fail(PackageNotFound.new("Package not found: #{name}#{version ? "@#{version}" : ""}"))
          elsif res.success?
            op.fulfill_result(Forge::JSON.parse(res.body) || {})
          else
            op.fail(Error.new("Manifest fetch failed (#{res.code}): #{res.body}"))
          end
        end
        op
      end

      def fetch_latest_version(name, &block)
        op = Op.new(&block)
        fetch_package_manifest(name) do |manifest_op|
          if manifest_op.failed?
            op.fail(manifest_op.error)
          else
            m = manifest_op.result
            op.fulfill_result(m["version"] || m["latest_version"])
          end
        end
        op
      end

      def download_package(name, version, &block)
        op = Op.new(&block)
        Forge::Http.get(api_url_for("/packages/#{name}/versions/#{version}/download")).on_complete do |res|
          if res.not_found?
            op.fail(VersionNotFound.new("Package version not found: #{name}@#{version}"))
          elsif res.success?
            op.fulfill_result(res.body)
          else
            op.fail(Error.new("Download failed (#{res.code}): #{res.body}"))
          end
        end
        op
      end

      # Install a list of dependency packages sequentially, fulfilling the op
      # when all are done (or failing on the first error).
      def install_dependencies(names, &block)
        op = Op.new(&block)
        each = lambda do |idx|
          if idx >= names.length
            op.fulfill_result(true)
            next
          end
          add_package(names[idx]) do |dep_op|
            if dep_op.failed?
              op.fail(dep_op.error)
            else
              each.call(idx + 1)
            end
          end
        end
        each.call(0)
        op
      end

      def extract_package(name, version, zip_data, manifest)
        package_dir = package_path(name)
        Forge::Fs.mkdir_p(package_dir)

        # Write manifest
        Forge::Fs.write(
          File.join(package_dir, "manifest.json"),
          Forge::JSON.pretty(manifest.merge("installed_version" => version))
        )

        resolver = PathResolver.new(name)

        # Extract zip (the download endpoint serves a plain ZIP archive)
        ZipReader.open(zip_data) do |zip|
          zip.each do |entry|
            next if entry.name.include?("..") # Security: prevent path traversal
            next if entry.name.end_with?("/")   # Skip directories

            # Strip package name prefix if present (some zips have name/ prefix)
            relative_path = entry.name.dup
            if relative_path.start_with?("#{name}/")
              relative_path = relative_path["#{name}/".length..-1]
            end

            target_path = File.join(package_dir, relative_path)
            Forge::Fs.mkdir_p(File.dirname(target_path))

            content = entry.read

            # Rewrite path references in Ruby files
            if target_path.end_with?(".rb")
              file_type = infer_file_type(relative_path)
              content = resolver.resolve_content(content, file_type: file_type)
            end

            Forge::Fs.write(target_path, content)
          end
        end

        # Generate asset map for runtime path resolution
        asset_map = PathResolver.generate_asset_map(package_dir)
        Forge::Fs.write(
          File.join(package_dir, "assets.json"),
          Forge::JSON.generate(asset_map)
        )
      end

      # Infer the file type from its installed path.
      # @param path [String] relative path within package
      # @return [Symbol] :script, :widget, :lib
      def infer_file_type(path)
        case path
        when /\Ascripts\// then :script
        when /\Awidgets\// then :widget
        when /\Alib\// then :lib
        else :lib
        end
      end

      def register_package(name, version, manifest)
        lock = read_lock

        lock["packages"][name] = {
          "version" => version,
          "manifest" => manifest
        }

        write_lock(lock)
      end

      def package_path(name)
        join_path(base_dir, "packages", name)
      end

      # The project root.
      #   - DragonRuby: paths passed to GTK.read_file / GTK.write_file are
      #     interpreted relative to the game directory, so the prefix is empty.
      #   - MRI: absolute path two levels up from this file (parent of app/)
      #     so tooling can run from any working directory.
      def base_dir
        if Forge::Fs::DR_RUNTIME
          ""
        else
          File.dirname(File.dirname(__FILE__))
        end
      end

      def lock_path
        join_path(base_dir, "packages.lock.json")
      end

      # File.join("", "packages", "x") returns "/packages/x" which DragonRuby
      # treats as an absolute path outside the sandbox. Drop empty/dot segments.
      def join_path(*parts)
        cleaned = parts.reject { |p| p.nil? || p == "" || p == "." }
        cleaned.empty? ? "" : File.join(*cleaned)
      end

      def read_lock
        if Forge::Fs.exists?(lock_path)
          contents = Forge::Fs.read(lock_path)
          Forge::JSON.parse(contents) || { "version" => "1", "forge_version" => "1.0.0", "packages" => {} }
        else
          { "version" => "1", "forge_version" => "1.0.0", "packages" => {} }
        end
      end

      def write_lock(lock)
        Forge::Fs.write(lock_path, Forge::JSON.pretty(lock))
      end

      def normalize_name(name)
        name.downcase.gsub(/\s+/, "-").gsub(/[^\w-]/, "")
      end

      def log(msg)
        puts "[Forge] #{msg}"
      end

      # Compare two semver version strings. Returns true if a > b.
      def version_gt?(a, b)
        a_parts = a.to_s.split(".").map(&:to_i)
        b_parts = b.to_s.split(".").map(&:to_i)
        [a_parts.length, b_parts.length].max.times do |i|
          a_p = a_parts[i] || 0
          b_p = b_parts[i] || 0
          return a_p > b_p if a_p != b_p
        end
        false
      end
    end

    # Minimal ZIP reader (no external gem needed).
    #
    # Locates the End-of-Central-Directory record at the tail of the archive,
    # walks the central directory (which carries authoritative compressed and
    # uncompressed sizes — local headers may set them to 0 with a streaming
    # data descriptor), then reads each entry from its local-header offset.
    module ZipReader
        EOCD_SIG = "PK\x05\x06".freeze
        CDH_SIG  = "PK\x01\x02".freeze
        LFH_SIG  = "PK\x03\x04".freeze

        def self.open(data, &block)
          raise ArgumentError, "block required" unless block_given?

          # On MRI, force binary encoding so String#[] is byte-indexed; mruby
          # strings are byte-oriented natively and may lack String#force_encoding.
          data = data.dup
          data.force_encoding(Encoding::ASCII_8BIT) if data.respond_to?(:force_encoding) && defined?(Encoding)
          eocd = find_eocd(data)
          raise "Invalid ZIP: end-of-central-directory record not found" unless eocd

          total_entries = data[eocd + 10, 2].unpack("v").first
          cd_size       = data[eocd + 12, 4].unpack("V").first
          cd_offset     = data[eocd + 16, 4].unpack("V").first

          entries = []
          offset = cd_offset
          total_entries.times do
            break if offset + 46 > data.bytesize
            sig = data[offset, 4]
            break unless sig == CDH_SIG

            comp_method  = data[offset + 10, 2].unpack("v").first
            comp_size    = data[offset + 20, 4].unpack("V").first
            uncomp_size  = data[offset + 24, 4].unpack("V").first
            name_len     = data[offset + 28, 2].unpack("v").first
            extra_len    = data[offset + 30, 2].unpack("v").first
            comment_len  = data[offset + 32, 2].unpack("v").first
            local_offset = data[offset + 42, 4].unpack("V").first

            name = data[offset + 46, name_len].to_s
            entries << LazyEntry.new(name, comp_method, comp_size, uncomp_size, local_offset, data)

            offset += 46 + name_len + extra_len + comment_len
          end

          block.call(Entries.new(entries))
        end

        # Search backwards from the end of the archive for the EOCD signature.
        # The EOCD comment can be up to 65535 bytes so we cap the search.
        def self.find_eocd(data)
          max_back = [data.bytesize, 65557].min
          start = data.bytesize - max_back
          start = 0 if start < 0
          window = data[start, max_back]
          idx = window.rindex(EOCD_SIG)
          idx ? start + idx : nil
        end

        # Lazily reads each entry's content from its local header offset on demand.
        class LazyEntry
          attr_reader :name

          def initialize(name, comp_method, comp_size, uncomp_size, local_offset, data)
            @name         = name
            @comp_method  = comp_method
            @comp_size    = comp_size
            @uncomp_size  = uncomp_size
            @local_offset = local_offset
            @data         = data
          end

          def read
            return @content if defined?(@content)
            return @content = "" if @name.end_with?("/")

            base = @local_offset
            return @content = "" if base + 30 > @data.bytesize
            sig = @data[base, 4]
            return @content = "" unless sig == LFH_SIG

            name_len  = @data[base + 26, 2].unpack("v").first
            extra_len = @data[base + 28, 2].unpack("v").first
            data_at   = base + 30 + name_len + extra_len
            raw       = @data[data_at, @comp_size].to_s

            @content = case @comp_method
                       when 0
                         raw
                       when 8
                         inflate_raw(raw)
                       else
                         raw
                       end
          end

          private

          def inflate_raw(bytes)
            unless defined?(Zlib)
              raise PackageManager::Error,
                    "Package archive uses DEFLATE compression but this runtime has no zlib. " \
                    "Forge package archives must be served as STORED (uncompressed) zips on DragonRuby."
            end
            # ZIP uses raw deflate streams (no zlib wrapper) → negative window bits.
            inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
            out = inflater.inflate(bytes)
            out << inflater.finish if !inflater.finished?
            inflater.close
            out
          rescue Zlib::Error
            bytes
          end
        end

        Entries = Struct.new(:entries) do
          def each(&block)
            entries.each(&block)
          end

          def [](name)
            entries.find { |e| e.name == name }
          end
        end
    end
  end

  # Convenience methods at Forge module level
  class << self
    def add_package(name, version: nil, &block)
      PackageManager.add_package(name, version: version, &block)
    end

    def remove_package(name)
      PackageManager.remove_package(name)
    end

    def update_packages(&block)
      PackageManager.update_packages(&block)
    end

    def list_installed
      PackageManager.list_installed
    end

    def search_packages(query, &block)
      PackageManager.search(query, &block)
    end

    def publish_package(**opts, &block)
      PackageManager.publish_package(**opts, &block)
    end

    def can_publish?(&block)
      PackageManager.can_publish?(&block)
    end

    def verify_auth(&block)
      PackageManager.verify_auth(&block)
    end

    def whoami(&block)
      PackageManager.whoami(&block)
    end
  end
end
