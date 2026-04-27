class TeleportScript < Forge::Script 
    attr :destination

    def level
        Forge.config.game_class.s.root.level(iid: destination.levelIid)
    end

    def entity 
        level.entity(destination.entityIid)
    end

    def on_interact(player)
        Forge.config.game_class.s.start_level(level)
        player.set_pos_case(entity.grid[0], entity.grid[1])
    end
end