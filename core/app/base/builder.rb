module Forge
  # Builder for creating games with minimal boilerplate
  #
  # Usage:
  #   game = Forge.game do |g|
  #     g.title "My Awesome Game"
  #     g.grid 32
  #     g.scale 2
  #     g.map "data/map.ldtk"
  #   end
  #
  #   game.run
  class GameBuilder
    attr_accessor :title, :grid, :scale, :map_path, :user_name, :player_class
    
    def initialize
      @title = "Forge Game"
      @grid = 16
      @scale = 1
      @map_path = "data/map.ldtk"
      @user_name = "Player"
      @player_class = nil
      @custom_game_class = nil
      @entities = []
      @widgets = []
      @scripts = []
    end
    
    def name(title)
      @title = title
      self
    end
    alias_method :title, :name
    
    def grid_size(size)
      @grid = size
      self
    end
    alias_method :grid, :grid_size
    
    def scale_factor(factor)
      @scale = factor
      self
    end
    alias_method :scale, :scale_factor
    
    def with_map(path)
      @map_path = path
      self
    end
    alias_method :map, :with_map
    
    def with_user(name)
      @user_name = name
      self
    end
    alias_method :user, :with_user
    
    # Define a player entity class
    # Usage: player { |p| p.script Forge::Scripts::TopDownPlayerScript.new }
    def player(&block)
      @player_class = Class.new(Entity) do
        class_eval(&block) if block
      end
      self
    end
    
    # Register an entity type
    def entity(id, &block)
      @entities << [id, block]
      self
    end
    
    # Register a widget
    def widget(klass_or_instance, &block)
      if klass_or_instance.is_a?(Class)
        @widgets << [klass_or_instance, block]
      else
        @widgets << [klass_or_instance.class, block]
      end
      self
    end
    
    # Register a script for the player
    def script(script_instance)
      @scripts << script_instance
      self
    end
    
    # Build the game class and user class
    def build
      player_class = @player_class || create_default_player
      
      game_class = Class.new(Forge::Game) do
        const_set(:GRID, @grid)
        const_set(:SCALE, Scaler.best_fit_i(@scale * 100, @scale * 100))
        
        define_method(:map_path) { @map_path }
        
        define_method(:user) do
          @user ||= begin
            u = User.new(@user_name)
            u.spawn_player(player_class)
            @scripts.each { |s| u.player.add_script(s) } if u.player
            u
          end
        end
      end
      
      Forge.configure { |c| c.game_class = game_class }
      
      # Register entities
      @entities.each do |id, block|
        entity_class = Class.new(Entity) do
          class_eval(&block) if block
        end
        Forge::Entity.define_singleton_method(:"resolve_#{id.to_s.gsub('::', '_')}") { entity_class }
      end
      
      game_class
    end
    
    private
    
    def create_default_player
      Class.new(Entity) do
        w 16
        h 16
      end
    end
  end
  
  class << self
    # Create a game using the builder pattern
    #
    # Usage:
    #   Forge.game do |g|
    #     g.title "My Game"
    #     g.grid 32
    #     g.player { |p| p.script Forge::Scripts::TopDownPlayerScript.new }
    #   end
    def game(&block)
      builder = GameBuilder.new
      builder.instance_eval(&block) if block
      builder.build
    end
    
    # Quick game for prototyping - creates a complete playable game in one call
    #
    # Usage:
    #   Forge.quick_game :top_down, title: "My Game", map: "data/map.ldtk"
    #   Forge.quick_game :platformer, map: "platformer/data/map.ldtk"
    #   Forge.quick_game :empty, title: "Blank Game"
    #   Forge.quick_game :shooter, title: "Space Shooter"
    #   Forge.quick_game :grid_rpg, title: "Grid RPG"
    def quick_game(type = :empty, **opts, &block)
      case type
      when :top_down
        create_top_down_game(**opts, &block)
      when :platformer
        create_platformer_game(**opts, &block)
      when :shooter
        create_shooter_game(**opts, &block)
      when :grid_rpg
        create_grid_rpg_game(**opts, &block)
      when :empty, nil
        create_empty_game(**opts, &block)
      else
        raise ArgumentError, "Unknown game type: #{type}. Use :top_down, :platformer, :shooter, :grid_rpg, or :empty"
      end
    end
    
    # Define a player entity that will be auto-detected
    def register_player(klass)
      @registered_player_class = klass
    end
    
    def player_class
      @registered_player_class
    end
    
    private
    
    def create_top_down_game(title: "Top Down Game", map: "data/map.ldtk", grid: 16, **)
      game do |g|
        g.title title
        g.grid grid
        g.map map
        g.player do |p|
          p.script Forge::Scripts::TopDownPlayerScript.new
          p.script Forge::Scripts::TopDownControlsScript.new
          p.collidable
        end
      end
    end
    
    def create_platformer_game(title: "Platformer Game", map: "data/map.ldtk", grid: 32, **)
      game do |g|
        g.title title
        g.grid grid
        g.map map
        g.player do |p|
          p.script Forge::Scripts::PlatformerPlayerScript.new
          p.script Forge::Scripts::PlatformerControlsScript.new
          p.script Forge::Scripts::JumpScript.new
          p.script Forge::Scripts::GravityScript.new
          p.collidable
        end
      end
    end
    
    def create_empty_game(title: "Empty Game", **)
      game do |g|
        g.title title
        g.map nil
      end
    end

    def create_shooter_game(title: "Space Shooter", map: "data/map.ldtk", grid: 16, **)
      game do |g|
        g.title title
        g.grid grid
        g.map map
        g.player do |p|
          p.script Forge::Scripts::TopDownPlayerScript.new
          p.script Forge::Scripts::TopDownControlsScript.new
          p.script Forge::Scripts::AnimationScript.new
          p.collidable
        end
      end
    end

    def create_grid_rpg_game(title: "Grid RPG", **)
      game do |g|
        g.title title
        g.grid 16
        g.map nil
        g.player do |p|
          p.script Forge::Scripts::HealthScript.new(max_hp: 100)
          p.script Forge::Scripts::InventoryScript.new(20)
          p.collidable
        end
      end
    end
  end
end
