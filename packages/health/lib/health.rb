# frozen_string_literal: true

# DragonRuby Forge - Health & Combat Package
# Health tracking, damage handling, collision damage, and collectibles.
#
# Usage:
#   Forge.add_package("health")
#
# Scripts:
#   HealthScript - Attach to any entity to give it health
#   CollisionDamageScript - Attach to hazards to damage entities on collision
#   PickupScript - Collectible items that trigger callbacks

module Forge
  module Scripts
    # Namespace for scripts
  end
end

require_relative "scripts/health_script"
require_relative "scripts/collision_damage_script"
require_relative "scripts/pickup_script"
