local tiny = require "tiny"

function by_render_order(a, b)
    if not a.render_order then
        if not b.render_order then
            return a
        end

        return b
    end

    if not b.render_order then return b end

    if a.render_order < b.render_order then return a end
    if a.render_order > b.render_order then return b end

    if a.position.y < b.position.y then return a end
    if a.position.y == b.position.y then return a.position.x < b.position.x end
    return b 
end

local SpriteRenderer = tiny.sortedProcessingSystem()
SpriteRenderer.filter = tiny.requireAll("spritesheet", "quad", "position")
SpriteRenderer.compare = function (self, a, b)
    if not a.render_order then
        if not b.render_order then
            return a
        end

        return b
    end

    if not b.render_order then return b end
    return a.render_order < b.render_order
end

SpriteRenderer.renderer = true


function SpriteRenderer:onAdd(entity)
    local spritebatches = self.world._spritebatches
    local spritesheet = entity.spritesheet
    if not spritebatches[spritesheet] then
        spritebatches[spritesheet] = 1
        table.insert(spritebatches, spritesheet)
    else
        spritebatches[spritesheet] = spritebatches[spritesheet] + 1
    end
end

function SpriteRenderer:onRemove(entity)
    local spritebatches = self.world._spritebatches
    local spritebatch = entity.spritesheet
    spritebatches[spritebatch] = spritebatches[spritebatch] - 1
    if spritebatches[spritebatch] < 1 then
        spritebatches[spritebatch] = nil

        local spritebatch_id
        for i, sb in ipairs(spritebatches) do
            if sb == spritebatch then
                spritebatch_id = i
                break
            end
        end

        table.remove(spritebatches, spritebatch_id)
    end
end

function SpriteRenderer:onAddToWorld(world)
    world._spritebatches = {}
end

function SpriteRenderer:onRemoveFromWorld(world)
    world._spritebatches = nil
end

function SpriteRenderer:preProcess(dt)
    for _, spritesheet in ipairs(self.world._spritebatches) do
        spritesheet.spritebatch:clear()
    end
end

function SpriteRenderer:process(e, dt)
    local spritesheet = e.spritesheet
    local spritebatch = spritesheet.spritebatch
    local quad = e.quad

    local x, y = e.position.x, e.position.y
    local ox, oy = 0, 0
    local r = e.rotation
    local scale = e.sprite_scale or 1

    if e.sprite_offset then
        x, y = x + e.sprite_offset.x, y + e.sprite_offset.y
    end

    if e.sprite_origin then
        ox, oy = e.sprite_origin.x, e.sprite_origin.y
    end

    if not r then
        if e.speed and e.max_speed then
            r = math.sin(e.speed.y / e.max_speed.y)
        end
    end

    if e.color then
        spritebatch:setColor(e.color)
    else
        spritebatch:setColor(1, 1, 1, 1)
    end

    x, y = math.floor(x), math.floor(y)
    spritebatch:add(quad, x, y, r or 0, scale, scale, ox, oy)
end

function SpriteRenderer:postProcess(dt)
    local camera = self.world.camera

    love.graphics.push()
    love.graphics.translate(camera.x, camera.y)

    local spritesheets = self.world._spritebatches
    table.sort(spritesheets, by_render_order)
    
    for i, ss in ipairs(spritesheets) do
        love.graphics.draw(ss.spritebatch, 0, 0)
    end

    love.graphics.pop()
end

return SpriteRenderer