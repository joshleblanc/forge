# frozen_string_literal: true

# LootLockerCurrencyGiftScript for DragonRuby Forge
# Collectible that awards currency to the player on contact.
# Attach to coins, gems, or treasure entities.
#
# Usage:
#   coin.add_script(Forge::LootLockerCurrencyGiftScript.new(
#     currency_id: :coins,
#     quantity: 10
#   ))
#
# Options:
#   currency_id: Symbol identifying the currency type
#   quantity:   Amount to award on collection

class LootLockerCurrencyGiftScript < Forge::Script
  def init
    @currency_id = options[:currency_id] || :coins
    @quantity = options[:quantity] || 1
    @awarded = false
  end

  def on_collision(player)
    return if @awarded
    @awarded = true

    player.send_to_scripts(:add_currency, @currency_id, @quantity) if player.respond_to?(:send_to_scripts)
  end
end
