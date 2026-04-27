# frozen_string_literal: true

# GravityScript for DragonRuby Forge
# Applies constant downward acceleration to an entity.
# Attach to any entity that should fall.
#
# Usage:
#   entity.add_script(Forge::GravityScript.new(gravity: 0.03))
#
#   # Options:
#   #   gravity: downward acceleration per frame (default: 0.03)
#   #   max_fall_speed: terminal velocity (default: 1.0)
#
# Requires entity to have:
#   v_base: velocity object with dx, dy setters
#   on_ground?: method returning true when on ground
#   has_collision?(x, y): method checking collision at grid position
#   cx, cy: current grid cell position
#   yr: y ratio within cell

class GravityScript < Forge::Script
  def init
    @gravity = options[:gravity] || 0.03
    @max_fall_speed = options[:max_fall_speed] || 1.0
  end

  def update
    return if on_ground?

    # Apply gravity to vertical velocity
    if entity.v_base.respond_to?(:dy=)
      entity.v_base.dy += @gravity
      entity.v_base.dy = [@gravity, @max_fall_speed].min if entity.v_base.dy > @max_fall_speed
    end
  end

  def post_update
    return unless entity.v_base.respond_to?(:dy)
    return unless entity.v_base.dy > 0
    return unless entity.respond_to?(:yr) && entity.yr > 1
    return unless entity.respond_to?(:has_collision?) && entity.has_collision?(entity.cx, entity.cy + 1)

    # Landed on ground
    entity.v_base.dy = 0
    on_land
  end

  def on_land
    # Override in subclass for custom landing behavior
    # e.g., play landing animation, squash effect
  end

  private

  def on_ground?
    entity.respond_to?(:on_ground?) && entity.on_ground?
  end
end
