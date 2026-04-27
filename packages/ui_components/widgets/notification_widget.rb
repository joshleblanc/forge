# frozen_string_literal: true

# NotificationWidget - Toast-style notification system for DragonRuby Forge.
#
# Displays transient messages that fade in, stay, and fade out.
# Uses args.outputs[:ui] for rendering.
#
# Usage:
#   # Attach to a persistent entity (e.g., game manager)
#   entity.add_widget(Forge::NotificationWidget)
#
#   # Show a notification
#   entity.notification_widget.notify("Hello!", duration: 3, type: :info)
#
#   # Notification types: :info (blue), :success (green), :warning (yellow), :error (red)

module Forge
  module Widgets
    class NotificationWidget < Forge::Widget
      # Notification queue item: { text:, type:, duration:, timer:, opacity: }
      NOTIFICATION_DEFAULTS = {
        duration: 2.5,
        type: :info,
        max_width: 400,
        padding: 12,
        font_size: 16,
        spacing: 8,
        stack_from: :top,
        max_visible: 5
      }

      NOTIFICATION_STYLES = {
        info:    { r: 74,  g: 144, b: 217, bg_r: 30,  bg_g: 60,  bg_b: 100 },
        success: { r: 166, g: 212, b: 161, bg_r: 30,  bg_g: 100, bg_b: 50  },
        warning: { r: 250, g: 200, b: 100, bg_r: 80,  bg_g: 60,  bg_b: 20  },
        error:   { r: 250, g: 100, b: 100, bg_r: 100, bg_g: 30,  bg_b: 30  }
      }

      def init
        @notifications = []
        @screen_padding = 16
        @fade_speed = 4.0  # seconds to fade in/out
      end

      # Show a notification
      # @param text [String] notification message
      # @param type [Symbol] :info, :success, :warning, :error
      # @param duration [Float] how long to display (seconds)
      def notify(text, type: :info, duration: NOTIFICATION_DEFAULTS[:duration])
        return if @notifications.any? { |n| n[:text] == text && n[:timer] < @fade_speed }

        # Limit max visible
        @notifications.shift if @notifications.length >= NOTIFICATION_DEFAULTS[:max_visible]

        @notifications << {
          text: text,
          type: type,
          duration: duration,
          timer: 0,
          opacity: 0,
          width: 0,
          height: 0
        }
      end

      def update
        return if @notifications.empty?

        args = entity.args
        return unless args

        # Calculate positions and sizes
        calculate_layout(args)

        # Update timers and remove expired
        @notifications.each do |n|
          n[:timer] += args.state.dt
          n[:opacity] = calculate_opacity(n)
        end

        @notifications.reject! { |n| n[:timer] > n[:duration] + @fade_speed && n[:opacity] <= 0 }
      end

      def render
        return if @notifications.empty?
        return unless entity.args

        args = entity.args
        screen_w = args.grid.w
        screen_h = args.grid.h
        out = args.outputs[:ui]

        @notifications.each do |n|
          x = screen_w - n[:width] - @screen_padding
          y = screen_h - @screen_padding - n[:y_offset]

          style = NOTIFICATION_STYLES[n[:type]] || NOTIFICATION_STYLES[:info]
          alpha = (n[:opacity] * 255).to_i

          # Background
          out.solids << {
            x: x,
            y: y,
            w: n[:width],
            h: n[:height],
            r: style[:bg_r],
            g: style[:bg_g],
            b: style[:bg_b],
            a: alpha
          }

          # Border
          out.borders << {
            x: x,
            y: y,
            w: n[:width],
            h: n[:height],
            r: style[:r],
            g: style[:g],
            b: style[:b],
            a: alpha
          }

          # Text
          out.labels << {
            x: x + NOTIFICATION_DEFAULTS[:padding],
            y: y + n[:height] / 2,
            text: n[:text],
            r: 255, g: 255, b: 255, a: alpha,
            size: NOTIFICATION_DEFAULTS[:font_size],
            anchor_y: 0.5
          }
        end
      end

      # Clear all notifications
      def clear
        @notifications.clear
      end

      private

      def calculate_layout(args)
        screen_h = args.grid.h

        y_offset = NOTIFICATION_DEFAULTS[:spacing]
        @notifications.each do |n|
          n[:y_offset] = y_offset
          n[:width] = calculate_text_width(n[:text], args) + NOTIFICATION_DEFAULTS[:padding] * 2
          n[:width] = [n[:width], NOTIFICATION_DEFAULTS[:max_width]].min
          n[:height] = NOTIFICATION_DEFAULTS[:font_size] + NOTIFICATION_DEFAULTS[:padding] * 2
          y_offset += n[:height] + NOTIFICATION_DEFAULTS[:spacing]
        end
      end

      def calculate_text_width(text, args)
        # Approximate: each character is ~0.6 * font_size wide
        char_width = NOTIFICATION_DEFAULTS[:font_size] * 0.6
        (text.length * char_width).to_i
      end

      def calculate_opacity(n)
        timer = n[:timer]
        duration = n[:duration]
        fade = @fade_speed

        if timer < fade
          # Fade in
          timer / fade
        elsif timer > duration
          # Fade out
          [(duration + fade - timer) / fade, 0].max
        else
          # Fully visible
          1.0
        end
      end
    end
  end
end
