require_relative "game"

# Define entities inline for simplicity
class Player < Forge::Entity
  attr :name

  script Forge::Scripts::TopDownPlayerScript.new
  script Forge::Scripts::TopDownControlsScript.new
  script Forge::Scripts::HealthScript.new(health: 100)

  # Quest manager - collects all QuestScripts
  script Forge::Scripts::QuestManagerScript.new

  # Quests - each is a separate script
  script Forge::Scripts::QuestScript.new(
    id: :find_dog,
    name: "Find the Dog",
    description: "The elder's dog is lost in the forest",
    steps: [{ id: :find, name: "Find Fido" }],
    score: 10
  )

  def initialize(**opts)
    super
    @name = "Hero"
  end
end

class VillageElder < Forge::Entity
  attr :name

  # Dialogue manager - must be first!
  script Forge::Scripts::DialogueManagerScript.new

  # Dialogue nodes
  script Forge::Scripts::DialogueScript.new(
    id: :root,
    text: "Greetings, adventurer! Can you help me find my lost dog?",
    choices: [
      { text: "I'll find Fono!", next: :quest_active },
      { text: "I already found him!", next: :quest_complete, requires: "find_dog" },
      { text: "Sorry, busy.", next: nil }
    ]
  )

  script Forge::Scripts::DialogueScript.new(
    id: :quest_active,
    text: "Oh, thank you! He's somewhere in the forest. Please hurry!",
    choices: [
      { text: "On it!", next: nil }
    ]
  )

  script Forge::Scripts::DialogueScript.new(
    id: :quest_complete,
    text: "You found him! You're a hero! Here, take this reward."
  )

  # Widget to show dialogue
  widget Forge::Widgets::DialogueWidget.new

  # Prompt to interact
  script Forge::Scripts::PromptScript.new(prompt: "Talk")

  # Collision detection for player
  collidable

  def initialize(**opts)
    super
    @name = "Elder"
  end

  def on_interact(player)
    # Start dialogue
    dialogue_manager_script.start(:root)
  end
end

class Floor < Forge::Entity
  def initialize(**opts)
    super
    @visible = true
  end

  def post_update
    args.outputs.primitives << {
      x: x,
      y: y,
      w: 32,
      h: 32,
      r: 100,
      g: 100,
      b: 100,
      a: 255,
      path: :pixel
    }
  end
end

Forge.configure do |config|
  config.game_class = Game
end

def tick(args)
  Game.s.args = args
  Game.s.tick
end

def reset(args)
  # Initialize game
  Game.s.init
end
