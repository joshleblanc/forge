# frozen_string_literal: true

# DragonRuby Forge - Gameplay Package
# Core gameplay systems: save/load data, quests, inventory, and prompts.
#
# Usage:
#   Forge.add_package("gameplay")
#
# Scripts:
#   SaveDataScript       - Key-value persistence across game sessions
#   QuestScript          - Single quest with progress tracking
#   QuestManagerScript   - Manages all quests on an entity
#   InventorySpecScript  - Item registry for inventory
#   InventoryScript      - Grid inventory with stacking
#   PromptScript         - Timed in-game messages

require_relative "scripts/save_data_script"
require_relative "scripts/quest_script"
require_relative "scripts/quest_manager_script"
require_relative "scripts/inventory_spec_script"
require_relative "scripts/inventory_script"
require_relative "scripts/prompt_script"
