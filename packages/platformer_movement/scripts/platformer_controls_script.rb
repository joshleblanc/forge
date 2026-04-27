# frozen_string_literal: true

# PlatformerControlsScript for DragonRuby Forge
# Arrow key / WASD movement for platformer games.
# Attach to player entity.
#
# Usage:
#   entity.add_script(Forge::PlatformerControlsScript.new(speed: 0.3))
#
#   # Options:
#   #   speed:         horizontal movement speed (default: 0.3)
#   #   acceleration:  how quickly to reach max speed (default: 1.0)
#   #   friction:      deceleration when no key pressed (default: 0.85)
#   #   air_friction: deceleration in air (default: 0.95)
#
# Requires:
#   entity.v_base: velocity object with dx, dy setters
#   entity.dir: current facing direction (1 or -1)

class PlatformerControlsScript < Forge::Script
  def init
    @speed = options[:speed] || 0.3
    @acceleration = options[:acceleration] || 1.0
    @friction = options[:friction] || 0.85
    @air_friction = options[:air_friction] || 0.95
    @current_dx = 0
  end

  def update
    return unless entity.args && entity.v_base

    kb = entity.args.inputs.keyboard

    left = kb.key_held.left || kb.key_held.a
    right = kb.key_held.right || kb.key_held.d

    if left && !right
      move_left
    elsif right && !left
      move_right
    else
      decelerate
    end
  end

  def move_left
    @current_dx = -@speed
    entity.v_base.dx = @current_dx
    entity.dir = -1 if entity.respond_to?(:dir=)
  end

  def move_right
    @current_dx = @speed
    entity.v_base.dx = @current_dx
    entity.dir = 1 if entity.respond_to?(:dir=)
  end

  def decelerate
    friction = on_ground? ? @friction : @air_friction
    @current_dx *= friction
    entity.v_base.dx = @current_dx

    if @current_dx.abs < 0.01
      @current_dx = 0
      entity.v_base.dx = 0
    end
  end

  private

  def on_ground?
    entity.respond_to?(:on_ground?) && entity.on_ground?
  end
end
