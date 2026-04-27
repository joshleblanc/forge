# frozen_string_literal: true

module Forge
  module Ldtk
    class FieldDefinition < Base
      imports :identifier, :uid, :ctype, :displayed_type, :default_override,
              :can_translate, :has_indexing, :optional, :array_max_length,
              :array_min_length, :doc, :editor_color, :editor_fold_style,
              :editor_if_condition, :editor_show_in_world_map, :editor_stack_height,
              :export_to_toc, :json_width_scale, :max, :min, :regex,
              :tile_size, :type_defs, :visible, :world_layout, :world_x, :y_first
    end
  end
end
