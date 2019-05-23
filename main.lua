local bump = require "bump"

local blocks
local world
local player
local game_over = false
local paused = true

function init_world()
    world = bump.newWorld(128)
end

function init_player()
    player = {
        speed = { x = 0, y = 0 },
        max_speed = { x = 800, y = 666 },
        acceleration = { x = 100,  y = 1000 },
        position = { x = 0, y = 0 },
        size = { x = 32, y = 32},
    }

    world:add(player, player.position.x, player.position.y, player.size.x, player.size.y)

    -- load player spritesheet
    local texture = love.graphics.newImage("chicken.png")
    local quads = {}
    do 
        local iw, ih = texture:getDimensions()
        local sw, sh = 48, 48
        local rows, cols = ih / sh, iw / sw
        for r = 0, rows - 1 do
            for c = 0, cols - 1 do
                table.insert(quads, love.graphics.newQuad(c * sw, r * sh, sw, sh, iw, ih))
            end
        end
    end
    
    player.animations = {
        walk = { 1, 2, 3, 4, duration = 100 },
        run = { 11, 12, 13, 14, duration = 50 },
    }

    player.texture = texture
    player.animation = "walk"
    player.quads = quads
end

function init_blocks()
    blocks = {}
    -- add initial block for the player to stand on
    spawn_initial_blocks()
end

function player_filter(player, other)
    -- TODO: windows and such
    if other.killzone then return "touch" end
    return "slide"
end

function is_on_screen(e)
    local gw, gh = love.graphics.getDimensions()
    local cx, cy = get_camera_offset()
    local translated_x, translated_y = cx + e.position.x, cy + e.position.y
    local ew, eh = e.size.x, e.size.y

    return (translated_x + ew > 0 and translated_x < gw + ew) and
           (translated_y + eh > 0 and translated_y < gh + eh)
end

function update_blocks(dt)
    -- if first block is out of screen, remove it
    if #blocks > 1 then
        if not is_on_screen(blocks[1]) then
            pop_block()

            -- add new block
            spawn_block()
        end
    else
        spawn_block()
    end
end

function spawn_initial_blocks()
    add_block {
        position = { x = -100, y = 10 },
        size = { x = 1000, y = 1000 },
    }

    for i = 1, 5 do
        spawn_block()
    end
end

function spawn_block()
    -- get position of previous block
    local last_block = blocks[#blocks]
    local last_block_x = last_block.position.x + last_block.size.x
    local last_block_y = last_block.position.y

    -- roll gap
    local gap_x = love.math.random(30, 200)

    -- TODO: roll y diff?
    local max_rise = math.max(-50, math.min(-200 - last_block_y, 0)) -- FIXME: hardcoded
    local max_fall = math.min(100, math.max(200 - last_block_y, 0))

    print(max_rise, max_fall, last_block_y + max_rise, last_block_y + max_fall)

    local gap_y = love.math.random(last_block_y + max_rise, last_block_y + max_fall)

    -- roll length
    local length = love.math.random(300, 1000)

    -- make new block
    add_block {
        position = { x = last_block_x + gap_x, y = gap_y }, -- TODO: fix Y
        size = { x = length, y = 1000 },
    }
end

function add_block(b)
    table.insert(blocks, b)
    world:add(b, b.position.x, b.position.y, b.size.x, b.size.y)
end

--- removes the first block
function pop_block()
    local b = table.remove(blocks, 1)
    world:remove(b) -- remove from bump
end

function reset_game()
    print("resetting..")
    while #blocks > 1 do
        pop_block()
    end


    player.position.x, player.position.y = 0, 0
    player.speed.x, player.speed.y = 0, 0

    world:update(player, player.position.x, player.position.y)

    spawn_initial_blocks()

    game_over = false
    last_camera_pos = nil
end

function love.load()
    init_world()
    init_player()
    init_blocks()
    
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
end

function love.update(dt)
    if game_over then return end
    if paused then return end

    -- update player speed
    local max, min = math.max, math.min
    player.speed.x = min(player.speed.x + player.acceleration.x * dt, player.max_speed.x)
    player.speed.y = max(min(player.speed.y + player.acceleration.y * dt, player.max_speed.y), -player.max_speed.y)
    
    if player.jumping then
        player.jump_time = player.jump_time + dt
        -- FIXME: hardcoded value
        if player.jump_time > 0.8 then
            player.jumping = false
            player.jump_time = 0
        end
    end

    if love.keyboard.isDown("space") or #love.touch.getTouches() > 0 then
        if player.jumping then
            -- it's a old jump
            player.speed.y = -400 * (0.5 - player.jump_time)
        else
            if player.on_ground then
                -- its a new jump
                -- TODO: sound effects?
                player.speed.y = -400
                player.jumping = true
                player.jump_time = 0
            end
        end
    else
        player.jumping = false
        player.jump_time = 0
    end

    -- move player
    local target_x = player.position.x + player.speed.x * dt
    local target_y = player.position.y + player.speed.y * dt
    local actual_x, actual_y, cols, len = world:move(player, target_x, target_y, player_filter)

    if actual_y > 1000 then
        game_over = true
        return
    end

    player.on_ground = false
    for i = 1, len do
        local col = cols[i]

        if col.other.killzone then
            -- TODO: game over
            game_over = true
        else
            if col.normal.y == -1 then
                -- TODO: spawn dust?
                player.speed.y = 0
                player.on_ground = true
            elseif col.normal.x == -1 then
                -- TODO: play oof
                player.speed.x = 0
            end
        end
    end
    
    player.position.x, player.position.y = actual_x, actual_y

    -- update player animation
    if player.animation == "walk" and player.speed.x > 700 then
        player.animation = "run"
        player.cur_frame = 1
        player.frame_time = 0
    elseif player.animation == "run" and player.speed.x < 600 then
        player.animation = "walk"
        player.cur_frame = 1
        player.frame_time = 0
    end

    do
        local anim = player.animations[player.animation]
        local old_frame = player.cur_frame or 1
        player.frame_time = (player.frame_time or 0) + dt
        if player.frame_time > anim.duration / 1000 then
            player.frame_time = 0
            player.cur_frame = (old_frame % #anim) + 1
        end
    end

    update_blocks(dt)
end

function love.focus(f)
    if not f then
        paused = true
    end
end

function love.keypressed(key, code)
    if key == "r" then
        reset_game()
    end

    if key == "space" then
        if paused then paused = false end
        if game_over then reset_game() end
    end

    if key == "p" then paused = not paused end
    if key == "escape" then love.event.quit() end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if paused then
        paused = false
    end

    if game_over then
        reset_game()
    end
end

function love.draw()
    -- position camera
    do
        local cx, cy = get_camera_offset()
        love.graphics.push()
        love.graphics.translate(cx, cy)
    end

    -- draw background
    draw_blocks()
    draw_player()

    love.graphics.pop()
    
    draw_ui()

    love.graphics.setColor(1, 1, 1, 1)

    last_camera_pos = { get_camera_offset() }
end

function get_camera_offset()
    local gw, gh = love.graphics.getDimensions()
    -- offset based on player speed
    local speed_factor = player.speed.x / player.max_speed.x
    -- at 0 speed, player is at center of screen
    -- as max speed, player is at left edge of screen + padding
    local padding = 100 -- FIXME: hardcoded
    local speed_offset_range = gw/2 - padding
    local speed_offset = padding + speed_offset_range * (1 - speed_factor)

    local off_x, off_y = speed_offset, gh/2 -- TODO: screen shake
    local cx, cy = -player.position.x + off_x, off_y

    if last_camera_pos then
        -- limit delta
        local old_x, old_y = last_camera_pos[1], last_camera_pos[2]
        local dx, dy = cx - old_x, cy - old_y
        dx = math.min(dx, 1) -- FIXME: hardcoded
        cx, cy = old_x + dx, old_y + dy
    end

    return cx, cy
end

function draw_blocks()
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    for _, b in ipairs(blocks) do
        love.graphics.rectangle("fill", b.position.x, b.position.y, b.size.x, b.size.y)
    end
end

function draw_player()
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    --love.graphics.rectangle("fill", player.position.x, player.position.y, player.size.x, player.size.y)

    -- get current frame
    local offset_x, offset_y = 18, 20
    local cur_frame = player.cur_frame or 1
    local anim = player.animations[player.animation]
    local quad_id = anim[cur_frame]
    local quad = player.quads[quad_id]

    local rot = math.sin(player.speed.y / player.max_speed.y)

    love.graphics.draw(player.texture, quad, math.floor(player.position.x + offset_x),
                                             math.floor(player.position.y + offset_y),
                                             rot,
                                            1, 1,
                                             24, 34)
end

function draw_ui()
    local gw, gh = love.graphics.getDimensions()
    if game_over then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 0, 0, gw, gh)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("GAME OVER", 0, gh/2, gw, "center" )
        love.graphics.printf("SCORE: " .. math.floor(player.position.x), 0, gh/2 + 20, gw, "center" )
    elseif paused then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", 0, 0, gw, gh)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PAUSED [p] to resume", 0, gh/2, gw, "center" )
    else
        love.graphics.printf("SCORE: " .. math.floor(player.position.x), 0, 8, gw, "center" )
    end
end