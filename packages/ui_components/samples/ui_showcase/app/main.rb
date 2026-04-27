require_relative "game"
require_relative "widgets/showcase_widget"
require_relative "entities/showcase_entity"

Forge.configure do |config|
  config.game_class = Game
end

def tick(args)
  Game.s.args = args
  Game.s.tick
end

def reset(args)
  $forge_ui_theme = Forge::Ui::Theme.new
end
