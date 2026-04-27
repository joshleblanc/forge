# frozen_string_literal: true

# JumpScript for DragonRuby Forge
# Handles jumping with configurable power and multi-jump (double/triple jump).
# Attach to player entity alongside GravityScript.
#
# Usage:
#   entity.add_script(Forge::JumpScript.new(power: 0.4, jumps: 2))
#
#   # Options:
#   #   power:     jump velocity (default: 0.4)
#   #   jumps:     number of jumps (1 = single, 2 = double jump) (default: 1)
#   #   coyote_time: frames of grace period after leaving ground (default: 6)
#   #   jump_buffer: frames to buffer jump input (default: 6)
#
# Requires:
#   entity.v_base: velocity object with dx, dy setters
#   entity.on_ground?: boolean

class JumpScript < Forge::Script
  def init
    @power = options[:power] || 0.4
    @max_jumps = options[:jumps] || 1
    @jumps_remaining = @max_jumps
    @coyote_time = options[:coyote_time] || 6
    @jump_buffer = options[:jump_buffer] || 6
    @coyote_timer = 0
    @buffer_timer = 0
  end

  def update
    return unless entity.args && entity.v_base

    # Track coyote time
    if on_ground?
      @jumps_remaining = @max_jumps
      @coyote_timer = @coyote_time
    else
      @coyote_timer -= 1
    end

    # Buffer jump input
    if jump_pressed?
      @buffer_timer = @jump_buffer
    else
      @buffer_timer -= 1
    end

    # Execute buffered jump
    if @buffer_timer > 0 && can_jump?
      execute_jump
      @buffer_timer = 0
    end
  end

  # Check if entity can currently jump
  def can_jump?
    @coyote_timer > 0 || @jumps_remaining > 0
  end

  # Manually trigger a jump
  def jump
    execute_jump
  end

  private

  def execute_jump
    entity.v_base.dy = -@power

    if on_ground?
      @jumps_remaining = @max_jumps - 1
      @coyote_timer = 0
    else
      @jumps_remaining -= 1
    end

    on_jump
  end

  def on_jump
    # Override in subclass: play sound, animation, particles
  end

  def jump_pressed?
    return false unless entity.args

    kb = entity.args.inputs.keyboard
    kb.key_down.space || kb.key_down.enter || kb.key_down.w || kb.key_down.up
  end

  def on_ground?
    entity.respond_to?(:on_ground?) && entity.on_ground?
  end
end
