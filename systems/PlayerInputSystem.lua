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
            local jmp_t = player.jump_time
            local jmp_r = (max_jump_time - jmp_t)
            local jmp_p = (jmp_t < 0.1 and -300 or -500)
            player.speed.y = jmp_p * jmp_r * jmp_r

            if player.jump_time > 0.3 then
                player.animation = "Fly"
            end

            if player.jump_time > 0.1 then
                sounds.flap:play()
            end

            if jmp_t > max_jump_time then
                player.animation = "Glide"
            end
        else
            if player.on_ground then
                -- its a new jump
                player.animation = "Jump"
                sounds.bukaak:play()

                -- TODO: sound effects?
                player.speed.y = -300
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
            player.animation = "Glide"
        end
    end


    -- TODO: xD
    player.rotation = math.sin(player.speed.y / player.max_speed.y)
end

return PlayerInputSystem