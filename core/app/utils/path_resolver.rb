# Forge Path Resolver — runtime asset lookups and manifest validation for an
# installed package. Path rewriting of `require_relative` / asset strings
# inside package source is done **on the server at publish time**, not here.
#
# DragonRuby's mruby has no Regexp class, so this file uses plain string ops
# only.
#
#   resolver = Forge::PathResolver.new("my_package")
#   resolver.resolve_asset_path("sprites/player.png")
#   # => "packages/my_package/assets/sprites/player.png"
#
#   missing = resolver.find_missing_files(manifest)
#   # => [] if every declared script/widget/asset is on disk

module Forge
  class PathResolver
    ASSET_EXTENSIONS = %w[.png .jpg .jpeg .gif .webp .wav .ogg .mp3 .flac .ttf .otf .json .ldtk .tmx .tsx]
    SPRITE_EXTS      = %w[.png .jpg .jpeg .gif .webp].freeze
    AUDIO_EXTS       = %w[.wav .ogg .mp3 .flac].freeze

    attr_reader :package_name, :package_dir

    def initialize(package_name)
      @package_name = package_name
      @package_dir  = "packages/#{package_name}"
    end

    # Resolve a relative asset path to its absolute installed path.
    # @param path [String] relative path (e.g., "sprites/player.png")
    # @param from_type [Symbol] :script, :widget, :lib, :sample
    # @return [String] resolved installed path
    def resolve_asset_path(path, from_type: :script)
      return path if path.nil? || path.empty?
      return path if path.start_with?("packages/")
      return path if path.start_with?("/")
      return path if path.start_with?("http://") || path.start_with?("https://")

      base = case from_type
             when :script then "#{package_dir}/scripts"
             when :widget then "#{package_dir}/widgets"
             when :lib    then "#{package_dir}/lib"
             when :sample then "#{package_dir}/samples"
             else              "#{package_dir}/assets"
             end

      "#{base}/#{path}"
    end

    # Guess the file type from a path.
    # @param path [String]
    # @return [Symbol] :script, :widget, :lib, :asset, :sample
    def infer_type(path)
      return :script if path.start_with?("scripts/")
      return :widget if path.start_with?("widgets/")
      return :lib    if path.start_with?("lib/")
      return :asset  if path.start_with?("assets/")
      return :sample if path.start_with?("samples/")
      :lib
    end

    # Get the asset subdirectory for a file extension.
    def asset_type_to_dir(ext)
      case ext.to_s.downcase
      when ".png", ".jpg", ".jpeg", ".gif", ".webp" then "sprites"
      when ".wav", ".ogg", ".mp3", ".flac"          then "audio"
      when ".ttf", ".otf"                            then "fonts"
      when ".json", ".ldtk", ".tmx", ".tsx"          then "data"
      end
    end

    # Validate that every file declared in the manifest is actually present.
    # @param manifest [Hash]
    # @return [Array<String>] list of missing absolute paths
    def find_missing_files(manifest)
      missing = []

      (manifest["scripts"] || []).each do |script|
        path = File.join(package_dir, "scripts", "#{Forge::Utils.underscore(script)}.rb")
        missing << path unless Forge::Fs.exists?(path)
      end

      (manifest["widgets"] || []).each do |widget|
        path = File.join(package_dir, "widgets", "#{Forge::Utils.underscore(widget)}.rb")
        missing << path unless Forge::Fs.exists?(path)
      end

      (manifest["assets"] || []).each do |asset|
        next unless asset.is_a?(Hash)
        path = File.join(package_dir, "assets", asset[:path])
        missing << path unless Forge::Fs.exists?(path)
      end

      missing
    end

    # Generate an asset map (logical name => installed path) for a package,
    # by walking the assets/ tree at install time.
    # @param package_dir [String] path to the installed package root
    # @return [Hash{String => String}]
    def self.generate_asset_map(package_dir)
      map = {}

      sprites_dir = File.join(package_dir, "assets", "sprites")
      if Forge::Fs.directory?(sprites_dir)
        Forge::Fs.list_recursive(sprites_dir).each do |rel|
          f = File.join(sprites_dir, rel)
          logical = strip_extension(rel, SPRITE_EXTS)
          map["sprites/#{logical}"] = f
          map[rel] = f
        end
      end

      audio_dir = File.join(package_dir, "assets", "audio")
      if Forge::Fs.directory?(audio_dir)
        Forge::Fs.list_recursive(audio_dir).each do |rel|
          f = File.join(audio_dir, rel)
          logical = "audio/#{strip_extension(rel, AUDIO_EXTS)}"
          map["audio/#{rel}"] = f
          map[logical] = f
        end
      end

      # Everything else under assets/ is indexed by its on-disk path.
      assets_dir = File.join(package_dir, "assets")
      if Forge::Fs.directory?(assets_dir)
        Forge::Fs.list_recursive(assets_dir).each do |rel|
          f = File.join(assets_dir, rel)
          map[rel] = f unless map.key?(rel)
        end
      end

      map
    end

    # Strip a matching extension from the tail of `path`. Returns `path`
    # unchanged if none of `exts` matches.
    def self.strip_extension(path, exts)
      lower = path.downcase
      exts.each do |ext|
        return path[0, path.length - ext.length] if lower.end_with?(ext)
      end
      path
    end
  end
end
