love.filesystem.setRequirePath("?.lua;?/init.lua;libs/?.lua;libs/?/init.lua")
local parsexml = require "parsexml"
local json = require "json"

local world
local fonts
local game_over = false
local paused = true
local highscore
sounds = {}
local music

local reject_renderer
local only_renderer

function init_world()
    local tiny = require "tiny"
    world = tiny.world(
        require "systems.BlockSpawnerSystem",
        require "systems.CloudSystem",
        --require "systems.TreeSystem",
        require "systems.PlayerInputSystem",
        require "systems.PhysicsSystem",
        require "systems.AnimationSystem",
        require "systems.EntityDespawner",
        -- renderers
        --require "systems.BlockRenderer",
        require "systems.SpriteRenderer"
    )

    reject_renderer = tiny.rejectAny("renderer")
    only_renderer = tiny.requireAll("renderer")
end

function init_player()
    local spritesheet = spritesheet("assets/sprites/spritesheet.json", { render_order = 2 })
    
    player = {
        name = "player",
        spritesheet = spritesheet,
        sprite = "chicken",
        render_order = 2,
        sprite_offset = {
            x = 18,
            y = 20,
        },
        sprite_origin = {
            x = 24,
            y = 34,
        },
        animations = spritesheet.meta.frameTags,
        animation = "Walk",
        player = true,
        speed = { x = 0, y = 0 },
        max_speed = { x = 800, y = 666 },
        acceleration = { x = 100,  y = 1000 },
        position = { x = 0, y = 0 },
        body = {
            width = 32,
            height = 32,
            filter = function(player, other)
                if other.body.type == "window" then
                    return "cross"
                end

                return other.body.type or "slide"
            end
        },
    }

    function player:collide(col)
        if col.other.crate then
            local crate = col.other

            if col.normal.x == -1 then
                -- despawn crate
                world:removeEntity(crate)
                -- stop player
                --player.speed.x = 0
    
                -- spawn falling crate
                local falling_crate = {
                    position = { x = crate.position.x, y = crate.position.y },
                    speed = { x = 0, y = 0 },
                    acceleration = { x = 0, y = 1000 },
                    max_speed = { x = 100, y = 1000 },
                    spritesheet = crate.spritesheet,
                    sprite = crate.sprite,
                    render_order = 1,
                    animation = crate.animation,
                    animations = crate.animations,
                }
                -- WTF????
                falling_crate.speed.x = 0

                world:addEntity(falling_crate)

                return false
            end
        end
    end

    world:addEntity(player)
end

function init_ui()
    local big_font = love.graphics.newFont("assets/LuckiestGuy-Regular.ttf", 40)
    local small_font = love.graphics.newFont("assets/LuckiestGuy-Regular.ttf", 18)
    fonts = {
        big = big_font,
        small = small_font,
    }
end

function is_on_screen(e)
    local gw, gh = love.graphics.getDimensions()
    local cx, cy = get_camera_offset()
    local translated_x, translated_y = cx + e.position.x, cy + e.position.y
    local ew, eh = e.size.x, e.size.y

    return (translated_x + ew > 0 and translated_x < gw + ew) and
           (translated_y + eh > 0 and translated_y < gh + eh)
end

function reset_game()
    print("resetting..")

    world:clearEntities()
    world:refresh()
    -- reset block rng
    world.systems[1]:reseed()
    
    player.position.x, player.position.y = 0, 0
    player.speed.x, player.speed.y = 0, 0

    player.body.teleport = true

    world:addEntity(player)

    local spritesheet = spritesheet("assets/sprites/spritesheet.json", { render_order = 2 })
    spritesheet.spritebatch:clear()

    game_over = false
    last_camera_pos = nil

    music:seek(0)
    music:play()
end


local _spritesheet_cache = {}
function spritesheet(filename, ...)
    return _spritesheet_cache[filename] or load_spritesheet(filename, ...)
end

function load_spritesheet(filename, ...)
    local extension = filename:match("^.+(%..+)$")
    local spritesheet
    if extension == ".png" then
        error(".png format not supported! use aseprite JSON instead! (" .. filename .. ")")
    elseif extension == ".xml" then
        error(".xml format not supported! use aseprite JSON instead! (" .. filename .. ")")
    elseif extension == ".json" then
        spritesheet = load_spritesheet_from_json(filename, ...)
    end

    _spritesheet_cache[filename] = spritesheet
    return spritesheet
end

function load_spritesheet_from_json(filename, opts)
    local content, size = love.filesystem.read(filename)
    local parsed = assert(json.decode(content), "Failed to parse spritesheet JSON!")

    local folder_name = filename:match("(.*/)")
    local image_filename = folder_name .. "/" .. parsed.meta.image
    local image = love.graphics.newImage(image_filename)
    local iw, ih = image:getDimensions()

    local spritebatch = love.graphics.newSpriteBatch(image, 100, "stream")
    local sprites = {}

    for i, frame in ipairs(parsed.frames) do
        local quad = love.graphics.newQuad(frame.frame.x, frame.frame.y, frame.frame.w, frame.frame.h, iw, ih)
        frame.quad = quad
        parsed.frames[frame.filename] = frame

        local sprite, frame_i = frame.filename:match("^(.+)-([0-9]+)$")
        sprites[sprite] = sprites[sprite] or {}
        sprites[sprite][tonumber(frame_i)] = frame
    end

    -- frameTag lookup
    for i, frameTag in ipairs(parsed.meta.frameTags) do
        local frames = {}
        for j = frameTag.from, frameTag.to do
            table.insert(frames, j)
        end
        frameTag.frames = frames

        -- TODO: figure out how to tell which sprite this belongs to?
        parsed.meta.frameTags[frameTag.name] = frameTag
    end

    return {
        texture = image,
        spritebatch = spritebatch,
        frames = parsed.frames,
        render_order = opts.render_order or 0,
        meta = parsed.meta,
        sprites = sprites,
    }
end

function love.load()
    if love.system.getOS() == 'ios' or love.system.getOS() == 'Android' then
        local dw, dh = love.window.getDesktopDimensions()
        love.window.setMode(dw, dh, { fullscreen = true })
    end

    init_world()
    init_player()
    init_ui()

    -- sounds
    sounds = {
        bukaak = love.audio.newSource("assets/bukaak.wav", "static"),
        splat = love.audio.newSource("assets/splat.wav", "static"),
        flap = love.audio.newSource("assets/flap.wav", "static"),
        land = love.audio.newSource("assets/land1.wav", "static"),
    }

    music = love.audio.newSource("assets/Cancan.ogg", "stream")
    music:setLooping(true)
    music:setVolume(0.3)
    music:play()

    highscore = load_highscore()

    love.graphics.setBackgroundColor(12 / 255, 241 / 255, 1, 1)

    -- update world once
    world:update(0, reject_renderer)
end

function love.update(dt)
    if game_over then return end
    if paused then return end

    if dt > 0.2 then dt = 0.2 end

    world:update(dt, reject_renderer)

    -- FIXME: XDDD
    music:setPitch(0.9 + (player.speed.x / player.max_speed.x)^3 * 0.2)

    if player.position.y > 1000 then
        game_over = true
        sounds.splat:play()
        update_highscore()
    end
end

function load_highscore()
    -- check if hiscore file exists
    if not love.filesystem.getInfo("hiscore.txt") then
        love.filesystem.newFile("hiscore.txt")
        love.filesystem.write("hiscore.txt", 0)

        return 0
    end

    local contents = love.filesystem.read("hiscore.txt")
    return tonumber(contents)
end

function update_highscore()
    if player.position.x > highscore then
        highscore = math.floor(player.position.x)
        love.filesystem.write("hiscore.txt", highscore)
    end
end

function love.focus(f)
    if not f then
        paused = true
        music:pause()
    end
end

function love.keypressed(key, code)
    if key == "r" then
        reset_game()
    end

    if key == "space" then
        if paused then paused = false; music:play() end
        if game_over then reset_game() end
    end

    if key == "p" then
        paused = not paused
        if paused then music:pause()
        else music:play() end
    end
    if key == "escape" then love.event.quit() end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if paused then
        paused = false
        music:play()
    end

    if game_over then
        reset_game()
    end
end

function love.draw()
    -- position camera

    local cx, cy = get_camera_offset()

    world.camera = { x = cx, y = cy }
    world:update(1, only_renderer)
    
    draw_ui()

    love.graphics.setColor(1, 1, 1, 1)

    last_camera_pos = { cx, cy }
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
        dx = math.min(dx, 2) -- FIXME: hardcoded
        cx, cy = old_x + dx, old_y + dy
    end

    cx, cy = math.floor(cx), math.floor(cy)

    return cx, cy
end

function draw_ui()
    local gw, gh = love.graphics.getDimensions()
    if game_over then
        love.graphics.setFont(fonts.big)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 0, 0, gw, gh)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("GAME OVER", 0, gh/2, gw, "center" )
        love.graphics.printf("SCORE: " .. math.floor(player.position.x), 0, gh/2 + 50, gw, "center" )
        love.graphics.printf("RECORD: " .. highscore, 0, gh/2 + 100, gw, "center" )
    elseif paused then
        love.graphics.setFont(fonts.big)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", 0, 0, gw, gh)
        love.graphics.setColor(1, 235/255, 87/255, 1)
        love.graphics.printf("KANABALTTI", 0, gh/2, gw, "center" )
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.printf("paused", 0, gh/2 + 40, gw, "center" )

    else
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.printf("SCORE: " .. math.floor(player.position.x), 0, 8, gw, "center" )
        if player.position.x > highscore then
            love.graphics.printf("NEW HIGH SCORE!", 0, 30, gw, "center" )
        end

        if DEBUG then
            love.graphics.print("entities: " .. #world.entities)
            love.graphics.print("fps: " .. love.timer.getFPS(), 0, 20)
            love.graphics.print("speed: " .. player.speed.x, 0, 40)
        end
    end
end