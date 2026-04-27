# frozen_string_literal: true

module Forge
  module Ldtk
    class EntityInstance < Base
      imports :grid, :identifier, :pivot, :smart_color, :tags,
              :world_x, :world_y, :def_uid, :height,
              :iid, :px, :width, field_instances: [FieldInstance], tile: TilesetRect

      # Get the value of a field by its identifier
      # @param id [String] field identifier
      # @return [Object] field value
      def field(id)
        field_instances.select { |i| i.identifier == id }.map { |i| i.value }.flatten
      end

      # Get the entity definition for this instance
      # @return [EntityDefinition]
      def definition
        root.entity(def_uid)
      end

      # Get the x position
      # @return [Integer]
      def x
        px[0] if px.is_a?(Array)
      end

      # Get the y position
      # @return [Integer]
      def y
        px[1] if px.is_a?(Array)
      end
    end
  end
end
