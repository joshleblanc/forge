# frozen_string_literal: true

module Forge
  module Ldtk
    class World < Base
      imports :identifier, :iid, :world_grid_height, :world_grid_width,
              :world_layout, levels: [Level]

      def free?
        world_layout == "Free"
      end

      def grid_vania?
        world_layout == "GridVania"
      end

      def linear_horizontal?
        world_layout == "LinearHorizontal"
      end

      def linear_vertical?
        world_layout == "LinearVertical"
      end
    end
  end
end
