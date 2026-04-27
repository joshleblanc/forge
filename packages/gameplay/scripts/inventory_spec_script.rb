# frozen_string_literal: true

# InventorySpecScript for DragonRuby Forge
# Defines item specifications for the inventory system.
# All specs are stored in a global registry.
#
# Usage:
#   Forge::InventorySpecScript.register(
#     name: "health_potion",
#     icon: "sprites/items/potion.png",
#     description: "Restores 50 health",
#     max_stack: 10,
#     sell_price: 25
#   )
#
#   Forge::InventorySpecScript.register(
#     name: "iron_sword",
#     icon: "sprites/items/sword.png",
#     description: "A sturdy iron blade",
#     max_stack: 1,
#     sell_price: 100
#   )
#
#   # Look up a spec:
#   spec = Forge::InventorySpecScript[:health_potion]

class InventorySpecScript < Forge::Script
  @registry = {}

  class << self
    # Global registry of all item specs
    attr_reader :registry

    # Register a new item spec
    # @param name: [String, Symbol] unique item name
    # @param icon: [String] sprite path
    # @param description: [String]
    # @param max_stack: [Integer] max stack size (default: 99)
    # @param sell_price: [Integer] gold value (default: 0)
    # @param buy_price: [Integer] cost to buy (default: sell_price * 2)
    # @param type: [Symbol] item category (default: :misc)
    def register(name:, icon: "", description: "", max_stack: 99,
                 sell_price: 0, buy_price: nil, type: :misc)
      @registry ||= {}
      @registry[name.to_sym] = {
        name: name.to_sym,
        icon: icon,
        description: description,
        max_stack: max_stack,
        sell_price: sell_price,
        buy_price: buy_price || (sell_price * 2),
        type: type
      }
    end

    # Look up a spec by name
    # @param name [String, Symbol]
    # @return [Hash, nil]
    def [](name)
      (@registry || {})[name.to_sym]
    end

    # Get all registered specs
    # @return [Hash]
    def all
      @registry || {}
    end

    # Clear the registry (useful for testing)
    def clear!
      @registry = {}
    end

    # Remove a spec
    # @param name [String, Symbol]
    def unregister(name)
      (@registry || {}).delete(name.to_sym)
    end
  end

  def init
    # No per-instance init needed for spec
  end
end
