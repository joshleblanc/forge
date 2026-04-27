class Worm < Forge::Entity 
    script Forge::Scripts::LdtkEntityScript.new
    script Forge::Scripts::MoveToDestinationScript.new
    script Forge::Scripts::CollisionDamageScript.new
    script Forge::Scripts::AnimationScript.new(:worm, {
        files: [
            "samples/platformer/sprites/enemies/worm_ring_move_a.png",
            "samples/platformer/sprites/enemies/worm_ring_move_b.png",
        ],
    })

    def init 
        send_to_scripts(:play_animation, :worm, true)
    end
end