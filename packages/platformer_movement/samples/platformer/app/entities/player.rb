class Player < Forge::Entity 
    script Forge::Scripts::PlatformerPlayerScript.new(
        health: 6
    )

    script Forge::Scripts::AnimationScript.new(:idle, {
        files: [
            "samples/platformer/sprites/character/character_beige_idle.png"
        ]
    })

    script Forge::Scripts::AnimationScript.new(:standing_jump, {
        files: [
            "samples/platformer/sprites/character/character_beige_jump.png"
        ]
    })

    script Forge::Scripts::AnimationScript.new(:moving_jump, {
        files: [
            "samples/platformer/sprites/character/character_beige_jump.png"
        ]
    })

    script Forge::Scripts::AnimationScript.new(:walk, {
        files: [
            "samples/platformer/sprites/character/character_beige_walk_a.png",
            "samples/platformer/sprites/character/character_beige_walk_b.png"
        ]
    })

    script Forge::Scripts::AnimationScript.new(:climb, {
        files: [
            "samples/platformer/sprites/character/character_beige_climb_a.png",
            "samples/platformer/sprites/character/character_beige_climb_b.png"
        ]
    })

    script Forge::Scripts::AudioScript.new(:footsteps, {
        files: [
            "samples/platformer/sounds/effects/footstep00.ogg",
            "samples/platformer/sounds/effects/footstep01.ogg",
            "samples/platformer/sounds/effects/footstep02.ogg",
            "samples/platformer/sounds/effects/footstep03.ogg",
            "samples/platformer/sounds/effects/footstep04.ogg",
            "samples/platformer/sounds/effects/footstep05.ogg",
            "samples/platformer/sounds/effects/footstep06.ogg",
            "samples/platformer/sounds/effects/footstep07.ogg",
            "samples/platformer/sounds/effects/footstep08.ogg",
            "samples/platformer/sounds/effects/footstep09.ogg",
        ]
    })

    script Forge::Scripts::AudioScript.new(:jump, {
        files: [
            "samples/platformer/sounds/effects/sfx_jump.ogg"
        ]
    })

    widget HealthWidget.new

    #script Forge::Scripts::DebugRenderScript.new

    def initialize(opts)
        opts[:tile_w] = 128
        opts[:tile_h] = 128
        opts[:anchor_y] = 1
        super(opts)
    end

    def init
        send_to_scripts(:play_animation, :idle, true)
    end
end