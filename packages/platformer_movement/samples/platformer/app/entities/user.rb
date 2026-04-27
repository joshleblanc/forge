class User < Forge::User 
    script CoinsScript.new
    widget CoinsWidget.new

    script Forge::Scripts::AudioScript.new(:coin_pickup, {
        files: [
            "samples/platformer/sounds/effects/handleCoins.ogg",
            "samples/platformer/sounds/effects/handleCoins2.ogg",
        ],
        overlap: true
    })

    script Forge::Scripts::NotificationsScript.new
end