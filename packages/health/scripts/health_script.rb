# frozen_string_literal: true

# HealthScript for DragonRuby Forge
# Attach to any entity to give it health, damage handling, and death.
#
# Usage:
#   entity.add_script(Forge::HealthScript, health: 100)
#
#   # Deal damage to this entity
#   entity.health_script.apply_damage(25, source_entity)
#
#   # Check state
#   entity.health_script.alive?   # => true/false
#   entity.health_script.dead?     # => true/false
#   entity.health_script.life_v   # current health
#   entity.health_script.life_max # max health
#
#   # Handle death (override in subclass or hook via entity):
#   entity.on_die { |e| puts "#{e} died!" }

class HealthScript < Forge::Script
  attr :life, :last_dmg_source, :max_health

  # Options:
  #   health: Maximum health (default: 100)
  #   bounce: Whether to bounce when hit (default: true)
  #   invincibility_frames: Frames of invincibility after damage (default: 60)
  def init
    @max_health = options[:health] || 100
    @bounce = options.fetch(:bounce, true)
    @invincibility_frames = options[:invincibility_frames] || 60
    @life = @max_health
    @last_dmg_source = nil
    @flash_timer = 0
    @visible = true
  end

  # Deal damage to this entity
  # @param amount [Numeric] damage amount
  # @param source [Object] the entity dealing the damage
  def apply_damage(amount, source = nil)
    return if amount <= 0
    return if dead?
    return if invincible?

    @last_dmg_source = source

    # Apply invincibility
    entity.cd.set_s("invulnerability", @invincibility_frames) if entity.cd

    # Flash effect
    start_flash

    # Bounce back from source
    bounce_from(source) if @bounce && source

    @life -= amount
    @life = 0 if @life < 0

    on_after_damage(amount, source)

    if dead?
      on_die(source)
    end
  end

  # Alias for apply_damage
  def damage(amount, source = nil)
    apply_damage(amount, source)
  end

  # Heal this entity
  # @param amount [Numeric] healing amount
  def heal(amount)
    return if dead?
    @life += amount
    @life = [@life, @max_health].min
  end

  # Restore to full health
  def full_heal
    @life = @max_health
  end

  # Check if alive
  def alive?
    @life > 0
  end

  # Check if dead
  def dead?
    @life <= 0
  end

  # Check if currently invincible
  def invincible?
    return false unless entity.cd
    entity.cd.has("invulnerability")
  end

  # Get current health
  def life_v
    @life
  end

  # Alias for current health
  def health
    @life
  end

  # Get max health
  def life_max
    @max_health
  end

  # Get max health alias
  def max_health
    @max_health
  end

  # Get health as percentage (0-1)
  def health_percent
    @max_health > 0 ? (@life.to_f / @max_health) : 0
  end

  def update
    # Handle flash effect
    if @flash_timer > 0
      @flash_timer -= 1
      entity.visible = (@flash_timer % 8) < 4
    else
      entity.visible = true if entity.respond_to?(:visible=)
    end
  end

  # Called after damage is applied but before death check
  # Override in subclass for custom behavior
  def on_after_damage(amount, source)
    # Override me
  end

  # Called when health reaches 0
  # Override in subclass for custom behavior
  def on_die(source = nil)
    # Override me
  end

  private

  def start_flash
    @flash_timer = @invincibility_frames
  end

  def bounce_from(source)
    return unless source.respond_to?(:x) && source.respond_to?(:y)
    return unless entity.respond_to?(:v_base)

    dx = entity.x - source.x
    dy = entity.y - source.y
    dist = Math.sqrt(dx * dx + dy * dy)
    return if dist == 0

    # Normalize and apply bounce force
    nx = dx / dist
    ny = dy / dist

    entity.v_base.x = nx * 0.5 if entity.v_base.respond_to?(:x=)
    entity.v_base.y = ny * 0.3 if entity.v_base.respond_to?(:y=)
  end
end
