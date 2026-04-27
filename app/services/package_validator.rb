# frozen_string_literal: true

require "zip"
require "json"

# Validates an uploaded package ZIP against the registry's expectations.
#
# Checks:
#   - ZIP is parseable and contains a `manifest.json` at the archive root
#   - manifest.json is valid JSON and contains required keys
#   - manifest["name"] matches the expected package name (when given)
#   - manifest["version"] matches the expected version (when given)
#   - Every entry in manifest["scripts"] resolves to a `scripts/<snake_case>.rb` file
#   - Every entry in manifest["widgets"] resolves to a `widgets/<snake_case>.rb` file
#   - Every entry in manifest["assets"] (if a string or {path: "..."}) resolves to a file
#   - No entry escapes the archive root (`..` segments) or uses absolute paths
#   - Archive size and file count are within sane limits
#
# Usage:
#
#   result = PackageValidator.new(zip_io, expected_name: "health", expected_version: "1.0.0").validate
#   if result.valid?
#     # proceed
#   else
#     result.errors  # => ["manifest.json missing", ...]
#   end
class PackageValidator
  MAX_BYTES   = 50 * 1024 * 1024  # 50 MB
  MAX_ENTRIES = 5_000
  REQUIRED_MANIFEST_KEYS = %w[name version].freeze

  Result = Struct.new(:errors, :warnings, :manifest, :files, keyword_init: true) do
    def valid?
      errors.empty?
    end
  end

  def initialize(zip_input, expected_name: nil, expected_version: nil)
    @zip_input        = zip_input
    @expected_name    = expected_name
    @expected_version = expected_version
    @errors           = []
    @warnings         = []
    @manifest         = nil
    @files            = []
  end

  def validate
    bytes = read_bytes(@zip_input)
    if bytes.nil?
      @errors << "ZIP file could not be read"
      return result
    end

    if bytes.bytesize > MAX_BYTES
      @errors << "ZIP exceeds maximum size of #{MAX_BYTES / 1024 / 1024} MB (got #{bytes.bytesize} bytes)"
      return result
    end

    @files = extract_file_list(bytes)
    return result unless @errors.empty?

    if @files.size > MAX_ENTRIES
      @errors << "ZIP contains too many entries (#{@files.size} > #{MAX_ENTRIES})"
      return result
    end

    validate_paths
    validate_manifest(bytes)
    validate_declared_files

    result
  end

  private

  def result
    Result.new(errors: @errors, warnings: @warnings, manifest: @manifest, files: @files)
  end

  def read_bytes(input)
    if input.respond_to?(:read)
      input.rewind if input.respond_to?(:rewind)
      bytes = input.read
      input.rewind if input.respond_to?(:rewind)
      bytes
    elsif input.is_a?(String)
      input
    end
  end

  def extract_file_list(bytes)
    paths = []
    Zip::File.open_buffer(bytes) do |zf|
      zf.each do |entry|
        next if entry.directory?
        paths << entry.name
      end
    end
    paths
  rescue Zip::Error => e
    @errors << "Could not parse ZIP archive: #{e.message}"
    []
  end

  def validate_paths
    @files.each do |path|
      if path.start_with?("/")
        @errors << "Archive contains absolute path: #{path}"
      end

      if path.split("/").include?("..")
        @errors << "Archive contains path traversal segment: #{path}"
      end
    end
  end

  def validate_manifest(bytes)
    manifest_content = nil
    Zip::File.open_buffer(bytes) do |zf|
      entry = zf.find_entry("manifest.json")
      manifest_content = entry&.get_input_stream&.read
    end

    unless manifest_content
      @errors << "manifest.json is missing from the archive root"
      return
    end

    begin
      @manifest = JSON.parse(manifest_content)
    rescue JSON::ParserError => e
      @errors << "manifest.json is not valid JSON: #{e.message}"
      return
    end

    unless @manifest.is_a?(Hash)
      @errors << "manifest.json must be a JSON object"
      @manifest = nil
      return
    end

    REQUIRED_MANIFEST_KEYS.each do |key|
      if @manifest[key].to_s.strip.empty?
        @errors << "manifest.json is missing required key: #{key}"
      end
    end

    if @expected_name && @manifest["name"] && @manifest["name"] != @expected_name
      @errors << "manifest.json name (#{@manifest["name"].inspect}) does not match expected package name (#{@expected_name.inspect})"
    end

    if @expected_version && @manifest["version"] && @manifest["version"] != @expected_version
      @errors << "manifest.json version (#{@manifest["version"].inspect}) does not match expected version (#{@expected_version.inspect})"
    end
  end

  def validate_declared_files
    return unless @manifest

    file_set = @files.to_set

    Array(@manifest["scripts"]).each do |script|
      expected = "scripts/#{script.to_s.underscore}.rb"
      unless file_set.include?(expected)
        @errors << "manifest.scripts entry #{script.inspect} expects #{expected} but it is not in the archive"
      end
    end

    Array(@manifest["widgets"]).each do |widget|
      expected = "widgets/#{widget.to_s.underscore}.rb"
      unless file_set.include?(expected)
        @errors << "manifest.widgets entry #{widget.inspect} expects #{expected} but it is not in the archive"
      end
    end

    Array(@manifest["assets"]).each do |asset|
      path = asset.is_a?(Hash) ? (asset["path"] || asset[:path]) : asset
      next if path.to_s.strip.empty?
      normalized = path.to_s.sub(%r{\Aassets/}, "")
      expected = "assets/#{normalized}"
      unless file_set.include?(expected)
        @warnings << "manifest.assets entry #{path.inspect} expects #{expected} but it is not in the archive"
      end
    end
  end
end
