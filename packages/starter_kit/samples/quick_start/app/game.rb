# Quick Start Example - Minimal boilerplate for a top-down game
#
# This demonstrates the simplified setup. Just:
# 1. Define a Player class that extends Forge::Entity
# 2. Add scripts for behavior
# 3. Forge automatically finds and spawns the Player

class Game < Forge::Game
  GRID = 16
  SCALE = Scaler.best_fit_i(150, 150)
  
  def initialize
    super
    # Player is automatically found and spawned via find_player_entity
    # It looks for a class named "Player" and spawns it via user.spawn_player
  end
end

# Player entity - Forge auto-detects this by class name convention
class Player < Forge::Entity
  script Forge::Scripts::TopDownPlayerScript.new
  script Forge::Scripts::TopDownControlsScript.new
  script Forge::Scripts::DebugRenderScript.new  # Shows a green square
  
  attr_sprite
  
  def sprite_path
    nil  # No sprite - using DebugRenderScript instead
  end
end
