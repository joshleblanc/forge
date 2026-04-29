# frozen_string_literal: true

require "zip"
require "json"
require "stringio"

# DragonRuby's pure-Ruby ZipReader only supports classic 32-bit ZIP headers.
# rubyzip 3.x defaults to emitting ZIP64 extra fields for streamed entries,
# which blows up the client. Disable ZIP64 — all our archives are < 4 GB.
Zip.write_zip64_support = false

# Builds a ZIP archive from an on-disk package directory (packages/<name>/)
# and/or from a version's DB metadata, and attaches it to a PackageVersion
# via ActiveStorage through PackageStorageService.
#
# Layout inside the produced ZIP (no top-level prefix):
#
#   manifest.json
#   lib/
#   scripts/
#   widgets/
#   assets/
#   samples/
#
# The manifest.json written into the archive is synthesized from the version
# record so it always matches the DB (on-disk manifest.json is ignored).
class PackagePackager
  class Error < StandardError; end
  class SourceMissing < Error; end

  PACKAGES_ROOT = Rails.root.join("packages").freeze
  INCLUDED_DIRS = %w[lib scripts widgets assets samples].freeze

  attr_reader :package, :version, :source_dir

  def initialize(package, version, source_dir: nil)
    @package = package
    @version = version
    @source_dir = source_dir || PACKAGES_ROOT.join(package.name)
  end

  # Build a ZIP of the package contents in-memory and return the raw bytes.
  # Does not attach — use `#build_and_attach` for that.
  # @return [String] the ZIP binary data
  def build
    buf = StringIO.new
    buf.set_encoding(Encoding::ASCII_8BIT)

    Zip::OutputStream.write_buffer(buf) do |zos|
      write_manifest(zos)
      write_tree(zos) if File.directory?(source_dir)
    end

    buf.string
  end

  # Whether there is an on-disk source tree for this package.
  def source_present?
    File.directory?(source_dir)
  end

  # Build the ZIP and attach it to the version via ActiveStorage.
  # Overwrites any previously attached ZIP.
  # @return [PackageVersion]
  def build_and_attach
    data = build
    PackageStorageService.delete(version) if version.zip_file.attached?
    PackageStorageService.store(version, data)
    version
  end

  private

  # Write the canonical manifest.json (derived from the version record) to the
  # archive root. This guarantees the installed manifest matches what the API
  # returns, regardless of any manifest.json present on disk.
  def write_manifest(zos)
    disk = read_disk_manifest

    manifest = {
      "name"               => package.name,
      "version"            => version.version,
      "description"        => version.description.presence || package.description,
      "dragonruby_version" => version.dragonruby_version.presence || package.dragonruby_version,
      "dependencies"       => version.dependencies.presence || package.dependencies || {},
      "scripts"            => disk["scripts"] || version.scripts.presence || package.scripts || [],
      "widgets"            => disk["widgets"] || version.widgets.presence || package.widgets || [],
      "assets"             => disk["assets"]  || version.assets.presence  || [],
      "tags"               => disk["tags"]    || version.tags.presence    || package.tags || [],
      "author"             => package.author
    }

    zos.put_next_entry("manifest.json", "", Zip::ExtraField.new, Zip::Entry::STORED)
    zos.write(JSON.pretty_generate(manifest))
  end

  def read_disk_manifest
    path = File.join(source_dir, "manifest.json")
    return {} unless File.file?(path)
    JSON.parse(File.read(path))
  rescue JSON::ParserError
    {}
  end

  # Copy every file under the included subdirectories into the archive,
  # preserving relative paths. Hidden files (dotfiles) are skipped.
  def write_tree(zos)
    INCLUDED_DIRS.each do |dir|
      root = File.join(source_dir, dir)
      next unless File.directory?(root)

      Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
        next if File.directory?(path)
        basename = File.basename(path)
        next if basename.start_with?(".")

        rel = Pathname.new(path).relative_path_from(Pathname.new(source_dir)).to_s
        bytes = File.binread(path)
        bytes = rewrite_lib_requires(bytes) if dir == "lib" && rel.end_with?(".rb")

        zos.put_next_entry(rel, "", Zip::ExtraField.new, Zip::Entry::STORED)
        zos.write(bytes)
      end
    end
  end

  # Inside lib/*.rb, rewrite `require_relative "scripts/foo"` and
  # `require_relative "widgets/foo"` to reach sibling directories via `../`.
  # Once installed, the file lives at `packages/<pkg>/lib/<name>.rb` and the
  # target at `packages/<pkg>/scripts/foo.rb`, so `../scripts/foo` resolves
  # correctly. Leaves other paths untouched (including require_relative
  # "phys/velocity" which naturally resolves to lib/phys/velocity.rb).
  def rewrite_lib_requires(source)
    source.gsub(
      /require_relative\s+(['"])(scripts|widgets|assets|samples)\/([^'"]+)\1/
    ) do
      quote = Regexp.last_match(1)
      dir   = Regexp.last_match(2)
      tail  = Regexp.last_match(3)
      "require_relative #{quote}../#{dir}/#{tail}#{quote}"
    end
  end
end
