class Packages::PublishController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :require_login
  
  def new
    @package = Package.new
  end

  def create
    # Parse dependencies from text format
    dependencies = {}
    if params[:package][:dependencies_text].present?
      params[:package][:dependencies_text].split("\n").each do |line|
        line = line.strip
        next if line.empty?
        # Parse "package (version)" format
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

    @package = Package.new(
      name: params[:package][:name],
      latest_version: params[:package][:latest_version],
      description: params[:package][:description],
      dragonruby_version: params[:package][:dragonruby_version] || ">= 3.0",
      dependencies: dependencies,
      scripts: scripts,
      tags: tags
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
      
      redirect_to package_path(@package.name), notice: "Package '#{@package.name}' published successfully!"
    else
      flash.now[:alert] = @package.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end
end
