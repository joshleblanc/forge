# Ultra Minimal Example - Just 3 lines to get a game running!
#
# This demonstrates Forge.quick_game for instant prototyping.
# No manual configuration needed.

require_relative '../../../hoard/hoard'

Forge.quick_game :grid_rpg, title: "My RPG"

def tick(args)
  Forge.config.game_class.s.args = args
  Forge.config.game_class.s.tick
end
