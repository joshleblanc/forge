# frozen_string_literal: true

# Platformer Movement Package for DragonRuby Forge
# Complete platformer movement with gravity, jumping, and ground detection.
#
# Usage:
#   Forge.add_package("platformer_movement")
#
#   # On your player entity:
#   entity.add_script(Forge::GravityScript.new(gravity: 0.03))
#   entity.add_script(Forge::JumpScript.new(power: 0.4, jumps: 2))
#   entity.add_script(Forge::PlatformerControlsScript.new(speed: 0.3))

require_relative "scripts/gravity_script"
require_relative "scripts/jump_script"
require_relative "scripts/platformer_controls_script"
