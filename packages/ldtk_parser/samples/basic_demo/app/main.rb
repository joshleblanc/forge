# frozen_string_literal: true

# DragonRuby Forge - LDTK Parser Basic Demo
# This sample demonstrates loading and rendering an LDTK level.
#
# To run this demo:
#   1. Create a .ldtk file in data/levels/demo.ldtk
#   2. Place sprite assets in data/sprites/
#   3. Run: ./dragonruby .

# Load Forge and the LDTK parser
$LOAD_PATH.unshift(File.join(__dir__, "..", "..", "..", "lib"))
require "ldtk_parser"

def tick(args)
  # Initialize the game state on first frame
  if args.state.tick_count == 0
    init_game(args)
  end

  # Update game logic
  update_game(args)

  # Render the game
  render_game(args)
end

def init_game(args)
  args.state.player_x = 100
  args.state.player_y = 100
  args.state.player_speed = 4

  # Load the LDTK level if it exists
  ldtk_path = File.join(__dir__, "..", "..", "data", "levels", "demo.ldtk")
  if File.exist?(ldtk_path)
    args.state.ldtk_root = Forge::Ldtk.load(ldtk_path, grid_size: 16)
    args.state.current_level = args.state.ldtk_root.levels.first
    puts "Loaded LDTK: #{args.state.ldtk_root.json_version}"
    puts "Levels: #{args.state.ldtk_root.levels.map(&:identifier).join(", ")}"
  else
    puts "No LDTK file found at #{ldtk_path}"
    puts "Create a level in LDtk and save it to see it in action!"
    args.state.ldtk_root = nil
    args.state.current_level = nil
  end
end

def update_game(args)
  # Player movement
  if args.inputs.keyboard.key_held.left
    args.state.player_x -= args.state.player_speed
  end
  if args.inputs.keyboard.key_held.right
    args.state.player_x += args.state.player_speed
  end
  if args.inputs.keyboard.key_held.up
    args.state.player_y += args.state.player_speed
  end
  if args.inputs.keyboard.key_held.down
    args.state.player_y -= args.state.player_speed
  end

  # Level switching with number keys
  if args.state.ldtk_root
    1.upto(9) do |n|
      if args.inputs.keyboard.key_held.send("key_#{n}")
        idx = n - 1
        if args.state.ldtk_root.levels[idx]
          args.state.current_level = args.state.ldtk_root.levels[idx]
          puts "Switched to level: #{args.state.current_level.identifier}"
        end
      end
    end
  end
end

def render_game(args)
  # Clear the screen
  args.outputs.background_color = [20, 20, 30]

  # Draw the level (if loaded)
  if args.state.current_level
    render_level(args, args.state.current_level)
  else
    # Draw a simple grid when no LDTK file is present
    render_demo_grid(args)
  end

  # Draw the player
  args.outputs.sprites << {
    x: args.state.player_x,
    y: args.state.player_y,
    w: 16,
    h: 16,
    path: "data/sprites/player.png",
    r: 100, g: 200, b: 255
  }

  # Draw UI
  args.outputs.labels << {
    x: 10,
    y: args.grid.h - 10,
    text: "Arrow keys to move | 1-9 to switch levels",
    r: 200, g: 200, b: 200
  }

  if args.state.current_level
    args.outputs.labels << {
      x: 10,
      y: args.grid.h - 30,
      text: "Level: #{args.state.current_level.identifier} | #{args.state.current_level.px_wid}x#{args.state.current_level.px_hei}px",
      r: 200, g: 200, b: 200
    }
  end
end

def render_level(args, level)
  # Draw level background color
  bg_color = level.bg_color || [40, 40, 60]
  args.outputs.solids << {
    x: level.world_x,
    y: level.world_y,
    w: level.px_wid,
    h: level.px_hei,
    r: bg_color[0], g: bg_color[1], b: bg_color[2]
  }

  # Draw tiles from each layer
  level.layer_instances&.each do |layer|
    next unless layer.visible
    next if layer.tiles.empty?

    path = layer.tileset_rel_path&.gsub("../", "") || ""
    next if path.empty?

    layer.tiles.each do |tile|
      args.outputs.sprites << {
        x: level.world_x + tile.px[0],
        y: level.world_y + tile.px[1],
        w: layer.grid_size,
        h: layer.grid_size,
        path: path,
        source_x: tile.src[0],
        source_y: tile.src[1],
        source_w: layer.grid_size,
        source_h: layer.grid_size,
        flip_horizontally: tile.flip_h?,
        flip_vertically: tile.flip_v?,
        a: (255 * layer.opacity).to_i
      }
    end
  end

  # Draw entities
  entities_layer = level.layer("Entities")
  if entities_layer
    entities_layer.entity_instances.each do |entity|
      defn = entity.definition
      next unless defn

      # Draw entity as a colored rectangle
      color = defn.color || [255, 255, 0]
      args.outputs.solids << {
        x: level.world_x + entity.world_x,
        y: level.world_y + entity.world_y,
        w: entity.width || defn.width,
        h: entity.height || defn.height,
        r: color[0], g: color[1], b: color[2]
      }
    end
  end
end

def render_demo_grid(args)
  # Draw a simple demo grid when no LDTK file is present
  grid_size = 32
  grid_w = args.grid.w / grid_size
  grid_h = args.grid.h / grid_size

  0.upto(grid_w) do |x|
    args.outputs.lines << {
      x: x * grid_size,
      y: 0,
      x2: x * grid_size,
      y2: args.grid.h,
      r: 40, g: 40, b: 60
    }
  end

  0.upto(grid_h) do |y|
    args.outputs.lines << {
      x: 0,
      y: y * grid_size,
      x2: args.grid.w,
      y2: y * grid_size,
      r: 40, g: 40, b: 60
    }
  end
end
