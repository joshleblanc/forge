# frozen_string_literal: true

# SaveDataScript for DragonRuby Forge
# Key-value data persistence that survives across game sessions.
# Uses DragonRuby's GTK persistence layer.
#
# Usage:
#   entity.add_script(Forge::SaveDataScript.new)
#
#   # Save data
#   entity.save_data_script.set(:coins, 150)
#   entity.save_data_script.set(:level, 3)
#   entity.save_data_script.set(:inventory, [{ name: "sword", qty: 1 }])
#
#   # Load data
#   entity.save_data_script.get(:coins)  # => 150
#   entity.save_data_script.get(:level)  # => 3
#
#   # Check existence
#   entity.save_data_script.has?(:coins)  # => true
#
#   # Delete
#   entity.save_data_script.delete(:coins)
#
#   # Clear all
#   entity.save_data_script.clear

class SaveDataScript < Forge::Script
  SAVE_KEY = :forge_save_data
  DEFAULT_FILE = "savegame.json"

  def init
    @data = {}
    @filename = options[:file] || options[:filename] || DEFAULT_FILE
    load!
  end

  # Get a saved value
  # @param key [Symbol, String]
  # @return [Object] saved value or nil
  def get(key)
    @data[key.to_sym]
  end

  # Alias for get
  def [](key)
    get(key)
  end

  # Set a saved value
  # @param key [Symbol, String]
  # @param value [Object]
  def set(key, value)
    @data[key.to_sym] = value
    save!
  end

  # Alias for set
  def []=(key, value)
    set(key, value)
  end

  # Check if a key exists
  # @param key [Symbol, String]
  # @return [Boolean]
  def has?(key)
    @data.key?(key.to_sym)
  end

  # Delete a key
  # @param key [Symbol, String]
  def delete(key)
    @data.delete(key.to_sym)
    save!
  end

  # Clear all saved data
  def clear
    @data = {}
    save!
  end

  # Get all saved data as a hash
  def all
    @data.dup
  end

  # Merge multiple values at once
  # @param hash [Hash]
  def merge(hash)
    @data.merge!(hash.stringify_keys)
    save!
  end

  # Initialize from save data (load on init)
  def load!
    return unless entity&.args

    serialized = entity.args.gtk.serialize_state(SAVE_KEY)
    if serialized
      begin
        @data = JSON.parse(serialized, symbolize_names: true)
      rescue JSON::ParserError
        @data = {}
      end
    else
      @data = {}
    end
  end

  # Save data to persistence layer
  def save!
    return unless entity&.args

    json = JSON.generate(@data)
    entity.args.gtk.deserialize_state(SAVE_KEY, json)
  end

  # Reset to empty state (without clearing save)
  def reset!
    @data = {}
  end

  def data
    @data
  end
end
