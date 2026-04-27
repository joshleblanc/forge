# frozen_string_literal: true

require_relative "tile_instance"
require_relative "entity_instance"

module Forge
  module Ldtk
    class LayerInstance < Base
      imports :c_hei, :c_wid, :grid_size, :identifier, :opacity, :px_total_offset_x,
              :px_total_offset_y, :tileset_def_uid, :tileset_rel_path, :type,
              :int_grid_csv, :layer_def_uid, :level_id, :override_tileset_uid,
              :px_offset_x, :px_offset_y, :visible, :int_grid, :iid,
              auto_layer_tiles: [TileInstance], entity_instances: [EntityInstance],
              grid_tiles: [TileInstance]

      # Check if a grid cell has collision (value == 1 in int grid)
      # @param cx [Integer] cell x
      # @param cy [Integer] cell y
      # @return [Boolean]
      def has_collision(x, y)
        int(x, y).to_i == 1
      end

      # Get all tiles (auto_layer or grid tiles)
      # @return [Array<TileInstance>]
      def tiles
        @tiles ||= if auto_layer_tiles.length > 0
          auto_layer_tiles
        elsif grid_tiles.length > 0
          grid_tiles
        else
          []
        end
      end

      # Get the int grid value at a cell position
      # @param cx [Integer] cell x
      # @param cy [Integer] cell y
      # @return [Integer,nil]
      def int(cx, cy)
        return nil if cx < 0 || cy < 0 || cx >= c_wid || cy >= c_hei
        pos = cx + (cy * c_wid)
        int_grid_csv[pos] if int_grid_csv.is_a?(Array)
      end

      # Find an entity instance by its IID
      # @param id [String] entity IID
      # @return [EntityInstance,nil]
      def entity(id)
        entity_instances.find { |i| i.iid == id }
      end

      # Get all entity instances, optionally filtered by IID
      # @param id [String,nil] optional IID to filter by
      # @return [Array<EntityInstance>]
      def entities(id = nil)
        if id.nil?
          entity_instances
        else
          entity_instances.select { |i| i.iid == id }
        end
      end

      # Get tile rects for rendering (position + index)
      # @return [Array<Array>] [[x, y, grid_size, grid_size, index], ...]
      def tile_rects
        @tile_rects ||= tiles.map.with_index do |tile, index|
          [tile.px[0], tile.px[1], grid_size, grid_size, index]
        end
      end
    end
  end
end
