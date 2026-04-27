# frozen_string_literal: true

# DragonRuby Forge - LDTK Parser Package
# Parse and use LDTK (LDtk) level editor files in DragonRuby games.
#
# Usage:
#   Forge.add_package("ldtk_parser")
#   # Then in your game:
#   Forge::Ldtk.load("path/to/my.ldtk")
#
# Or use the script:
#   entity.add_script(Forge::LdtkLoaderScript, file: "data/levels.ldtk")

require_relative "ldtk/base"
require_relative "ldtk/serializable"
require_relative "ldtk/definitions"
require_relative "ldtk/enum_definition"
require_relative "ldtk/enum_value_definition"
require_relative "ldtk/tileset_definition"
require_relative "ldtk/tileset_rect"
require_relative "ldtk/field_definition"
require_relative "ldtk/layer_definition"
require_relative "ldtk/entity_definition"
require_relative "ldtk/tile_instance"
require_relative "ldtk/field_instance"
require_relative "ldtk/entity_instance"
require_relative "ldtk/layer_instance"
require_relative "ldtk/level"
require_relative "ldtk/world"
require_relative "ldtk/root"

module Forge
  module Ldtk
    class << self
      # Load an LDTK file from a path or JSON string
      # @param source [String] - file path or JSON string
      # @param grid_size [Integer] - grid size in pixels (default: 16)
      # @return [Forge::Ldtk::Root]
      def load(source, grid_size: 16)
        json = if File.exist?(source)
          JSON.parse(File.read(source))
        elsif source.is_a?(String) && source.start_with?("{")
          JSON.parse(source)
        else
          raise ArgumentError, "LDTK source must be a valid file path or JSON string"
        end

        @grid_size = grid_size
        Root.import(json)
      end

      # Get the configured grid size
      # @return [Integer]
      def grid_size
        @grid_size || 16
      end

      # Set the grid size for coordinate calculations
      # @param size [Integer]
      def grid_size=(size)
        @grid_size = size
      end
    end
  end
end
