local tiny = require "tiny"

local PlayerInputSystem = tiny.processingSystem()
PlayerInputSystem.filter = tiny.requireAll("player")

function PlayerInputSystem:process(player, dt)
    local max_jump_time = 1

    if player.jumping then
        player.jump_time = player.jump_time + dt
        -- FIXME: hardcoded value
        if player.jump_time > max_jump_time then
            player.jumping = false
            player.jump_time = 0
        end
    end

    if love.keyboard.isDown("space") or #love.touch.getTouches() > 0 then
        if player.jumping then
            -- it's a old jump
            local jmp_r = (max_jump_time - player.jump_time)
            player.speed.y = -400 * jmp_r * jmp_r

            if player.jump_time > 0.3 then
                player.animation = "Fly"
            end
        else
            if player.on_ground then
                -- its a new jump
                player.animation = "Jump"

                -- TODO: sound effects?
                player.speed.y = -400
                player.jumping = true
                player.jump_time = 0
            end
        end
    else
        player.jumping = false
        player.jump_time = 0

        if player.speed.y == 0 then
            if player.speed.x < 700 then
                player.animation = "Walk"
            else
                player.animation = "Run"
            end
        else
            player.animation = "Fly"
        end
    end
end

return PlayerInputSystem