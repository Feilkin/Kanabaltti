local tiny = require "tiny"

local CloudSystem = tiny.processingSystem()
CloudSystem.filter = tiny.requireAll("cloud")

local cloud_sprites = {
    "cloud", "cloud4"
}


function CloudSystem:onAdd(entity)
end

function CloudSystem:onRemove(entity)

end

function CloudSystem:onModify(dt)

end

function CloudSystem:onAddToWorld(world)
end

function CloudSystem:onRemoveFromWorld(world)

end

function CloudSystem:preProcess(dt)
    local entities = #self.entities

    local min, max = math.min, math.max

    local spritesheet = spritesheet("assets/sprites/spritesheet.json")

    while entities < 7 do
        local sprite = cloud_sprites[love.math.random(1, #cloud_sprites)]

        local cloud = {
            spritesheet = spritesheet,
            sprite = sprite,
            sprite_scale = love.math.random() * 0.75 + 0.5,
            render_order = -1,
            animation = "Idle",
            animations = spritesheet.meta.frameTags,
            position = {
                x = player.position.x + love.math.random(1200, 2400),
                y = love.math.random(-300, 0),
            },
            speed = {
                x = love.math.random(-500, -300),
                y = 0,
            },
            cloud = true,
        }

        self.world:addEntity(cloud)
        entities = entities + 1
    end
end

function CloudSystem:process(e, dt)
end

function CloudSystem:postProcess(dt)

end

return CloudSystem