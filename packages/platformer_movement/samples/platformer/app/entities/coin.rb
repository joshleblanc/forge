class Coin < Forge::Entity 
    script Forge::Scripts::LdtkEntityScript.new
    #script Forge::Scripts::DebugRenderScript.new
    script Forge::Scripts::PickupScript.new(persistant: false)
    script Forge::Scripts::InventorySpecScript.new(
        icon: nil,
        name: "Coin"
    )
    script Forge::Scripts::AnimationScript.new(
        :coin,
        path: "samples/platformer/sprites/spritesheet-tiles-default.png",
        x: 15 * 64,
        y: 7 * 64,
        frames: 2,
        tile_w: 64,
        tile_h: 64,
        w: 64,
        h: 64,
        horizontal_frames: false
    )

    def init 
        send_to_scripts(:play_animation, :coin, true)
    end
end