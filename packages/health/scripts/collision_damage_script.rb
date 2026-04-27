# frozen_string_literal: true

# CollisionDamageScript for DragonRuby Forge
# Deals damage to any colliding entity that has a HealthScript.
# Attach to hazards, spikes, enemies, etc.
#
# Usage:
#   hazard.add_script(Forge::CollisionDamageScript, damage: 10, cooldown: 60)
#   # Any entity with HealthScript that collides will take 10 damage
#
# Options:
#   damage: Amount of damage per collision (default: 1)
#   cooldown: Frames between damage instances (default: 60)
#   death_knocks_back: Whether to apply extra knockback on kill (default: false)

class CollisionDamageScript < Forge::Script
  def init
    @damage = options[:damage] || 1
    @cooldown_frames = options[:cooldown] || 60
    @death_knockback = options[:death_knocks_back] || false
    @cooldown_timer = 0
  end

  def update
    @cooldown_timer -= 1 if @cooldown_timer > 0
  end

  def on_collision(other)
    return if @cooldown_timer > 0
    return unless other.respond_to?(:health_script) || other.respond_to?(:apply_damage)

    health = other.health_script || other

    if health.respond_to?(:apply_damage)
      health.apply_damage(@damage, entity)
      @cooldown_timer = @cooldown_frames
    elsif health.respond_to?(:damage)
      health.damage(@damage, entity)
      @cooldown_timer = @cooldown_frames
    end
  end
end
