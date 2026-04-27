class ShowcaseEntity < Forge::Entity
  script Forge::Scripts::QuestManagerScript.new
  widget ShowcaseWidget.new
  widget Forge::Widgets::QuestTrackerWidget.new
  widget Forge::Widgets::QuestLogWidget.new
  widget Forge::Widgets::NotificationWidget.new
  widget Forge::Widgets::InventoryWidget.new
  widget Forge::Widgets::ShopWidget.new
  widget Forge::Widgets::ConfirmationWidget.new

  def initialize(**opts)
    super(**opts)
    self.visible = false  # No sprite to render -- purely a widget host
    define_sample_quests
    define_sample_inventory
    define_sample_shop
  end

  # No level loaded, skip world position and collision logic
  def update_world_pos; end

  def pre_update
    send_to_scripts(:args=, args)
    send_to_widgets(:args=, args)
    send_to_scripts(:pre_update)
    send_to_widgets(:pre_update)
  end

  private

  def define_sample_quests

    add_script Forge::Scripts::QuestScript.new(id: :exploration, name: "Exploration", index: 0)
    add_script Forge::Scripts::QuestScript.new(
      id: :find_treasure,
      name: "Find Sunken Treasure",
      parent_id: :exploration,
      score: 10, index: 0, tracking: true,
      rewards: [
        { name: "Gold", quantity: 100 },
        { name: "Diving Helmet", quantity: 1 },
      ]
    )
    add_script Forge::Scripts::QuestScript.new(id: :dive, name: "Dive into the water", parent_id: :find_treasure, index: 0)
    add_script Forge::Scripts::QuestScript.new(id: :open_chest, name: "Find the chest", parent_id: :find_treasure, index: 2)
    add_script Forge::Scripts::QuestScript.new(id: :surface, name: "Return to surface", parent_id: :find_treasure, index: 1)

    add_script Forge::Scripts::QuestScript.new(id: :hidden_items, name: "Hidden Items", parent_id: :exploration, index: 1)
    add_script Forge::Scripts::QuestScript.new(id: :feather_1, name: "Feather 1", description: "A white feather near the fountain", parent_id: :hidden_items, index: 0)
    add_script Forge::Scripts::QuestScript.new(id: :feather_2, name: "Feather 2", description: "A blue feather near the fountain", parent_id: :hidden_items, index: 1)
    add_script Forge::Scripts::QuestScript.new(id: :feather_3, name: "Feather 3", description: "A green feather near the fountain", parent_id: :hidden_items, index: 2)
    add_script Forge::Scripts::QuestScript.new(id: :feather_4, name: "Feather 4", description: "A yellow feather near the fountain", parent_id: :hidden_items, index: 3)

    add_script Forge::Scripts::QuestScript.new(id: :coins, name: "Ancient Coins", description: "Coins hidden in the ruins", parent_id: :hidden_items, index: 1)
    add_script Forge::Scripts::QuestScript.new(id: :coin_1, name: "Coin in the Well",   parent_id: :coins, score: 3, index: 0)
    add_script Forge::Scripts::QuestScript.new(id: :coin_2, name: "Coin in the Ruins",  parent_id: :coins, score: 3, index: 1)


    add_script Forge::Scripts::QuestScript.new(id: :map_caves, name: "Map the Caves", parent_id: :exploration, description: "Explore all cave entrances in the Northern Range.", score: 15, index: 2)
    add_script Forge::Scripts::QuestScript.new(id: :cave_a, name: "Find Cave A", parent_id: :map_caves)
    add_script Forge::Scripts::QuestScript.new(id: :cave_b, name: "Find Cave B", parent_id: :map_caves)
    add_script Forge::Scripts::QuestScript.new(id: :cave_c, name: "Find Cave C", parent_id: :map_caves)

    add_script Forge::Scripts::QuestScript.new(id: :climb_peak, name: "Reach the Summit", parent_id: :exploration, description: "Climb to the highest point on the map.", score: 20, index: 3, rewards: [{ name: "Mountaineer Badge", quantity: 1 }])
    add_script Forge::Scripts::QuestScript.new(id: :summit, name: "Reach the Summit", parent_id: :climb_peak, description: "Climb to the highest point on the map.")


    # =====================================================================
    # Root: Combat
    # =====================================================================
    add_script Forge::Scripts::QuestScript.new(id: :combat, name: "Combat", index: 1)
    add_script Forge::Scripts::QuestScript.new(id: :slay_slimes, name: "Slay 10 Slimes", parent_id: :combat, description: "The slime population is out of control. Thin them out.", score: 5, index: 0)
    add_script Forge::Scripts::QuestScript.new(id: :kill, name: "Kill Slimes", required: 10, parent_id: :slay_slimes)

    add_script Forge::Scripts::QuestScript.new(id: :defeat_boss, name: "Defeat the Golem", parent_id: :combat, description: "A stone golem guards the ancient ruins. Defeat it.", score: 25, index: 1, rewards: [
      { name: "Golem Heart", quantity: 1 },
      { name: "Gold", quantity: 500 },
    ])
    add_script Forge::Scripts::QuestScript.new(id: :defeat_golem, name: "Defeat the Stone Golem", parent_id: :defeat_boss, description: "Defeat the stone golem.", index: 0)

    # =====================================================================
    # Root: Crafting
    # =====================================================================

    add_script Forge::Scripts::QuestScript.new(id: :crafting, name: "Crafting", index: 2)
    add_script Forge::Scripts::QuestScript.new(id: :craft_sword, name: "Craft a Sword", parent_id: :crafting, description: "Gather materials and forge your first sword.", rewards: [
      { name: "Iron Sword", quantity: 1 }
    ])
    add_script Forge::Scripts::QuestScript.new(id: :ore, name: "Mine iron ore", required: 5, parent_id: :craft_sword)
    add_script Forge::Scripts::QuestScript.new(id: :wood, name: "Gather wood", required: 3, parent_id: :craft_sword)
    add_script Forge::Scripts::QuestScript.new(id: :forge, name: "Use the forge", parent_id: :craft_sword)

    add_script Forge::Scripts::QuestScript.new(id: :craft_armor, name: "Craft Armor", parent_id: :crafting, description: "Craft a set of iron armor.", rewards: [
      { name: "Iron Armor", quantity: 1 }
    ])
    add_script Forge::Scripts::QuestScript.new(id: :ore, name: "Mine iron ore", required: 10, parent_id: :craft_armor)
    add_script Forge::Scripts::QuestScript.new(id: :leather, name: "Gather leather", required: 5, parent_id: :craft_armor)
    add_script Forge::Scripts::QuestScript.new(id: :forge, name: "Use the forge", parent_id: :craft_armor)

    # Pre-progress some quests
    quest_manager_script.progress(:dive)
    quest_manager_script.progress(:kill, 3)
    quest_manager_script.progress(:ore, 2)
    quest_manager_script.progress(:find)  # complete one feather
  end

  def define_sample_inventory
    items = [
      { name: "Health Potion",  description: "Restores 50 HP",        quantity: 5   },
      { name: "Iron Sword",     description: "A sturdy blade",        quantity: 1   },
      { name: "Wooden Shield",  description: "Basic protection",      quantity: 1   },
      { name: "Iron Ore",       description: "Raw crafting material", quantity: 12  },
      { name: "Lumber",         description: "Processed wood planks", quantity: 8   },
      { name: "Gold Coin",      description: "Currency",              quantity: 347 },
      { name: "Slime Gel",      description: "Dropped by slimes",     quantity: 3   },
      { name: "Map Fragment",   description: "Part of a treasure map",quantity: 2   },
    ]

    inventory_widget.slots = items
    inventory_widget.size = 20
  end

  def define_sample_shop
    catalog = [
      { name: "Health Potion",   description: "Restores 50 HP",          buy_price: 25  },
      { name: "Mana Potion",     description: "Restores 30 MP",          buy_price: 30  },
      { name: "Iron Sword",      description: "A sturdy blade",          buy_price: 150 },
      { name: "Steel Shield",    description: "Strong protection",       buy_price: 200 },
      { name: "Leather Armor",   description: "Light but flexible",      buy_price: 120 },
      { name: "Fire Scroll",     description: "Casts Fireball",          buy_price: 75  },
      { name: "Antidote",        description: "Cures poison",            buy_price: 15  },
      { name: "Tent",            description: "Rest anywhere",           buy_price: 50  },
      { name: "Lockpick",        description: "Opens locked chests",     buy_price: 40  },
      { name: "Diamond Ring",    description: "Very shiny and expensive",buy_price: 999 },
    ]

    sell_inventory = [
      { name: "Health Potion",  description: "Restores 50 HP",        sell_price: 10, quantity: 5  },
      { name: "Iron Ore",       description: "Raw crafting material", sell_price: 5,  quantity: 12 },
      { name: "Lumber",         description: "Processed wood planks", sell_price: 3,  quantity: 8  },
      { name: "Slime Gel",      description: "Dropped by slimes",     sell_price: 8,  quantity: 3  },
      { name: "Map Fragment",   description: "Part of a treasure map",sell_price: 0,  quantity: 2  },
    ]

    shop_widget.catalog   = catalog
    shop_widget.inventory = sell_inventory
    shop_widget.gold      = 500
    shop_widget.shop_name = "General Store"
  end
end
