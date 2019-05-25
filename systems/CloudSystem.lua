local tiny = require "tiny"

local CloudSystem = tiny.processingSystem()
CloudSystem.filter = tiny.requireAll("cloud")

local cloud_quads = {
    "cloud1.png", "cloud2.png", "cloud3.png", "cloud4.png", "cloud5.png", "cloud6.png", "cloud7.png", "cloud8.png"
}


function CloudSystem:onAdd(entity)
end

function CloudSystem:onRemove(entity)

end

function CloudSystem:onModify(dt)

end

function CloudSystem:onAddToWorld(world)
    -- spawn some initial clouds

    for i = 1, 7 do
        local quad = cloud_quads[love.math.random(1, #cloud_quads)]

        local cloud = {
            spritesheet = spritesheet("assets/background-elements-redux/Spritesheet/spritesheet_default.xml", { render_order = 1 }),
            quad = quad,
            position = {
                x = love.math.random(-800, 1200),
                y = love.math.random(-300, 100),
            },
            speed = {
                x = love.math.random(-500, -100),
                y = 0,
            },
            color = { 1, 1, 1, 0.9 },
            cloud = true,
        }

        self.world:addEntity(cloud)
    end
end

function CloudSystem:onRemoveFromWorld(world)

end

function CloudSystem:preProcess(dt)
    local entities = #self.entities
    local last_block = self.entities[entities]

    local min, max = math.min, math.max

    while entities < 7 do
        local cloud = {
            spritesheet = spritesheet("assets/background-elements-redux/Spritesheet/spritesheet_default.xml"),
            quad = cloud_quads[love.math.random(1, #cloud_quads)],
            position = {
                x = player.position.x + love.math.random(1200, 1300),
                y = love.math.random(-300, 0),
            },
            speed = {
                x = love.math.random(-500, -100),
                y = 0,
            },
            cloud = true,
        }

        self.world:addEntity(cloud)
        entities = entities + 1
    end
end

function CloudSystem:process(e, dt)
    -- if block is past camera zone, remove it
    -- TODO: get camera zone
    local kill_x = player.position.x - 1000

    if e.position.x < kill_x then
        self.world:removeEntity(e)
    end
end

function CloudSystem:postProcess(dt)

end

return CloudSystem