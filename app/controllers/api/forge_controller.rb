class Api::ForgeController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /api/forge/library
  #
  # Returns a STORED (uncompressed) ZIP of the Forge base library, **excluding**
  # per-project files so it can be unzipped over an existing project without
  # clobbering the user's state. Excluded:
  #   - api_key.rb / api_key.rb.example  (user's credentials)
  #   - app/main.rb                      (user's game entry point)
  #   - metadata/*                       (DragonRuby project metadata)
  #   - README.md                        (project readme)
  #
  # Used by the in-game `Forge.update_forge` helper.
  def library
    require "zip"
    Zip.write_zip64_support = false # DragonRuby ZipReader only parses classic 32-bit headers.

    core_path = Rails.root.join("core")
    buffer    = StringIO.new

    Zip::OutputStream.write_buffer(buffer) do |zip|
      Dir.glob("#{core_path}/**/*", File::FNM_DOTMATCH).sort.each do |file_path|
        next if File.directory?(file_path)
        base = File.basename(file_path)
        next if base == "." || base == ".."
        next if file_path.end_with?(".drp")

        rel = file_path.sub("#{core_path}/", "")
        next if excluded?(rel)

        zip.put_next_entry(rel, "", Zip::ExtraField.new, Zip::Entry::STORED)
        zip.write(File.binread(file_path))
      end
    end

    send_data buffer.string,
              filename:    "forge-library.zip",
              type:        "application/zip",
              disposition: "attachment"
  end

  private

  # Paths (relative to core/) that update should **not** overwrite.
  EXCLUDED_PREFIXES = [
    "api_key.rb",
    "api_key.rb.example",
    "app/main.rb",
    "metadata/",
    "README.md"
  ].freeze

  def excluded?(rel)
    EXCLUDED_PREFIXES.any? { |p| p.end_with?("/") ? rel.start_with?(p) : rel == p }
  end
end
