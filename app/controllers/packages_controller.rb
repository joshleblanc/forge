require 'ostruct'

class PackagesController < ApplicationController
  def index
    @packages = Package.all
    @packages = @packages.search(params[:search]) if params[:search].present?
    @packages = @packages.filter_by_tag(params[:tag]) if params[:tag].present?
    @packages = @packages.ordered

    # Get all unique tags for filtering
    @all_tags = Package.pluck(:tags).flatten.compact.uniq.sort
  end

  def show
    @package = Package.find_by!(name: params[:id])
    @selected_version = params[:version] || @package.latest_version
    @version = @package.versions.find_by(version: @selected_version)
    
    # Parse samples from JSON string
    @samples = @package.samples.present? ? JSON.parse(@package.samples) : []
    
    # If no version record exists, use package metadata
    @version ||= OpenStruct.new(
      version: @selected_version,
      description: @package.description,
      dragonruby_version: @package.dragonruby_version,
      dependencies: @package.dependencies,
      scripts: @package.scripts,
      tags: @package.tags,
      source_code: sample_source_code(@package.name)
    )
  end

  private

  def sample_source_code(package_name)
    case package_name
    when 'health'
      <<~RUBY
# Health package for Forge
# Provides health tracking for game entities

class HealthScript < Forge::Script
  def init
    @max_health = entity.properties[:max_health] || 100
    @current_health = @max_health
  end

  def update
    # Health regeneration logic can go here
    if @current_health < @max_health && entity.properties[:regen_rate]
      @current_health = [@max_health, @current_health + entity.properties[:regen_rate]].min
    end
  end

  def take_damage(amount, source = nil)
    return if @current_health <= 0
    
    @current_health -= amount
    entity.invoke(:on_damage, amount, source)
    
    if @current_health <= 0
      @current_health = 0
      entity.invoke(:on_death)
    end
  end

  def heal(amount)
    @current_health = [@max_health, @current_health + amount].min
    entity.invoke(:on_heal, amount)
  end

  def current_health
    @current_health
  end

  def max_health
    @max_health
  end

  def health_percentage
    (@current_health.to_f / @max_health) * 100
  end

  def alive?
    @current_health > 0
  end
end
      RUBY
    when 'physics'
      <<~RUBY
# Physics package for Forge
# Basic physics system with gravity and collision

class PhysicsScript < Forge::Script
  def init
    @velocity_x = entity.properties[:velocity_x] || 0
    @velocity_y = entity.properties[:velocity_y] || 0
    @gravity = entity.properties[:gravity] || 0.5
    @friction = entity.properties[:friction] || 0.9
    @grounded = false
  end

  def update
    # Apply gravity
    @velocity_y -= @gravity
    
    # Apply friction to horizontal movement
    @velocity_x *= @friction
    
    # Update position
    entity.x += @velocity_x
    entity.y += @velocity_y
    
    # Ground collision (simplified)
    if entity.y <= 0
      entity.y = 0
      @velocity_y = 0
      @grounded = true
    end
  end

  def apply_force(x, y)
    @velocity_x += x
    @velocity_y += y
  end

  def grounded?
    @grounded
  end
end
      RUBY
    else
      <<~RUBY
# #{package_name.titleize} package for Forge
# Add your package code here

class #{package_name.split('_').map(&:capitalize).join}Script < Forge::Script
  def init
    # Initialize your script
  end

  def update
    # Called every frame
  end
end
      RUBY
    end
  end
end
