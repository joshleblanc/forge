class Packages::PublishController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :require_login

  def new
    @package = Package.new
  end

  def create
    # Handle ZIP upload - extract metadata automatically
    zip_metadata = {}
    if params[:zip_upload].present?
      zip_metadata = extract_zip_metadata(params[:zip_upload])
      if zip_metadata[:error]
        flash.now[:alert] = zip_metadata[:error]
        render :new, status: :unprocessable_entity
        return
      end
    end

    # Parse dependencies from text format
    dependencies = {}
    if params[:package][:dependencies_text].present?
      params[:package][:dependencies_text].split("\n").each do |line|
        line = line.strip
        next if line.empty?
        if line =~ /^(\S+)\s*\(([^)]+)\)$/
          dependencies[$1] = $2
        end
      end
    end

    # Parse scripts - combine form input with ZIP extraction
    scripts = []
    if params[:package][:scripts_text].present?
      scripts = params[:package][:scripts_text].split("\n").map(&:strip).reject(&:empty?)
    elsif zip_metadata[:scripts].present?
      scripts = zip_metadata[:scripts]
    end

    # Parse widgets
    widgets = []
    if params[:package][:widgets_text].present?
      widgets = params[:package][:widgets_text].split(",").map(&:strip).reject(&:empty?)
    elsif zip_metadata[:widgets].present?
      widgets = zip_metadata[:widgets]
    end

    # Parse assets
    assets = []
    if params[:package][:assets_text].present?
      assets = params[:package][:assets_text].split("\n").map(&:strip).reject(&:empty?).map { |a| { path: a } }
    elsif zip_metadata[:assets].present?
      assets = zip_metadata[:assets]
    end

    # Parse tags
    tags = []
    if params[:package][:tags_text].present?
      tags = params[:package][:tags_text].split(",").map(&:strip).reject(&:empty?)
    elsif zip_metadata[:tags].present?
      tags = zip_metadata[:tags]
    end

    # Parse samples
    samples = []
    if params[:package][:samples_text].present?
      samples = params[:package][:samples_text].split(",").map(&:strip).reject(&:empty?)
    end

    # Build package name - prefer form, fall back to ZIP
    package_name = params[:package][:name].presence || zip_metadata[:name] || "unknown"
    version_str = params[:package][:latest_version].presence || zip_metadata[:version] || "1.0.0"
    description = params[:package][:description].presence || zip_metadata[:description] || ""
    dr_version = params[:package][:dragonruby_version].presence || zip_metadata[:dragonruby_version] || ">= 3.0"

    @package = Package.new(
      name: package_name,
      latest_version: version_str,
      description: description,
      dragonruby_version: dr_version,
      dependencies: dependencies,
      scripts: scripts,
      tags: tags,
      samples: samples
    )
    @package.author = current_user.username

    if @package.valid?
      # Check for duplicate version
      existing = Package.find_by(name: @package.name)
      if existing && existing.versions.exists?(version: @package.latest_version)
        flash.now[:alert] = "Version #{@package.latest_version} of this package already exists"
        render :new, status: :unprocessable_entity
        return
      end

      # If a ZIP was uploaded, validate it against the resolved name/version
      # before saving anything to the database.
      if params[:zip_upload].present?
        validation = PackageValidator.new(
          params[:zip_upload],
          expected_name: package_name,
          expected_version: version_str
        ).validate

        unless validation.valid?
          flash.now[:alert] = "Invalid package archive: #{validation.errors.join("; ")}"
          render :new, status: :unprocessable_entity
          return
        end
      end

      @package.save!

      # Create initial version record
      version_record = @package.versions.create!(
        version: @package.latest_version,
        description: @package.description,
        dragonruby_version: @package.dragonruby_version,
        dependencies: @package.dependencies,
        scripts: @package.scripts,
        widgets: widgets,
        assets: assets,
        tags: @package.tags
      )

      # Store ZIP file via ActiveStorage if uploaded
      if params[:zip_upload].present?
        PackageStorageService.store(version_record, params[:zip_upload])
      end

      redirect_to package_path(@package.name), notice: "Package '#{@package.name}' published successfully!"
    else
      flash.now[:alert] = @package.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def extract_zip_metadata(zip_file)
    return { error: "Invalid ZIP file" } unless zip_file.is_a?(ActionDispatch::Http::UploadedFile)

    require 'zip'
    metadata = { scripts: [], widgets: [], assets: [], tags: [] }

    begin
      Zip::File.open_buffer(zip_file.read) do |zip|
        # Look for manifest.json
        manifest_entry = zip.glob("manifest.json").first
        if manifest_entry
          content = manifest_entry.get_input_stream.read
          manifest = JSON.parse(content)
          metadata[:name] = manifest["name"]
          metadata[:version] = manifest["version"]
          metadata[:description] = manifest["description"]
          metadata[:dragonruby_version] = manifest["dragonruby_version"]
          metadata[:scripts] = manifest["scripts"] || []
          metadata[:widgets] = manifest["widgets"] || []
          metadata[:assets] = manifest["assets"] || []
          metadata[:tags] = manifest["tags"] || []
          metadata[:dependencies] = manifest["dependencies"] || {}
          return metadata
        end

        # Auto-detect from file structure
        zip.each do |entry|
          next if entry.directory?

          path = entry.name
          basename = File.basename(path, ".rb")

          case path
          when /\Ascripts\/(.+)\.rb\z/
            metadata[:scripts] << basename.titleize
          when /\Awidgets\/(.+)\.rb\z/
            metadata[:widgets] << basename.titleize
          when /\Aassets\//
            metadata[:assets] << { path: path.sub("assets/", "") }
          end
        end
      end
    rescue Zip::Error => e
      return { error: "Could not read ZIP file: #{e.message}" }
    rescue JSON::ParserError => e
      return { error: "Invalid manifest.json in ZIP: #{e.message}" }
    end

    metadata[:name] ||= "auto_package"
    metadata[:version] ||= "1.0.0"
    metadata
  end

end
