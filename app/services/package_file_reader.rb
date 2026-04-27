# frozen_string_literal: true

# Reads files from a package ZIP blob stored in ActiveStorage.
# This reader never touches the local filesystem; if the version has no
# attached ZIP, the file list is empty and reads return nil.
require "zip"

class PackageFileReader
  attr_reader :package, :version

  def initialize(package, version_record)
    @package = package
    @version = version_record
  end

  # Returns all files in the package as a list of {path, type, name} hashes.
  # Prefers the attached ZIP; if none, falls back to the version's metadata
  # columns so the UI still has something to display.
  def file_list
    return list_from_zip if zip_blob&.attached?
    list_from_metadata
  end

  # Returns the content of a specific file, or nil if not found.
  def read_file(path)
    return nil unless zip_blob&.attached?
    content = nil
    zip_blob.open do |io|
      ::Zip::File.open_buffer(io) do |zf|
        normalized = path.sub(%r{\A/}, "")
        entry = zf.find_entry(normalized)
        content = entry.get_input_stream.read if entry
      end
    rescue => _e
      content = nil
    end
    content
  end

  private

  def zip_blob
    @version.zip_file
  end

  def list_from_zip
    results = {}
    zip_blob.open do |io|
      ::Zip::File.open_buffer(io) do |zf|
        zf.each do |entry|
          next if entry.directory?
          path = entry.name
          next if path.start_with?(".") || path.include?("/.")
          type = file_type(path)
          results[path] = { path: path, type: type, name: File.basename(path) } if type
        end
      end
    rescue => _e
      return []
    end
    results.values.sort_by { |f| file_sort_key(f[:type]) }
  end

  # Synthesize a file list from the version's metadata columns when no ZIP
  # is attached. Paths are derived purely from DB fields — no filesystem.
  def list_from_metadata
    results = {}
    add_entry(results, "manifest.json")

    Array(@version.try(:scripts)).each do |name|
      next if name.blank?
      add_entry(results, "scripts/#{slugify(name)}.rb")
    end

    Array(@version.try(:widgets)).each do |name|
      next if name.blank?
      add_entry(results, "widgets/#{slugify(name)}.rb")
    end

    Array(@version.try(:assets)).each do |asset|
      path = asset.is_a?(Hash) ? (asset["path"] || asset[:path]) : asset
      next if path.blank?
      path = path.to_s.sub(%r{\Aassets/}, "")
      add_entry(results, "assets/#{path}")
    end

    sample_names = parse_samples(@package.try(:samples))
    sample_names.each do |sample|
      next if sample.blank?
      add_entry(results, "samples/#{sample}/app/main.rb")
    end

    results.values.sort_by { |f| file_sort_key(f[:type]) }
  end

  def add_entry(results, path)
    type = file_type(path)
    return unless type
    results[path] ||= { path: path, type: type, name: File.basename(path) }
  end

  def slugify(name)
    s = name.to_s.strip
    # Insert underscores at CamelCase boundaries: "ABCDef" -> "ABC_Def", "FooBar" -> "Foo_Bar"
    s = s.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2')
    s = s.gsub(/[^A-Za-z0-9]+/, "_").gsub(/\A_+|_+\z/, "").downcase
    s.empty? ? "untitled" : s
  end

  def parse_samples(raw)
    return [] if raw.blank?
    return raw if raw.is_a?(Array)
    JSON.parse(raw)
  rescue JSON::ParserError
    []
  end

  def file_type(rel)
    return "lib"     if rel.start_with?("lib/")
    return "script"  if rel.start_with?("scripts/")
    return "widget"  if rel.start_with?("widgets/")
    return "sprite"  if rel.start_with?("assets/sprites/")
    return "audio"   if rel.start_with?("assets/audio/")
    return "asset"   if rel.start_with?("assets/")
    return "sample"  if rel.start_with?("samples/")
    return "config" if rel.end_with?(".json")
    return "doc"    if rel.end_with?(".md")
    return "lib"     if rel.end_with?(".rb")
    nil
  end

  def file_sort_key(type)
    {
      "config" => 0, "script" => 1, "widget" => 2, "lib" => 3,
      "sprite" => 4, "audio" => 5, "asset" => 6, "sample" => 7,
      "doc" => 8, "file" => 9
    }.fetch(type, 9)
  end
end
