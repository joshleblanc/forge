# frozen_string_literal: true

# Top-Down Movement Package for DragonRuby Forge
# 8-directional movement with WASD/arrow keys for top-down games.
#
# Usage:
#   Forge.add_package("top_down_movement")
#
#   entity.add_script(Forge::TopDownControlsScript.new(speed: 0.3))
#
# Requires:
#   entity.args: DragonRuby args (for input)
#   entity.v_base: velocity object with dx, dy setters
#   entity.dir: facing direction (1 or -1, optional)
#   entity.cd: cooldown system (optional, for controls_disabled)

require_relative "scripts/top_down_controls_script"
