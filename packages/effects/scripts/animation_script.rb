# frozen_string_literal: true

# AnimationScript for DragonRuby Forge
# Handles sprite sheet animations for entities.
#
# Usage:
#   entity.add_script(Forge::AnimationScript.new(:idle,
#     path: "sprites/player.png",
#     x: 0, y: 0,
#     tile_w: 32, tile_h: 32,
#     horizontal_frames: true,
#     frames: 4,
#     speed: 1
#   ))
#
#   # Play animation
#   entity.send_to_scripts(:play_animation, :idle, loop: true)
#
#   # Check state
#   entity.animation_scripts.each do |s|
#     puts s.done? if s.id == :idle
#   end

class AnimationScript < Forge::Script
  attr_reader :id, :loop, :playing

  # Options:
  #   path:        Sprite sheet path (for tiled sprites)
  #   files:       Array of individual sprite paths (alternative to path)
  #   x, y:        Top-left corner of first frame in sprite sheet
  #   tile_w:      Width of each frame (default: entity.tile_w or 16)
  #   tile_h:      Height of each frame (default: entity.tile_h or 16)
  #   w, h:        Render size (default: tile_w, tile_h)
  #   horizontal_frames: Frames go left-to-right (default: true)
  #   frames:      Number of frames in the animation
  #   speed:       Playback speed multiplier (default: 1)
  #   overlap:     Allow overlapping playback (default: false)
  #   offset_x:    Render offset X (default: 0)
  #   offset_y:    Render offset Y (default: 0)
  #   reverse:     Play in reverse (default: false)

  def init
    @id = options[:id] || options[:name] || :animation
    opts = options.is_a?(Hash) ? options : {}

    @opts = opts
    @playing = false
    @loop = false
    @frame = 0
    @offset_x = opts[:offset_x] || 0
    @offset_y = opts[:offset_y] || 0
    @horizontal_frames = opts.fetch(:horizontal_frames, true)
    @overlap = opts[:overlap] || false
    @reverse = opts[:reverse] || false
    @callback = nil
  end

  # Start playing this animation
  # @param should_loop [Boolean]
  def play(should_loop = false, &callback)
    @frame = @reverse ? frame_length : 0
    @playing = true
    @loop = should_loop
    @callback = callback
  end

  # Handle play_animation message from other scripts
  def play_animation(anim_id, should_loop = false, &callback)
    return unless anim_id == @id

    if @overlap
      @playing = true
    else
      @playing = (anim_id == @id)
    end

    return unless @playing

    @loop = should_loop
    @callback = callback
    @frame = @reverse ? frame_length : 0
  end

  def update
    return unless @playing

    # Advance frame
    @frame += (@reverse ? -1 : 1)

    # Check if done
    if done?
      @playing = false
      @callback.call if @callback
    end
  end

  def render
    return unless @playing
    return unless entity.visible? if entity.respond_to?(:visible?)

    # Calculate render position
    render_x = entity_x + @offset_x
    render_y = entity_y + @offset_y

    sprite_opts = {
      x: render_x,
      y: render_y,
      w: render_w,
      h: render_h,
      tile_x: tile_x,
      tile_y: tile_y,
      tile_w: tile_w,
      tile_h: tile_h,
      path: sprite_path,
      flip_horizontally: (entity.flip_horizontally? rescue false),
      flip_vertically: (entity.flip_vertically? rescue false)
    }

    entity.args.outputs[:scene].sprites << sprite_opts if entity.args
  end

  # Is the animation currently playing?
  def playing?
    @playing == true
  end

  # Has the animation finished?
  def done?
    return false if @loop
    return false if @frame <= 0 && @reverse
    return false if @frame >= frame_length && !@reverse
    @frame >= frame_length
  end

  def loop?
    @loop == true
  end

  def frame_count
    @opts[:frames] || (files ? files.length : 1)
  end

  def files
    @opts[:files]
  end

  def speed
    @opts[:speed] || 1
  end

  def speed_ratio
    10.0 / speed
  end

  def current_frame
    frame_ratio = (@frame / speed_ratio)
    (frame_ratio % frame_count).abs.to_i
  end

  def frame_length
    ((frame_count - 1) * speed_ratio) + speed_ratio
  end

  def tile_x
    if files
      0
    elsif @horizontal_frames
      (@opts[:x] || 0) + (tile_w * current_frame)
    else
      @opts[:x] || 0
    end
  end

  def tile_y
    if files
      0
    elsif @horizontal_frames
      @opts[:y] || 0
    else
      (@opts[:y] || 0) + (tile_h * current_frame)
    end
  end

  def tile_w
    @opts[:tile_w] || (entity.tile_w if entity.respond_to?(:tile_w)) || 16
  end

  def tile_h
    @opts[:tile_h] || (entity.tile_h if entity.respond_to?(:tile_h)) || 16
  end

  def render_w
    @opts[:w] || tile_w
  end

  def render_h
    @opts[:h] || tile_h
  end

  def sprite_path
    files ? files[current_frame] : @opts[:path]
  end

  private

  def entity_x
    return 0 unless entity
    entity.x || 0
  end

  def entity_y
    return 0 unless entity
    entity.y || 0
  end
end
