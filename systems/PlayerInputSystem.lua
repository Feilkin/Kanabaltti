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

    player.animation_speed = 0.5 + (player.speed.x / player.max_speed.x)

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

                -- spawn some dust particles
                for i = 1, 4 do
                    local ttl = love.math.random() * 0.5 + 0.3
                    local dust = {
                        position = {
                            x = player.position.x + 16,
                            y = player.position.y + player.body.height,
                        },
                        speed = {
                            x = love.math.random(-200, 200),
                            y = love.math.random(-300, -200),
                        },
                        max_speed = {
                            x = 100,
                            y = 666,
                        },
                        acceleration = {
                            x = love.math.random(-100, 100),
                            y = 1000,
                        },
                        spritesheet = player.spritesheet,
                        animations = player.animations,
                        sprite = "dust",
                        animation = "DustIdle",
                        render_order = 3,
                        animation_speed = 0.8 / ttl,
                        time_to_live = ttl,
                    }

                    self.world:addEntity(dust)
                end

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

    if player.on_ground and not player.was_on_ground then
        local last_y_speed = player.last_speed.y
        local spd_r = last_y_speed / player.max_speed.y
        local dust_amount = math.floor((spd_r - 0.5) * 2 * 10)

        if spd_r > 0.2 then
            sounds.land:setVolume(spd_r)
            sounds.land:play()
        end

        -- spawn some dust particles
        for i = 1, dust_amount do
            local ttl = love.math.random() * 0.5 + 0.3
            local dust = {
                position = {
                    x = player.position.x + 16,
                    y = player.position.y + player.body.height,
                },
                speed = {
                    x = love.math.random(-200, 200),
                    y = love.math.random(-300, -200),
                },
                max_speed = {
                    x = 100,
                    y = 666,
                },
                acceleration = {
                    x = love.math.random(-100, 100),
                    y = 1000,
                },
                spritesheet = player.spritesheet,
                animations = player.animations,
                sprite = "dust",
                animation = "DustIdle",
                render_order = 3,
                animation_speed = 0.8 / ttl,
                time_to_live = ttl,
            }

            self.world:addEntity(dust)
        end
    end
end

return PlayerInputSystem