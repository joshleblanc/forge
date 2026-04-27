# frozen_string_literal: true

module Forge
  module Ldtk
    class FieldInstance < Base
      imports :identifier, :type, :value, :def_uid, tile: TilesetRect

      def definition
        root.defs.level_fields.find { |f| f.uid == def_uid }
      end
    end
  end
end
