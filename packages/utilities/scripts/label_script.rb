# frozen_string_literal: true

# LabelScript for DragonRuby Forge
# Renders a floating text label above an entity.
# Useful for name tags, damage numbers, and status indicators.
#
# Usage:
#   entity.add_script(Forge::LabelScript.new(label: "Enemy", font_size: -1))
#
#   # Options:
#   #   label:      text to display (default: "")
#   #   font_size:  DragonRuby font size (default: -1)
#   #   color:     RGB array [r, g, b] (default: [255, 255, 255])
#   #   offset_y:  pixels above entity center (default: 65)
#   #   bg_alpha:  background opacity 0-255 (default: 125)
#   #   show_bg:   show background box (default: true)

class LabelScript < Forge::Script
  def init
    @label = options[:label] || ""
    @font_size = options[:font_size] || -1
    @color = options[:color] || [255, 255, 255]
    @offset_y = options[:offset_y] || 65
    @bg_alpha = options[:bg_alpha] || 125
    @show_bg = options.fetch(:show_bg, true)
  end

  def label=(text)
    @label = text
  end

  def post_update
    return unless entity.args

    ex = entity.x || 0
    ey = entity.y || 0
    ew = entity.w || entity.respond_to?(:tile_w) ? entity.tile_w : 16
    out = entity.args.outputs[:ui]

    # Label position (above entity)
    label_x = ex + ew / 2
    label_y = ey + @offset_y

    # Get text dimensions
    tw = 0
    th = 8
    if entity.args.respond_to?(:gtk)
      tw, th = entity.args.gtk.calcstringbox(@label, @font_size)
    end

    # Background box
    if @show_bg
      pad = 8
      bg_w = tw + pad * 2 - 2
      bg_h = th + pad * 2
      bg_x = ex + ew / 2 - bg_w / 2
      bg_y = label_y - bg_h / 2

      out.solids << {
        x: bg_x, y: bg_y, w: bg_w, h: bg_h,
        r: 0, g: 0, b: 0, a: @bg_alpha
      }
      out.borders << {
        x: bg_x, y: bg_y, w: bg_w, h: bg_h,
        r: @color[0], g: @color[1], b: @color[2], a: 200
      }
    end

    # Text
    out.labels << {
      x: label_x,
      y: label_y,
      text: @label,
      font_size: @font_size,
      alignment_enum: 1,
      vertical_alignment_enum: 0,
      r: @color[0], g: @color[1], b: @color[2], a: 255
    }
  end
end
