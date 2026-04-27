# frozen_string_literal: true

# PromptScript for DragonRuby Forge
# Timed or conditional in-game prompts that auto-dismiss.
# Useful for hints, tooltips, and contextual messages.
#
# Usage:
#   entity.add_script(Forge::PromptScript.new)
#
#   entity.prompt_script.show("Press SPACE to jump", duration: 3)
#   entity.prompt_script.show("New ability unlocked!", duration: 5, type: :success)
#
#   # Auto-dismiss after duration (in frames at 60fps)
#   entity.prompt_script.update  # call each frame

class PromptScript < Forge::Script
  # Prompt types and their default colors (RGB)
  PROMPT_STYLES = {
    info:    { r: 74,  g: 144, b: 217, bg: [20, 40, 70] },
    success: { r: 166, g: 212, b: 161, bg: [20, 60, 30] },
    warning: { r: 250, g: 200, b: 100, bg: [60, 40, 10] },
    error:   { r: 250, g: 100, b: 100, bg: [60, 20, 20] },
    neutral: { r: 200, g: 200, b: 200, bg: [30, 30, 50] }
  }

  def init
    @current_prompt = nil
    @timer = 0
    @fade_out = 0
    @fade_speed = 0.1
  end

  # Show a prompt message
  # @param message [String]
  # @param duration [Integer] frames to show (default: 120 = 2 sec at 60fps)
  # @param type [Symbol] :info, :success, :warning, :error, :neutral
  # @param x [Integer] screen x position (default: center)
  # @param y [Integer] screen y position (default: 1/4 from bottom)
  def show(message, duration: 120, type: :neutral, x: nil, y: nil)
    style = PROMPT_STYLES[type] || PROMPT_STYLES[:neutral]
    @current_prompt = {
      message: message,
      duration: duration,
      type: type,
      style: style,
      x: x,
      y: y,
      opacity: 0
    }
    @timer = 0
    @fade_out = 0
  end

  def update
    return unless @current_prompt

    @timer += 1
    prompt = @current_prompt

    # Fade in
    if prompt[:opacity] < 1.0 && @timer < 10
      prompt[:opacity] = [@timer / 10.0, 1.0].min
    end

    # Fade out
    if @timer >= prompt[:duration]
      @fade_out += @fade_speed
      prompt[:opacity] = [1.0 - @fade_out, 0].max

      if prompt[:opacity] <= 0
        @current_prompt = nil
        @fade_out = 0
      end
    end
  end

  def render
    return unless @current_prompt
    return unless entity&.args

    args = entity.args
    prompt = @current_prompt
    style = prompt[:style]
    alpha = (prompt[:opacity] * 255).to_i
    opacity_r = prompt[:opacity]

    screen_w = args.grid.w
    screen_h = args.grid.h

    # Position
    x = prompt[:x] || screen_w / 2
    y = prompt[:y] || screen_h / 4

    # Measure text (approximate)
    text = prompt[:message]
    char_w = 10
    w = [text.length * char_w + 24, 400].min
    h = 40
    bx = x - w / 2
    by = y - h / 2

    # Background
    bg = style[:bg]
    args.outputs[:ui].solids << {
      x: bx, y: by, w: w, h: h,
      r: bg[0], g: bg[1], b: bg[2], a: alpha
    }

    # Border
    args.outputs[:ui].borders << {
      x: bx, y: by, w: w, h: h,
      r: style[:r], g: style[:g], b: style[:b], a: alpha
    }

    # Text
    args.outputs[:ui].labels << {
      x: x, y: y,
      text: text,
      r: style[:r], g: style[:g], b: style[:b], a: alpha,
      size: 18,
      anchor_x: 0.5, anchor_y: 0.5
    }
  end

  def visible?
    !!@current_prompt
  end

  def dismiss
    @timer = @current_prompt[:duration] if @current_prompt
  end
end
