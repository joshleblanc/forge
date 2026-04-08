class Api::PackagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:updates, :check_updates, :index, :publish]
  before_action :require_login, only: [:publish]
  
  # GET /api/packages
  def index
    packages = Package.select(:name, :latest_version, :description, :author, :dragonruby_version, :dependencies, :scripts, :tags, :samples).all
    render json: { packages: packages.map { |p| {
      name: p.name,
      latest_version: p.latest_version,
      description: p.description,
      author: p.author,
      dragonruby_version: p.dragonruby_version,
      dependencies: p.dependencies,
      scripts: p.scripts,
      tags: p.tags,
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

    # Find or create the package
    @package = Package.find_or_initialize_by(name: params[:package][:name])
    
    @package.latest_version = params[:package][:latest_version]
    @package.description = params[:package][:description]
    @package.dragonruby_version = params[:package][:dragonruby_version] || ">= 3.0"
    @package.dependencies = dependencies
    @package.scripts = scripts
    @package.tags = tags
    @package.samples = samples
    @package.author = current_user.username
    
    if @package.new_record?
      # Check for duplicate name (another user might have it)
      if Package.exists?(name: @package.name)
        render json: { error: "Package name '#{@package.name}' is already taken" }, status: :conflict
        return
      end
      @package.save!
      
      # Create initial version record
      @package.versions.create!(
        version: @package.latest_version,
        description: @package.description,
        dragonruby_version: @package.dragonruby_version,
        dependencies: @package.dependencies,
        scripts: @package.scripts,
        tags: @package.tags
      )
      
      render json: { 
        message: "Package '#{@package.name}' created successfully!",
        package: {
          name: @package.name,
          version: @package.latest_version
        }
      }, status: :created
    else
      # Check if this version already exists
      if @package.versions.exists?(version: @package.latest_version)
        render json: { error: "Version #{@package.latest_version} already exists for package '#{@package.name}'" }, status: :conflict
        return
      end
      
      @package.save!
      
      # Create new version record
      @package.versions.create!(
        version: @package.latest_version,
        description: @package.description,
        dragonruby_version: @package.dragonruby_version,
        dependencies: @package.dependencies,
        scripts: @package.scripts,
        tags: @package.tags
      )
      
      render json: { 
        message: "Package '#{@package.name}' updated with version #{@package.latest_version}!",
        package: {
          name: @package.name,
          version: @package.latest_version
        }
      }
    end
  end
  
  # GET /api/packages/updates
  # Query params: packages=health:1.0.0,physics:1.0.0 or packages[health]=1.0.0
  def updates
    updates = []
    
    # Try to parse packages from various formats
    packages_param = params[:packages]
    
    if packages_param.is_a?(Hash)
      packages_param.each do |name, current_version|
        check_package_update(name, current_version, updates)
      end
    elsif packages_param.is_a?(String) && packages_param.include?(',')
      # Format: health:1.0.0,physics:1.0.0
      packages_param.split(',').each do |pair|
        name, version = pair.split(':')
        check_package_update(name, version, updates) if name && version
      end
    end
    
    render json: { updates: updates }
  end

  def check_package_update(name, current_version, updates)
    return unless name.present? && current_version.present?
    
    pkg = Package.find_by(name: name.strip)
    if pkg
      latest = pkg.latest_version
      begin
        if Gem::Version.new(latest) > Gem::Version.new(current_version)
          updates << {
            name: name.strip,
            current_version: current_version.strip,
            latest_version: latest,
            description: pkg.description
          }
        end
      rescue
        # Skip invalid version strings
      end
    end
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

  # GET /api/packages/all_versions
  # Returns all packages with their latest versions (for checking updates)
  def all_versions
    packages = Package.select(:name, :latest_version, :description).all
    versions = packages.map { |p| { name: p.name, version: p.latest_version } }
    render json: { packages: versions }
  end

  # POST /api/packages/check_updates
  # Check for updates against a list of installed packages
  def check_updates
    # Parse packages from JSON body: { packages: { health: "1.0.0", physics: "1.0.0" } }
    installed = params[:packages] || {}
    updates = []
    
    installed.each do |name, current_version|
      pkg = Package.find_by(name: name)
      if pkg
        begin
          if Gem::Version.new(pkg.latest_version) > Gem::Version.new(current_version.to_s)
            updates << {
              name: name,
              current_version: current_version,
              latest_version: pkg.latest_version,
              description: pkg.description
            }
          end
        rescue
          # Skip invalid versions
        end
      end
    end
    
    render json: { updates: updates }
  end

  # GET /api/packages/:id/samples
  def samples
    pkg = Package.find_by!(name: params[:id])
    sample_list = pkg.samples.present? ? JSON.parse(pkg.samples) : []
    
    render json: { samples: sample_list.map { |s| { name: s } } }
  end

  # GET /api/packages/:id/samples/:sample_name
  def sample
    pkg = Package.find_by!(name: params[:id])
    sample_name = params[:sample_name]
    
    # Check if sample exists
    sample_list = pkg.samples.present? ? JSON.parse(pkg.samples) : []
    unless sample_list.include?(sample_name)
      render json: { error: "Sample '#{sample_name}' not found" }, status: :not_found
      return
    end

    # For now, we look up the sample from the local packages folder
    # In production, this would be stored in the database or file storage
    # Check multiple possible locations
    possible_paths = [
      Rails.root.join('packages', pkg.name, 'samples', sample_name, 'app', 'main.rb'),
      Pathname.new('/mnt/c/source/dragonruby/forge/packages').join(pkg.name, 'samples', sample_name, 'app', 'main.rb'),
      Pathname.new(ENV.fetch('FORGE_PACKAGES_PATH', '')).join(pkg.name, 'samples', sample_name, 'app', 'main.rb').presence
    ].compact
    
    package_source_path = possible_paths.find { |p| File.exist?(p) }
    
    if package_source_path
      main_rb_content = File.read(package_source_path)
      render json: {
        name: sample_name,
        package: pkg.name,
        main_rb: main_rb_content
      }
    else
      # Sample file not found locally - return placeholder for demo
      render json: {
        name: sample_name,
        package: pkg.name,
        main_rb: "# Sample '#{sample_name}' for #{pkg.name}\n# This sample is available in the published package\n\nputs \"Hello from #{sample_name} sample!\""
      }
    end
  end
end
