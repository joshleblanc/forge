# frozen_string_literal: true

# InventoryScript for DragonRuby Forge
# Grid-based inventory management with stacking and save/load.
# Attach to player entity.
#
# Usage:
#   entity.add_script(Forge::InventoryScript.new(size: 20))
#
#   # Add items
#   spec = Forge::InventorySpecScript[:health_potion]
#   entity.inventory_script.add(spec, quantity: 5)
#
#   # Check items
#   entity.inventory_script.has?(:health_potion)  # => true
#   entity.inventory_script.count(:health_potion)  # => 5
#
#   # Remove items
#   entity.inventory_script.remove(:health_potion, quantity: 2)
#
#   # Query
#   entity.inventory_script.full?      # is inventory full?
#   entity.inventory_script.slots      # all items
#   entity.inventory_script.empty?     # no items?

class InventoryScript < Forge::Script
  # Options:
  #   size: Number of inventory slots (default: 20)
  def init
    @size = options[:size] || 20
    @slots = []  # Array of { name:, quantity:, spec: }

    # Load saved inventory
    load!
  end

  # Add an item to inventory
  # @param spec [Hash] item spec (from InventorySpecScript)
  # @param quantity [Integer] how many to add
  # @return [Boolean] true if added successfully
  def add(spec, quantity: 1)
    name = spec[:name].to_sym

    # Try to stack with existing item
    existing = @slots.find { |s| s[:name] == name }
    max_stack = spec[:max_stack] || 99

    if existing
      added = [quantity, max_stack - existing[:quantity]].max(0)
      existing[:quantity] += added
      return added > 0
    end

    # Add to new slot if there's room
    if @slots.length < @size
      @slots << { name: name, quantity: quantity, spec: spec }
      save!
      return true
    end

    false  # inventory full
  end

  # Remove items from inventory
  # @param name [Symbol, String] item name
  # @param quantity [Integer] how many to remove
  # @return [Boolean] true if removed
  def remove(name, quantity: 1)
    name = name.to_sym
    slot = @slots.find { |s| s[:name] == name }
    return false unless slot

    if quantity >= slot[:quantity]
      @slots.delete(slot)
    else
      slot[:quantity] -= quantity
    end

    save!
    true
  end

  # Check if player has enough of an item
  # @param name [Symbol, String]
  # @param quantity [Integer]
  # @return [Boolean]
  def has?(name, quantity: 1)
    count(name) >= quantity
  end

  # Count how many of an item
  # @param name [Symbol, String]
  # @return [Integer]
  def count(name)
    name = name.to_sym
    @slots.find { |s| s[:name] == name }&.dig(:quantity) || 0
  end

  # Get a slot by name
  # @param name [Symbol, String]
  # @return [Hash, nil]
  def find(name)
    name = name.to_sym
    @slots.find { |s| s[:name] == name }
  end

  # Check if inventory is full
  def full?
    @slots.length >= @size
  end

  # Check if inventory is empty
  def empty?
    @slots.empty?
  end

  # Get all slots
  def slots
    @slots.dup
  end

  # Get the number of free slots
  def free_slots
    @size - @slots.length
  end

  # Get total item count
  def total_items
    @slots.sum { |s| s[:quantity] }
  end

  # Clear all items
  def clear
    @slots.clear
    save!
  end

  # Load inventory from save
  def load!
    save_data = nil
    if entity&.respond_to?(:save_data_script)
      save_data = entity.save_data_script.get(:inventory)
    end

    @slots = []
    return unless save_data.is_a?(Array)

    save_data.each do |item|
      name = item[:name].to_sym
      spec = InventorySpecScript[name] || { name: name, max_stack: 99 }
      @slots << {
        name: name,
        quantity: item[:quantity] || 1,
        spec: spec
      }
    end
  end

  # Save inventory to save data
  def save!
    return unless entity&.respond_to?(:save_data_script)

    serialized = @slots.map do |s|
      { name: s[:name].to_s, quantity: s[:quantity] }
    end

    entity.save_data_script.set(:inventory, serialized)
  end

  # Serialize for custom save systems
  def serialize
    @slots.map do |s|
      { name: s[:name].to_s, quantity: s[:quantity] }
    end
  end

  # Deserialize from custom save data
  # @param data [Array<Hash>]
  def deserialize(data)
    return unless data.is_a?(Array)
    @slots = data.map do |item|
      name = item[:name].to_sym
      spec = InventorySpecScript[name] || { name: name, max_stack: 99 }
      { name: name, quantity: item[:quantity] || 1, spec: spec }
    end
  end
end
