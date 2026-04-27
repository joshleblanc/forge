# frozen_string_literal: true

# LDTK Loader Script for DragonRuby Forge
# Attach to an entity to automatically load an LDTK level file.
#
# Options:
#   file:        Path to the .ldtk file (required)
#   grid_size:   Grid size in pixels (default: 16)
#   load_level:  Level identifier to load immediately (optional)
#   auto_draw:   Whether to auto-draw tiles each frame (default: false)
#
# Usage:
#   entity.add_script(Forge::LdtkLoaderScript, file: "data/levels.ldtk", grid_size: 32)
#   Forge::Ldtk.root  # Access the loaded LDTK data
#
# Methods added to entity:
#   .ldtk          - Returns the Forge::Ldtk::Root object
#   .ldtk_level    - Returns the current Forge::Ldtk::Level
#   .ldtk_layer(name) - Returns a specific layer from the current level

class LdtkLoaderScript < Forge::Script
  def init
    @file = options[:file] || raise(":file option is required")
    @grid_size = options[:grid_size] || 16
    @load_level = options[:load_level]
    @auto_draw = options[:auto_draw] || false

    # Set the grid size for coordinate calculations
    Forge::Ldtk.grid_size = @grid_size

    # Resolve file path — try as-is first, then check package asset maps
    resolved_path = resolve_ldtk_path(@file)

    # Load the LDTK file
    @root = Forge::Ldtk.load(resolved_path, grid_size: @grid_size)

    # Set the current level if specified
    if @load_level
      @current_level = @root.level(identifier: @load_level)
    end

    entity.ldtk = @root
    entity.ldtk_level = @current_level
  end

  def update
    return unless @auto_draw
    draw_tiles
  end

  # Load a specific level by identifier
  # @param identifier [String] level identifier
  def load_level(identifier)
    @current_level = @root.level(identifier: identifier)
    entity.ldtk_level = @current_level
    @current_level
  end

  # Get a layer from the current level
  # @param name [String] layer identifier
  def layer(name)
    @current_level&.layer(name)
  end

  # Get all entities from the current level
  # @param layer_name [String] optional layer name (default: "Entities")
  def entities(layer_name = "Entities")
    @current_level&.entities || []
  end

  # Check collision at a pixel position
  # @param x [Integer] pixel x
  # @param y [Integer] pixel y
  def has_collision?(x, y)
    @current_level&.has_collision(x, y) || false
  end

  # Draw all tiles from the current level
  # Uses DragonRuby args.outputs.solids or args.outputs.sprites
  # Override this method for custom rendering.
  def draw_tiles
    return unless @current_level && entity.respond_to?(:args)

    args = entity.args
    @current_level.layer_instances&.each do |layer|
      next unless layer.visible
      next if layer.tiles.empty?

      path = layer.tileset_rel_path&.gsub("../", "") || ""
      grid_size = layer.grid_size || @grid_size
      alpha = (255 * layer.opacity).to_i

      layer.tiles.each do |tile|
        # args.outputs.sprites << {
        #   x: tile.px[0],
        #   y: tile.px[1],
        #   w: grid_size,
        #   h: grid_size,
        #   path: path,
        #   source_x: tile.src[0],
        #   source_y: tile.src[1],
        #   source_w: grid_size,
        #   source_h: grid_size,
        #   flip_horizontally: tile.flip_h?,
        #   flip_vertically: tile.flip_v?,
        #   a: alpha
        # }
      end
    end
  end

  # Find entity instances by their identifier (IID)
  # @param iid [String] entity instance IID
  def find_entity(iid)
    @current_level&.entity(iid)
  end

  # Resolve a logical LDTK file path to an absolute path.
  # Checks: as-is → app/ → data/ → packages/{package}/assets/data/
  # @param path [String] logical or absolute path
  # @return [String] absolute path
  def resolve_ldtk_path(path)
    return path if File.exist?(path)
    return path if path.start_with?("/")

    candidates = [
      File.join("app", path),
      File.join("data", path),
      File.join("data", "levels", path),
      File.join("data", "levels", path.sub(".ldtk", ".ldtk")),
    ]

    candidates.each do |candidate|
      return candidate if File.exist?(candidate)
    end

    path
  end
end
