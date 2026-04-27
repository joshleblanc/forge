# frozen_string_literal: true

# Service for storing and retrieving package ZIP files via ActiveStorage.
# Provides both the blob (for reading) and a temp path (for send_file downloads).
#
# Uses ActiveStorage for persistence:
#   - PackageVersion#zip_file attached blob
#   - Disk service for local development
#   - S3/GCS/Azure for production

class PackageStorageService
  class StorageError < StandardError; end

  class << self
    # Attach a ZIP file to a package version via ActiveStorage.
    # @param version [PackageVersion]
    # @param file [ActionDispatch::Http::UploadedFile, File, String, IO]
    def store(version, file)
      version.zip_file.attach(
        io: file_to_io(file),
        filename: "#{version.package.name}-#{version.version}.zip",
        content_type: "application/zip"
      )
    rescue => e
      raise StorageError, "Failed to store package: #{e.message}"
    end

    # Check if a package version has a ZIP blob attached.
    # @param version [PackageVersion]
    # @return [Boolean]
    def exists?(version)
      version.zip_file.attached?
    end

    # Get a local temp path to the ZIP file for send_file / processing.
    # Downloads from cloud if using S3/GCS.
    # @param version [PackageVersion]
    # @return [String, nil] path to temp file, or nil if not attached
    def path(version)
      return nil unless version.zip_file.attached?

      blob = version.zip_file.blob
      if blob.service.name == "disk"
        # Local disk service — return the actual path
        blob.service.path_for(blob.key)
      else
        # Cloud service — download to temp file
        temp_file = Tempfile.new(["#{version.package.name}-#{version.version}", ".zip"])
        temp_file.binmode
        blob.download { |chunk| temp_file.write(chunk) }
        temp_file.close
        temp_file.path
      end
    end
    alias_method :get, :path

    # Open the ZIP blob as an IO stream.
    # @param version [PackageVersion]
    # @return [IO, nil]
    def open(version)
      return nil unless version.zip_file.attached?
      version.zip_file.blob.open
    end

    # Delete the attached ZIP blob.
    # @param version [PackageVersion]
    def delete(version)
      version.zip_file.purge if version.zip_file.attached?
    end

    # Delete all versions for a package.
    # @param package [Package]
    def delete_all(package)
      package.versions.each { |v| delete(v) }
    end

    # Total bytes used by all ZIPs for a package.
    # @param package [Package]
    # @return [Integer]
    def size_bytes(package)
      package.versions.sum do |v|
        v.zip_file.attached? ? v.zip_file.blob.byte_size : 0
      end
    end

    # Human-readable storage size.
    # @param bytes [Integer]
    # @return [String]
    def size_human(bytes)
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)} KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{(bytes / (1024.0 * 1024)).round(1)} MB"
      else
        "#{(bytes / (1024.0 * 1024 * 1024)).round(2)} GB"
      end
    end

    # Serve a blob as a downloadable response using Rails streaming.
    # @param version [PackageVersion]
    # @param controller [ApplicationController]
    def serve(version, controller)
      return nil unless version.zip_file.attached?

      blob = version.zip_file.blob
      filename = "#{version.package.name}-#{version.version}.zip"

      controller.send_file blob.service.path_for(blob.key),
        filename: filename,
        type: "application/zip",
        disposition: "attachment"
    rescue => e
      raise StorageError, "Failed to serve package: #{e.message}"
    end

    private

    def file_to_io(file)
      if file.is_a?(ActionDispatch::Http::UploadedFile)
        file.to_io
      elsif file.respond_to?(:read)
        io = file.read
        file.close if file.respond_to?(:close)
        StringIO.new(io)
      elsif file.is_a?(String)
        StringIO.new(file)
      else
        file
      end
    end
  end
end
