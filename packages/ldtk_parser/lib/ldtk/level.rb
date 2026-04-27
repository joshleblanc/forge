# frozen_string_literal: true

require_relative "field_instance"
require_relative "layer_instance"

module Forge
  module Ldtk
    class Level < Base
      include Serializable

      # Neighbours is an array of objects with shape: { dir, levelIid, levelUid }
      # bg_pos has shape: { cropRect: [int, int, int, int], scale, topLeftpx }
      imports :bg_color, :bg_pos, :neighbours, :bg_rel_path, :external_rel_path,
              :identifier, :iid, :px_hei, :px_wid, :uid, :world_depth, :world_x, :world_y,
              field_instances: [FieldInstance], layer_instances: [LayerInstance]

      # Check if a pixel position has collision in the "Collisions" layer
      # @param x [Integer] pixel x
      # @param y [Integer] pixel y
      # @return [Boolean]
      def has_collision(x, y)
        layer("Collisions")&.has_collision(x, y)
      end

      # Get a layer by its identifier
      # @param id [String] layer identifier
      # @return [LayerInstance,nil]
      def layer(id)
        return nil unless layer_instances
        layer_instances.find { |i| i.identifier == id }
      end

      # Convert world coordinates to level-local coordinates
      # @param x [Integer] world x
      # @param y [Integer] world y
      # @return [Array<Integer>] [local_x, local_y]
      def world_pos_to_level_pos(x, y)
        [x - world_x, y - world_y]
      end

      # Find a neighbour level at a given cell position
      # @param cx [Integer] cell x (uses grid_size)
      # @param cy [Integer] cell y (uses grid_size)
      # @param grid_size [Integer] grid size in pixels (default: Forge::Ldtk.grid_size)
      # @return [Level,nil]
      def find_neighbour(cx, cy, grid_size: Forge::Ldtk.grid_size)
        x = cx * grid_size
        y = cy * grid_size

        neighbours.each do |n|
          level = root.level(iid: n[:levelIid])
          next unless level

          # Simple AABB intersection check
          inside = x >= level.world_x &&
                   x < level.world_x + level.px_wid &&
                   y >= level.world_y &&
                   y < level.world_y + level.px_hei

          return level if inside
        end

        nil
      end

      # Check if a cell position is outside the level bounds
      # @param cx [Integer] cell x
      # @param cy [Integer] cell y
      # @return [Boolean]
      def outside?(cx, cy)
        cx < 0 || cx >= (px_wid / grid_size) || cy < 0 || cy >= (px_hei / grid_size)
      end

      # Find an entity instance by its IID in the Entities layer
      # @param id [String] entity IID
      # @return [EntityInstance,nil]
      def entity(id)
        layer("Entities")&.entity(id)
      end

      # Get all entity instances from the Entities layer, optionally filtered by IID
      # @param id [String,nil] optional IID filter
      # @return [Array<EntityInstance>]
      def entities(id = nil)
        layer("Entities")&.entities(id) || []
      end

      # Get a field value from the level
      # @param id [String] field identifier
      # @return [Object]
      def field(id)
        return nil unless field_instances
        field_instances.select { |i| i.identifier == id }.map { |i| i.value }.flatten
      end
    end
  end
end
