# frozen_string_literal: true

# ProgressBarWidget - A customizable progress bar for DragonRuby Forge.
#
# Can display a value between 0 and max, with optional label and percentage.
#
# Usage:
#   entity.add_widget(Forge::ProgressBarWidget)
#   entity.progress_bar_widget.set(75, 100)  # 75 out of 100
#   entity.progress_bar_widget.set_percent(0.5)  # 50%

module Forge
  module Widgets
    class ProgressBarWidget < Forge::Widget
      def init
        @value = 0
        @max = 100
        @label = ""
        @show_percent = true
        @animate_speed = 2.0  # lerp speed toward target
        @display_value = 0

        # Visual config
        @width = 200
        @height = 24
        @padding = 4
        @corner_radius = 4

        # Colors
        @bar_color = { r: 74, g: 144, b: 217 }
        @bar_bg_color = { r: 40, g: 40, b: 60 }
        @border_color = { r: 100, g: 100, b: 140 }
        @text_color = { r: 255, g: 255, b: 255 }
      end

      # Set the current value and max
      # @param value [Numeric]
      # @param max [Numeric]
      def set(value, max = nil)
        @value = value.to_f
        @max = max.to_f if max
        @max = 1 if @max == 0
      end

      # Set value as a percentage (0-1)
      # @param percent [Numeric]
      def set_percent(percent)
        @value = percent.clamp(0, 1) * @max
      end

      # Get current percentage (0-1)
      # @return [Float]
      def percent
        return 0 if @max == 0
        (@value / @max).clamp(0, 1)
      end

      # Get percentage as integer (0-100)
      # @return [Integer]
      def percent_i
        (percent * 100).to_i
      end

      # Set the label text
      # @param text [String]
      def label=(text)
        @label = text
      end

      # Set bar color
      # @param r [Integer] 0-255
      # @param g [Integer] 0-255
      # @param b [Integer] 0-255
      def bar_color=(rgb)
        @bar_color = { r: rgb[0], g: rgb[1], b: rgb[2] }
      end

      # Set dimensions
      # @param w [Integer] width in pixels
      # @param h [Integer] height in pixels
      def size=(w, h)
        @width = w
        @height = h
      end

      def update
        # Smooth animation toward target value
        return if entity.args.nil?
        dt = entity.args.state.dt
        diff = @value - @display_value
        @display_value += diff * [@animate_speed * dt, 1].min
      end

      def render
        return if entity.args.nil?

        args = entity.args
        x = entity.x || 0
        y = entity.y || 0
        out = args.outputs[:ui]

        inner_w = @width - @padding * 2
        inner_h = @height - @padding * 2
        inner_y = y + @padding

        # Background
        out.solids << {
          x: x, y: y, w: @width, h: @height,
          r: @bar_bg_color[:r], g: @bar_bg_color[:g], b: @bar_bg_color[:b]
        }

        # Progress fill
        display_percent = @max > 0 ? (@display_value / @max).clamp(0, 1) : 0
        fill_w = (inner_w * display_percent).to_i

        if fill_w > 0
          out.solids << {
            x: x + @padding, y: inner_y,
            w: fill_w, h: inner_h,
            r: @bar_color[:r], g: @bar_color[:g], b: @bar_color[:b]
          }
        end

        # Border
        out.borders << {
          x: x, y: y, w: @width, h: @height,
          r: @border_color[:r], g: @border_color[:g], b: @border_color[:b]
        }

        # Text label
        if @show_percent
          text = "#{percent_i}%"
          out.labels << {
            x: x + @width / 2,
            y: inner_y + inner_h / 2,
            text: text,
            r: @text_color[:r], g: @text_color[:g], b: @text_color[:b],
            size: @height - @padding * 2 - 2,
            anchor_x: 0.5, anchor_y: 0.5
          }
        elsif @label != ""
          out.labels << {
            x: x + @padding,
            y: inner_y + inner_h / 2,
            text: @label,
            r: @text_color[:r], g: @text_color[:g], b: @text_color[:b],
            size: @height - @padding * 2 - 2,
            anchor_x: 0, anchor_y: 0.5
          }
        end
      end
    end
  end
end
