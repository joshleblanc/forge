# frozen_string_literal: true

# DragonRuby Forge - Utilities Package
# Small, focused utility scripts: labels, controls, dialogue, currency.
#
# Usage:
#   Forge.add_package("utilities")
#
# Scripts:
#   LabelScript               - Floating text above entity
#   DisableControlsScript     - Temporarily disable player input
#   DialogueScript            - Dialogue node with branching choices
#   LootLockerCurrencyGiftScript - Award currency on collision

require_relative "scripts/label_script"
require_relative "scripts/disable_controls_script"
require_relative "scripts/dialogue_script"
require_relative "scripts/loot_locker_currency_gift_script"
