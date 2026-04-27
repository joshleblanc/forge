class Api::PackagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:publish]
  before_action :authenticate_by_api_key, only: [:publish]
  before_action :require_publish_permission, only: [:publish]

  # GET /api/packages
  # Returns all packages with optional search/tag filtering
  def index
    query = params[:q]
    tag = params[:tag]

    @packages = Package.ordered
    @packages = @packages.search(query) if query.present?
    @packages = @packages.filter_by_tag(tag) if tag.present?
    @packages = @packages.limit(50)

    render json: { packages: @packages.map { |p|
      v = p.versions.first
      {
        name: p.name,
        latest_version: p.latest_version,
        description: p.description,
        author: p.author,
        dragonruby_version: p.dragonruby_version,
        dependencies: p.dependencies,
        scripts: p.scripts,
        tags: p.tags,
        downloads: p.versions.sum(:download_count),
        samples: p.samples.present? ? JSON.parse(p.samples) : []
      }}}
  end

  # GET /api/packages/:id
  def show
    pkg = Package.find_by!(name: params[:id])
    sample_list = pkg.samples.present? ? JSON.parse(pkg.samples) : []
    render json: {
      name: pkg.name,
      latest_version: pkg.latest_version,
      description: pkg.description,
      author: pkg.author,
      dragonruby_version: pkg.dragonruby_version,
      dependencies: pkg.dependencies,
      scripts: pkg.scripts,
      tags: pkg.tags,
      samples: sample_list
    }
  end

  # POST /api/packages/publish
  # Create or update a package in the registry
  def publish
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

    # Parse scripts from text format
    scripts = []
    if params[:package][:scripts_text].present?
      scripts = params[:package][:scripts_text].split("\n").map(&:strip).reject(&:empty?)
    end

    # Parse tags from comma-separated format
    tags = []
    if params[:package][:tags_text].present?
      tags = params[:package][:tags_text].split(",").map(&:strip).reject(&:empty?)
    end

    # Parse samples from comma-separated format
    samples = []
    if params[:package][:samples_text].present?
      samples = params[:package][:samples_text].split(",").map(&:strip).reject(&:empty?)
    end

    # Parse widgets from comma-separated format
    widgets = []
    if params[:package][:widgets_text].present?
      widgets = params[:package][:widgets_text].split(",").map(&:strip).reject(&:empty?)
    end

    # Parse assets from comma-separated format (path,name pairs)
    assets = []
    if params[:package][:assets_text].present?
      assets = params[:package][:assets_text].split("\n").map(&:strip).reject(&:empty?).map { |a| { path: a } }
    end

    # Find or create the package
    @package = Package.find_or_initialize_by(name: params[:package][:name])

    @package.latest_version = params[:package][:latest_version]
    @package.description = params[:package][:description]
    @package.dragonruby_version = params[:package][:dragonruby_version] || ">= 3.0"
    @package.dependencies = dependencies
    @package.scripts = scripts
    @package.tags = tags
    @package.samples = samples
    @package.author = resolve_user&.username || "Unknown"

    if @package.new_record?
      if Package.exists?(name: @package.name)
        render json: { error: "Package name '#{@package.name}' is already taken" }, status: :conflict
        return
      end
      @package.save!

      @package.versions.create!(
        version: @package.latest_version,
        description: @package.description,
        dragonruby_version: @package.dragonruby_version,
        dependencies: @package.dependencies,
        scripts: @package.scripts,
        widgets: widgets,
        assets: assets,
        tags: @package.tags
      )

      @api_key&.increment!(:publish_count) if @api_key

      render json: {
        message: "Package '#{@package.name}' created successfully!",
        package: {
          name: @package.name,
          version: @package.latest_version
        }
      }, status: :created
    else
      if @package.versions.exists?(version: @package.latest_version)
        render json: { error: "Version #{@package.latest_version} already exists for package '#{@package.name}'" }, status: :conflict
        return
      end

      @package.save!

      @package.versions.create!(
        version: @package.latest_version,
        description: @package.description,
        dragonruby_version: @package.dragonruby_version,
        dependencies: @package.dependencies,
        scripts: @package.scripts,
        widgets: widgets,
        assets: assets,
        tags: @package.tags
      )

      @api_key&.increment!(:publish_count) if @api_key

      render json: {
        message: "Package '#{@package.name}' v#{@package.latest_version} published successfully!",
        package: {
          name: @package.name,
          version: @package.latest_version
        }
      }
    end
  rescue ApiAuthController::PublishPermissionDenied => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package not found" }, status: :not_found
  end

  # GET /api/packages/updates
  # Returns all packages (for checking what exists)
  def updates
    packages = Package.select(:name, :latest_version).all
    render json: { packages: packages.map { |p| {
      name: p.name,
      version: p.latest_version
    }}}
  end

  # POST /api/packages/check_updates
  # Check for updates against a list of installed packages
  def check_updates
    installed = params[:packages] || {}
    updates = []

    installed.each do |name, current_version|
      pkg = Package.find_by(name: name)
      next unless pkg
      begin
        latest = pkg.latest_version
        if Gem::Version.new(latest) > Gem::Version.new(current_version.to_s)
          updates << {
            name: name,
            current_version: current_version,
            latest_version: latest,
            description: pkg.description,
            scripts: pkg.scripts,
            tags: pkg.tags
          }
        end
      rescue
        # Skip invalid version strings
      end
    end

    render json: { updates: updates }
  end

  # GET /api/packages/:name/latest
  def latest
    pkg = Package.find_by!(name: params[:id])
    render json: {
      name: pkg.name,
      version: pkg.latest_version,
      description: pkg.description,
      dragonruby_version: pkg.dragonruby_version,
      dependencies: pkg.dependencies,
      scripts: pkg.scripts,
      tags: pkg.tags
    }
  end

  # GET /api/packages/:name/versions/:version
  # Returns full version data including scripts, widgets, assets
  def version_info
    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])

    render json: {
      name: pkg.name,
      version: version.version,
      description: version.description || pkg.description,
      dragonruby_version: version.dragonruby_version || pkg.dragonruby_version,
      dependencies: version.dependencies,
      scripts: version.scripts,
      widgets: version.widgets,
      assets: version.assets,
      tags: version.tags || pkg.tags
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  end

  # GET /api/packages/all_versions
  # Returns all packages with their latest versions (for checking updates)
  def all_versions
    packages = Package.select(:name, :latest_version, :description).all
    versions = packages.map { |p| { name: p.name, version: p.latest_version } }
    render json: { packages: versions }
  end

  # POST /api/packages/check_updates
  def check_package_update(name, current_version, updates)
    pkg = Package.find_by(name: name)
    return unless pkg
    latest = Gem::Version.new(pkg.latest_version)
    current = Gem::Version.new(current_version.to_s)
    if latest > current
      updates << { name: name, current: current_version, latest: pkg.latest_version }
    end
  rescue
    # Skip invalid version strings
  end

  def check_updates
    installed = params[:packages] || {}
    updates = []

    installed.each do |name, current_version|
      pkg = Package.find_by(name: name)
      next unless pkg
      begin
        latest = Gem::Version.new(pkg.latest_version)
        current = Gem::Version.new(current_version.to_s)
        if latest > current
          updates << { name: name, current_version: current_version, latest_version: pkg.latest_version }
        end
      rescue
        # Skip invalid version strings
      end
    end
  end

  # GET /api/packages/:id/samples
  def samples
    pkg = Package.find_by!(name: params[:id])
    sample_list = pkg.samples.present? ? JSON.parse(pkg.samples) : []
    render json: { samples: sample_list }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package not found" }, status: :not_found
  end

  # GET /api/packages/:id/samples/:sample_name
  def sample
    pkg = Package.find_by!(name: params[:id])
    sample_name = params[:sample_name]

    sample_list = pkg.samples.present? ? JSON.parse(pkg.samples) : []
    unless sample_list.include?(sample_name)
      render json: { error: "Sample '#{sample_name}' not found" }, status: :not_found
      return
    end

    version = pkg.versions.ordered.last
    main_rb_content = nil
    if version
      reader = PackageFileReader.new(pkg, version)
      main_rb_content = reader.read_file("samples/#{sample_name}/app/main.rb")
    end

    render json: {
      name: sample_name,
      package: pkg.name,
      main_rb: main_rb_content || "# Sample '#{sample_name}' not available in package archive"
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or sample not found" }, status: :not_found
  end

  # GET /api/packages/:id/versions/:version/download
  # Downloads the package ZIP file.
  def download
    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])
    version.increment!(:download_count)

    if version.zip_file.attached?
      PackageStorageService.serve(version, self)
    else
      render json: { error: "Package file not found" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  end

  # POST /api/packages/:id/versions/:version/upload
  # Upload a ZIP file for a specific package version.
  def upload
    require_publish_permission

    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])

    zip_file = params[:zip_file]
    unless zip_file
      render json: { error: "No ZIP file provided" }, status: :bad_request
      return
    end

    unless zip_file.content_type == "application/zip" || zip_file.original_filename&.end_with?(".zip")
      render json: { error: "File must be a ZIP archive" }, status: :bad_request
      return
    end

    validation = PackageValidator.new(
      zip_file,
      expected_name: pkg.name,
      expected_version: version.version
    ).validate

    unless validation.valid?
      render json: { error: "Invalid package archive", details: validation.errors }, status: :unprocessable_entity
      return
    end

    begin
      version.zip_file.attach(io: zip_file.to_io, filename: "#{pkg.name}-#{version.version}.zip", content_type: "application/zip")
      render json: {
        message: "Package uploaded successfully",
        size: version.zip_file.blob.byte_size,
        warnings: validation.warnings
      }
    rescue => e
      render json: { error: "Upload failed: #{e.message}" }, status: :internal_server_error
    end
  rescue ApiAuthController::PublishPermissionDenied => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  end

  # DELETE /api/packages/:id/versions/:version/file
  def delete_file
    require_publish_permission

    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])

    if version.zip_file.attached?
      version.zip_file.purge
      render json: { message: "Package file deleted" }
    else
      render json: { error: "Package file not found" }, status: :not_found
    end
  rescue ApiAuthController::PublishPermissionDenied => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  end

  # GET /api/packages/:id/storage_info
  def storage_info
    pkg = Package.find_by!(name: params[:id])

    versions = pkg.versions.map do |v|
      stored = v.zip_file.attached?
      size = stored ? v.zip_file.blob.byte_size : 0
      { version: v.version, stored: stored, size_bytes: size, size_human: PackageStorageService.size_human(size) }
    end

    render json: {
      package: pkg.name,
      total_size_bytes: PackageStorageService.size_bytes(pkg),
      total_size_human: PackageStorageService.size_human(PackageStorageService.size_bytes(pkg)),
      versions: versions
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package not found" }, status: :not_found
  end

  # GET /api/packages/:id/versions/:version/files
  # Returns a list of all files in a package version
  def files
    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])
    reader = PackageFileReader.new(pkg, version)
    render json: { files: reader.file_list }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  end

  # GET /api/packages/:id/versions/:version/files/:path
  def file
    pkg = Package.find_by!(name: params[:id])
    version = pkg.versions.find_by!(version: params[:version])
    file_path = params[:path]
    # Reconstruct extension stripped by Rails format parsing
    if !file_path.include?('.') && params[:format].present?
      file_path = "#{file_path}.#{params[:format]}"
    end

    reader = PackageFileReader.new(pkg, version)
    content = reader.read_file(file_path)

    if content
      language = detect_file_language(file_path)
      render json: { path: file_path, content: content, language: language }
    else
      content = placeholder_content(pkg, version, file_path)
      render json: { path: file_path, content: content, language: "ruby", placeholder: true }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Package or version not found" }, status: :not_found
  rescue => e
    render json: { error: "Could not load file: #{e.message}" }, status: :not_found
  end

  private

  def placeholder_content(pkg, version, path)
    if path == "manifest.json"
      JSON.pretty_generate({
        "name" => pkg.name,
        "version" => version.version,
        "description" => pkg.description,
        "dependencies" => version.dependencies,
        "scripts" => version.scripts,
        "tags" => version.tags
      })
    elsif path.start_with?("scripts/")
      sname = path.split("/").last.to_s.sub(/\.rb$/, "").gsub("_", " ").split.map(&:capitalize).join("").freeze
      body = "# #{sname} script\n# Version: #{version.version}\n\nclass #{sname}Script < Forge::Script\n  def init\n    # Called when script is added to entity\n  end\n\n  def update\n    # Called every frame\n  end\nend\n"
      body
    elsif path.start_with?("widgets/")
      wname = path.split("/").last.to_s.sub(/\.rb$/, "").gsub("_", " ").split.map(&:capitalize).join("").freeze
      body = "# #{wname} widget\n# Version: #{version.version}\n\nclass #{wname}Widget < Forge::Widget\n  def render\n    # Called every frame\n  end\nend\n"
      body
    else
      "# File not available: #{path}\n# Download the package to get the full source.\n"
    end
  end

  def detect_file_language(path)
    return "ruby"    if path.end_with?(".rb")
    return "json"    if path.end_with?(".json")
    return "markdown" if path.end_with?(".md")
    return "yaml"    if path.end_with?(".yml") || path.end_with?(".yaml")
    "text"
  end
end
