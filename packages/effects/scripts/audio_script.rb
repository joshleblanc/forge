# frozen_string_literal: true

# AudioScript for DragonRuby Forge
# Manages sound effect playback for entities.
#
# Usage:
#   entity.add_script(Forge::AudioScript.new(:jump,
#     files: ["audio/jump1.wav", "audio/jump2.wav"],
#     overlap: true  # allow multiple instances playing at once
#   ))
#
#   # Trigger playback from another script or event:
#   entity.send_to_scripts(:play_audio, :jump)

class AudioScript < Forge::Script
  attr_reader :name

  # Options:
  #   files:    Array of sound file paths (randomly selected on play)
  #   file:     Single sound file path (alternative to files)
  #   overlap:  Allow multiple simultaneous instances (default: false)
  #   volume:   Volume multiplier 0-1 (default: 1.0)

  def init
    opts = options.is_a?(Hash) ? options : {}
    @name = opts[:name] || opts[:id] || :sound
    @files = opts[:files] || ([opts[:file]] if opts[:file])
    @overlap = opts[:overlap] || false
    @volume = opts[:volume] || 1.0
  end

  # Handle play_audio message from other scripts
  def play_audio(sound_name)
    return unless sound_name == @name
    return if playing? unless @overlap

    play
  end

  # Play the sound effect
  def play
    return unless @files && !@files.empty?
    return unless entity && entity.args

    sound_path = @files.sample

    if @overlap
      entity.args.outputs.sounds << {
        input: sound_path,
        gain: @volume
      }
    else
      entity.args.audio[@name] = {
        input: sound_path,
        gain: @volume
      }
    end
  end

  # Stop the sound
  def stop
    return unless entity && entity.args
    entity.args.audio[@name] = nil unless @overlap
  end

  def playing?
    return false unless entity && entity.args
    !!entity.args.audio[@name]
  end
end
