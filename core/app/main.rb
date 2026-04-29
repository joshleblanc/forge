# DragonRuby entry point
# https://forge.game
#
# This is your game's main.rb — the entry point DragonRuby runs.
#
# Usage:
#
#   # Basic: create an entity and run the loop
#   require "forge/packages"
#
#   class Player < Forge::Entity
#   end
#
#   def tick(args)
#     Forge.tick(args)
#   end
#
#   # Advanced: configure Forge, add packages
#   require "forge/packages"
#
#   Forge.configure do |config|
#     config.game_class = MyGame
#   end
#
#   class MyGame < Forge::Entity
#   end
#
#   def tick(args)
#     Forge.tick(args)
#   end
#
# Quick package commands (run in DragonRuby console):
#
#   Forge.add_package("health-system")
#   Forge.remove_package("health-system")
#   Forge.update_packages
#   Forge.list_installed
#   Forge.search_packages("health")
#
# Publishing (requires registered account — anonymous keys cannot publish):
#
#   Forge.publish_package(
#     name: "my-script",
#     version: "1.0.0",
#     description: "Does a cool thing",
#     scripts: ["MyScript"],
#     tags: ["gameplay"]
#   )

# Load Forge base + package manager + all installed packages
require "forge/packages"

# Initialize Forge
Forge.configure do |config|
  # Set your game class here:
  # config.game_class = MyGame
end

# DragonRuby tick — called every frame
def tick(args)
  Forge.tick(args)
end
