# frozen_string_literal: true

# PickupScript for DragonRuby Forge
# Collectible items that disappear when touched and trigger a callback.
# Can be used for coins, powerups, health packs, etc.
#
# Usage:
#   coin.add_script(Forge::PickupScript,
#     quantity: 10,
#     persist: true,
#     on_collect: ->(player) { player.add_coins(10) }
#   )
#
# Options:
#   quantity: How many to collect (default: 1)
#   persist: Whether pickup stays gone after collecting (default: true)
#   collect_sound: Sound effect name to play (optional)
#   collect_animation: Animation name to play (optional)
#   on_collect: Proc called when collected (takes player as argument)

class PickupScript < Forge::Script
  def init
    @quantity = options[:quantity] || 1
    @persist = options.fetch(:persist, true)
    @collected = false
    @bob_timer = 0
    @original_y = entity.y if entity.respond_to?(:y)
  end

  def update
    return if @collected

    # Simple floating animation
    @bob_timer += 0.05
    if entity.respond_to?(:y) && @original_y
      entity.y = @original_y + Math.sin(@bob_timer) * 2
    end

    # Rotation animation
    if entity.respond_to?(:angle)
      entity.angle = (@bob_timer * 30) % 360
    end
  end

  def on_collision(player)
    return if @collected

    # Call the collect callback
    if options[:on_collect].is_a?(Proc)
      options[:on_collect].call(player)
    end

    # Send collection message to player
    player.send_to_scripts(:on_collect_pickup, entity, @quantity) if player.respond_to?(:send_to_scripts)

    on_collected(player)

    if @persist
      collect!
    else
      destroy!
    end
  end

  # Override to add custom behavior on collection
  def on_collected(player)
    # Example: play sound
    # player.send_to_scripts(:play_audio, options[:collect_sound]) if options[:collect_sound]

    # Example: play animation
    # player.send_to_scripts(:play_animation, options[:collect_animation]) if options[:collect_animation]
  end

  # Mark as collected (hide) without destroying
  def collect!
    @collected = true
    entity.visible = false if entity.respond_to?(:visible=)
    entity.destroyed = true if entity.respond_to?(:destroyed=)
  end

  # Destroy the entity entirely
  def destroy!
    entity.destroyed = true if entity.respond_to?(:destroyed=)
    entity.visible = false if entity.respond_to?(:visible=)
  end

  # Reset the pickup (make visible again)
  def reset!
    @collected = false
    entity.visible = true if entity.respond_to?(:visible=)
    entity.destroyed = false if entity.respond_to?(:destroyed=)
  end

  def collected?
    @collected
  end

  def quantity
    @quantity
  end
end
