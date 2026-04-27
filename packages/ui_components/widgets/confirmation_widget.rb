# frozen_string_literal: true

# ConfirmationWidget - A yes/no confirmation dialog for DragonRuby Forge.
#
# Usage:
#   entity.add_widget(Forge::ConfirmationWidget)
#
#   entity.confirmation_widget.confirm(
#     title: "Delete Save?",
#     message: "This cannot be undone.",
#     on_yes: -> { delete_save },
#     on_no: -> { }
#   )
#
#   # In your game's update loop:
#   entity.confirmation_widget.handle_input(args)

module Forge
  module Widgets
    class ConfirmationWidget < Forge::Widget
      def init
        @visible = false
        @title = "Confirm"
        @message = ""
        @yes_text = "Yes"
        @no_text = "No"
        @on_yes = nil
        @on_no = nil
        @focused = :yes  # or :no
      end

      # Show the confirmation dialog
      # @param title [String]
      # @param message [String]
      # @param yes_text [String]
      # @param no_text [String]
      # @param on_yes [Proc,nil]
      # @param on_no [Proc,nil]
      def confirm(title: "Confirm", message: "", yes_text: "Yes", no_text: "No",
                  on_yes: nil, on_no: nil)
        @title = title
        @message = message
        @yes_text = yes_text
        @no_text = no_text
        @on_yes = on_yes
        @on_no = on_no
        @focused = :yes
        show!
      end

      def handle_input(args)
        return unless @visible
        return unless entity.args

        # Arrow keys to switch focus
        if args.inputs.keyboard.key_held.left || args.inputs.keyboard.key_held.right
          @focused = @focused == :yes ? :no : :yes
        end

        # Enter or Space to confirm
        if args.inputs.keyboard.key_down.enter || args.inputs.keyboard.key_down.space
          if @focused == :yes
            do_yes
          else
            do_no
          end
        end

        # Escape to cancel
        if args.inputs.keyboard.key_down.escape
          do_no
        end
      end

      def update
        # Called each frame - handle_input should be called separately
        # because this needs args passed through
      end

      def render
        return unless @visible
        return unless entity.args

        args = entity.args
        out = args.outputs[:ui]
        screen_w = args.grid.w
        screen_h = args.grid.h

        dw = 360
        dh = 180
        dx = (screen_w - dw) / 2
        dy = (screen_h - dh) / 2

        # Dark overlay
        out.solids << { x: 0, y: 0, w: screen_w, h: screen_h, r: 0, g: 0, b: 0, a: 140 }

        # Dialog background
        out.solids << { x: dx, y: dy, w: dw, h: dh, r: 30, g: 30, b: 50 }

        # Dialog border
        out.borders << { x: dx, y: dy, w: dw, h: dh, r: 100, g: 100, b: 150 }

        # Title
        out.labels << {
          x: dx + dw / 2, y: dy + dh - 24,
          text: @title,
          r: 255, g: 255, b: 255,
          size: 18, anchor_x: 0.5, anchor_y: 0.5
        }

        # Message
        out.labels << {
          x: dx + dw / 2, y: dy + dh / 2,
          text: @message,
          r: 200, g: 200, b: 200,
          size: 14, anchor_x: 0.5, anchor_y: 0.5
        }

        # Yes button
        btn_w = 100
        btn_h = 32
        yes_x = dx + dw / 2 - btn_w - 10
        btn_y = dy + 16
        no_x = dx + dw / 2 + 10

        # Yes button
        if @focused == :yes
          out.solids << { x: yes_x, y: btn_y, w: btn_w, h: btn_h, r: 74, g: 144, b: 217 }
        else
          out.solids << { x: yes_x, y: btn_y, w: btn_w, h: btn_h, r: 50, g: 50, b: 70 }
        end
        out.borders << { x: yes_x, y: btn_y, w: btn_w, h: btn_h, r: 100, g: 100, b: 150 }
        out.labels << {
          x: yes_x + btn_w / 2, y: btn_y + btn_h / 2,
          text: @yes_text,
          r: 255, g: 255, b: 255,
          size: 14, anchor_x: 0.5, anchor_y: 0.5
        }

        # No button
        if @focused == :no
          out.solids << { x: no_x, y: btn_y, w: btn_w, h: btn_h, r: 100, g: 50, b: 50 }
        else
          out.solids << { x: no_x, y: btn_y, w: btn_w, h: btn_h, r: 50, g: 50, b: 70 }
        end
        out.borders << { x: no_x, y: btn_y, w: btn_w, h: btn_h, r: 100, g: 100, b: 150 }
        out.labels << {
          x: no_x + btn_w / 2, y: btn_y + btn_h / 2,
          text: @no_text,
          r: 255, g: 255, b: 255,
          size: 14, anchor_x: 0.5, anchor_y: 0.5
        }
      end

      def do_yes
        cb = @on_yes
        hide!
        cb.call if cb
      end

      def do_no
        cb = @on_no
        hide!
        cb.call if cb
      end
    end
  end
end
