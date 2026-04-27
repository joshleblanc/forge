# frozen_string_literal: true

# TopDownControlsScript for DragonRuby Forge
# 8-directional movement with WASD / arrow keys for top-down games.
# Attach to player entity.
#
# Usage:
#   entity.add_script(Forge::TopDownControlsScript.new(speed: 0.3))
#
#   # Options:
#   #   speed: movement speed per frame (default: 0.3)
#   #   diagonal: allow diagonal movement (default: true)
#
# Requires entity to have:
#   args: DragonRuby args (for input)
#   v_base: velocity object with dx, dy setters
#   dir: facing direction (optional)
#   cd: cooldown system (optional)

class TopDownControlsScript < Forge::Script
  def init
    @speed = options[:speed] || 0.3
    @diagonal = options.fetch(:diagonal, true)
    @current_dx = 0
    @current_dy = 0
    @last_dir = :down
  end

  def update
    return unless entity.args && entity.v_base

    kb = entity.args.inputs.keyboard
    return if controls_disabled?

    @current_dx = 0
    @current_dy = 0

    # Read input
    left  = kb.key_held.left  || kb.key_held.a
    right = kb.key_held.right || kb.key_held.d
    up    = kb.key_held.up    || kb.key_held.w
    down  = kb.key_held.down  || kb.key_held.s

    if left
      @current_dx = -@speed
      @last_dir = :left
      entity.dir = -1 if entity.respond_to?(:dir=)
    end
    if right
      @current_dx = @speed
      @last_dir = :right
      entity.dir = 1 if entity.respond_to?(:dir=)
    end
    if up
      @current_dy = @speed
      @last_dir = :up
    end
    if down
      @current_dy = -@speed
      @last_dir = :down
    end

    # Normalize diagonal movement
    if @diagonal && @current_dx != 0 && @current_dy != 0
      factor = 1.0 / Math.sqrt(2)
      @current_dx *= factor
      @current_dy *= factor
    end

    # Apply velocity
    entity.v_base.dx = @current_dx
    entity.v_base.dy = @current_dy
  end

  def moving?
    @current_dx != 0 || @current_dy != 0
  end

  def direction
    @last_dir
  end

  private

  def controls_disabled?
    return false unless entity.respond_to?(:cd)
    return false unless entity.cd
    entity.cd.has("controls_disabled")
  end
end
