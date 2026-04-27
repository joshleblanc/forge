# frozen_string_literal: true

module Forge
  module Ldtk
    class TileInstance < Base
      # a = alpha, f = flip (0=none, 1=h, 2=v, 3=hv), px = position, src = source rect, t = tileset uid
      imports :a, :f, :px, :src, :t

      # Returns the x position in pixels
      def x
        px[0] if px.is_a?(Array)
      end

      # Returns the y position in pixels
      def y
        px[1] if px.is_a?(Array)
      end

      # Returns source x
      def src_x
        src[0] if src.is_a?(Array)
      end

      # Returns source y
      def src_y
        src[1] if src.is_a?(Array)
      end

      # Returns true if horizontally flipped
      def flip_h?
        f == 1 || f == 3
      end

      # Returns true if vertically flipped
      def flip_v?
        f == 2 || f == 3
      end

      # Returns the tileset for this tile
      def tileset
        root.tileset(t)
      end
    end
  end
end
