# frozen_string_literal: true

require_relative "base"
require_relative "definitions"
require_relative "level"
require_relative "world"

module Forge
  module Ldtk
    class Root < Base
      imports :bg_color, :external_levels, :iid, :json_version,
              :toc, :world_grid_height, :world_grid_width,
              :world_layout, worlds: [World], levels: [Level], defs: Definitions

      # Check if this is a free-form world layout
      # @return [Boolean]
      def free?
        world_layout == "Free"
      end

      # Find a level by any attribute
      # @param query [Hash] attribute => value pairs
      # @return [Level,nil]
      def level(**query)
        levels.find do |i|
          query.any? do |k, v|
            i.send(k.to_s) == v
          end
        end
      end

      # Find an enum definition by its identifier
      # @param id [String] enum identifier
      # @return [EnumDefinition,nil]
      def enum(id)
        defs.enums.find { |i| i.identifier == id }
      end

      # Find a world by its identifier
      # @param id [String] world identifier
      # @return [World,nil]
      def world(id)
        defs.worlds.find { |i| i.identifier == id }
      end

      # Find a tileset by its UID
      # @param uid [Integer] tileset UID
      # @return [TilesetDefinition,nil]
      def tileset(uid)
        defs.tilesets.find { |i| i.uid == uid }
      end

      # Find an entity definition by its UID
      # @param uid [Integer] entity UID
      # @return [EntityDefinition,nil]
      def entity(uid)
        defs.entities.find { |i| i.uid == uid }
      end

      def grid_vania?
        world_layout == "GridVania"
      end

      def linear_horizontal?
        world_layout == "LinearHorizontal"
      end

      def linear_vertical
        world_layout == "LinearVertical"
      end
    end
  end
end
