# frozen_string_literal: true

# Forge Path Resolver
# Rewrites path references when packages are installed to the packages/ namespace.
#
# Handles:
# - require/require_relative statements in Ruby files
# - Asset paths in sprite, audio, and LDTK file references
# - Internal package cross-references
#
# Usage:
#   resolver = Forge::PathResolver.new("my_package")
#   resolver.resolve_content(ruby_source_code)
#   resolver.resolve_asset_path("sprites/player.png")  # => "packages/my_package/assets/sprites/player.png"

module Forge
  class PathResolver
    # Common asset extensions that need path rewriting
    ASSET_EXTENSIONS = %w[.png .jpg .jpeg .gif .wav .ogg .mp3 .ttf .otf .json .ldtk .tmx .tsx .tsx]

    attr_reader :package_name, :package_dir

    def initialize(package_name)
      @package_name = package_name
      @package_dir = "packages/#{package_name}"
    end

    # Resolve a relative asset path to its absolute installed path.
    # @param path [String] relative path (e.g., "sprites/player.png")
    # @param from_type [Symbol] :script, :widget, :lib (where the path appears)
    # @return [String] resolved absolute path
    def resolve_asset_path(path, from_type: :script)
      return path if path.nil? || path.empty?
      return path if path.start_with?("packages/")
      return path if path.start_with?("/")
      return path if path =~ /\Ahttps?:\/\//

      # Map asset directory based on file type
      case from_type
      when :script
        base = "#{package_dir}/scripts"
      when :widget
        base = "#{package_dir}/widgets"
      when :lib
        base = "#{package_dir}/lib"
      when :sample
        base = "#{package_dir}/samples"
      else
        base = "#{package_dir}/assets"
      end

      # Determine asset subdirectory from extension
      ext = File.extname(path).downcase
      asset_subdir = asset_type_to_dir(ext)

      if asset_subdir
        "#{package_dir}/assets/#{asset_subdir}/#{path}"
      else
        "#{package_dir}/#{path}"
      end
    end

    # Resolve the directory where a file type lives.
    # @param type [Symbol] :script, :widget, :lib
    # @return [String] relative directory path
    def directory_for(type)
      case type
      when :script then "scripts"
      when :widget then "widgets"
      when :lib then "lib"
      when :asset then "assets"
      else type.to_s
      end
    end

    # Rewrite all path references in Ruby source code.
    # @param content [String] Ruby source code
    # @param file_type [Symbol] :script, :widget, :lib
    # @return [String] rewritten source code
    def resolve_content(content, file_type: :script)
      return content unless content.is_a?(String)

      # Rewrite require/require_relative for internal package files
      content = rewrite_requires(content, file_type)

      # Rewrite string literals that look like asset paths
      content = rewrite_asset_strings(content, file_type)

      # Rewrite hash rocket and symbol key paths (path:, sprite:, etc.)
      content = rewrite_path_hashes(content, file_type)

      content
    end

    # Rewrite require statements for internal package files.
    # E.g., require_relative "scripts/foo" -> require_relative "packages/pkg/scripts/foo"
    def rewrite_requires(content, file_type = :script)
      # require_relative "scripts/foo"
      content.gsub(
        /require_relative\s+["']([^"']+)["']/
      ) do |match|
        path = $1
        quoted = match[/["']/]
        new_path = resolve_require_path(path, file_type)
        "require_relative #{quoted}#{new_path}#{quoted}"
      end

      # require "packages/foo/scripts/bar" (normalize to full path)
      content.gsub(
        /require\s+["']([^"']+)["']/
      ) do |match|
        path = $1
        quoted = match[/["']/]
        # Only rewrite if it's a relative-looking path (not gem-like)
        if path.start_with?(".") || path.start_with?("scripts/") || path.start_with?("widgets/") || path.start_with?("lib/")
          new_path = resolve_require_path(path, file_type)
          "require #{quoted}#{new_path}#{quoted}"
        else
          match
        end
      end
    end

    # Resolve a require path to its installed location.
    # @param path [String] relative require path
    # @param file_type [Symbol] where the require appears
    # @return [String] resolved path
    def resolve_require_path(path, file_type)
      return path if path.start_with?("packages/")
      return path if path.start_with?("/")

      # Determine base directory from current file type
      base = directory_for(file_type)

      # Handle paths that start with scripts/, widgets/, lib/
      case path
      when /\A(scripts|widgets|lib)\//
        "#{package_dir}/#{path}"
      when /\A\.\.?\//
        # Relative path — resolve from current file's directory
        File.expand_path(path, "#{package_dir}/#{base}")
      else
        # Bare name — assume it's in the same category
        "#{package_dir}/#{base}/#{path}"
      end.sub(/\.rb\z/, "") # Strip .rb extension for require
    end

    # Rewrite string literals that look like asset paths.
    def rewrite_asset_strings(content, file_type)
      # Match string literals containing likely asset paths
      content.gsub(
        /(["'])([^"']*\.(png|jpg|jpeg|gif|wav|ogg|mp3|ttf|otf|json|ldtk|tmx))(\1)/i
      ) do |_match|
        path = $2
        quoted = $1
        resolved = resolve_asset_path(path, from_type: file_type)
        "#{quoted}#{resolved}#{quoted}"
      end
    end

    # Rewrite :path, :sprite, :audio hash keys with asset paths.
    def rewrite_path_hashes(content, file_type)
      # :path => "sprites/foo.png" or path: "sprites/foo.png"
      content.gsub(
        /([:\w]+)\s*=>\s*(["'])([^"']+\.(png|jpg|jpeg|gif|wav|ogg|mp3|ttf|otf|json|ldtk|tmx))(\2)/
      ) do |_match|
        key = $1
        quoted = $2
        path = $3
        resolved = resolve_asset_path(path, from_type: file_type)
        "#{key}=>#{quoted}#{resolved}#{quoted}"
      end
    end

    # Guess the file type from a path.
    # @param path [String]
    # @return [Symbol] :script, :widget, :lib, :asset
    def infer_type(path)
      case path
      when /\Ascripts\// then :script
      when /\Awidgets\// then :widget
      when /\Alib\// then :lib
      when /\Aassets\// then :asset
      when /\Asamples\// then :sample
      else :lib
      end
    end

    # Get the asset subdirectory for a file extension.
    # @param ext [String] file extension including dot
    # @return [String, nil] subdirectory name or nil
    def asset_type_to_dir(ext)
      case ext.downcase
      when ".png", ".jpg", ".jpeg", ".gif", ".webp" then "sprites"
      when ".wav", ".ogg", ".mp3", ".flac" then "audio"
      when ".ttf", ".otf" then "fonts"
      when ".json", ".ldtk", ".tmx", ".tsx" then "data"
      else nil
      end
    end

    # Validate that all required files exist in the installed package.
    # @param manifest [Hash] package manifest
    # @return [Array<String>] list of missing files
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

    # Generate asset manifest for a package — maps logical names to installed paths.
    # Used at runtime to resolve asset paths.
    # @param package_dir [String] path to package directory
    # @return [Hash] name => installed_path mapping
    def self.generate_asset_map(package_dir)
      map = {}

      sprites_dir = File.join(package_dir, "assets", "sprites")
      if Forge::Fs.directory?(sprites_dir)
        Forge::Fs.list_recursive(sprites_dir).each do |rel|
          f = File.join(sprites_dir, rel)
          logical = rel.sub(/\.(png|jpg|jpeg|gif|webp)\z/, "")
          map["sprites/#{logical}"] = f
          map[rel] = f
        end
      end

      audio_dir = File.join(package_dir, "assets", "audio")
      if Forge::Fs.directory?(audio_dir)
        Forge::Fs.list_recursive(audio_dir).each do |rel|
          f = File.join(audio_dir, rel)
          logical = "audio/#{rel.sub(/\.(wav|ogg|mp3|flac)\z/, "")}"
          map["audio/#{rel}"] = f
          map[logical] = f
        end
      end

      map
    end
  end
end
