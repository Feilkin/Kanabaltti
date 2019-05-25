local tiny = require "tiny"

local TreeSystem = tiny.processingSystem()
TreeSystem.filter = tiny.requireAll("tree")

local tree_quadas = {
    "tree.png", "treeLong.png", "treePine.png", "treeDead.png",
}


function TreeSystem:onAdd(entity)
end

function TreeSystem:onRemove(entity)

end

function TreeSystem:onModify(dt)

end

function TreeSystem:onAddToWorld(world)
    -- spawn some initial clouds

    for i = 1, 20 do
        local quad = tree_quadas[love.math.random(1, #tree_quadas)]

        local tree = {
            spritesheet = spritesheet("assets/background-elements-redux/Spritesheet/spritesheet_default.xml", { render_order = 1 }),
            quad = quad,
            position = {
                x = love.math.random(-800, 1200),
                y = love.math.random(50, 100),
            },
            color = { 1, 1, 1, 0.9 },
            tree = true,
        }

        self.world:addEntity(tree)
    end
end

function TreeSystem:onRemoveFromWorld(world)

end

function TreeSystem:preProcess(dt)
    local entities = #self.entities
    local last_block = self.entities[entities]

    local min, max = math.min, math.max

    if entities < 20 then
        local tree = {
            spritesheet = spritesheet("assets/background-elements-redux/Spritesheet/spritesheet_default.xml"),
            quad = tree_quadas[love.math.random(1, #tree_quadas)],
            position = {
                x = player.position.x + love.math.random(1200, 1300),
                y = love.math.random(50, 100),
            },
            tree = true,
        }

        self.world:addEntity(tree)
        entities = entities + 1
    end
end

function TreeSystem:process(e, dt)
    -- if block is past camera zone, remove it
    -- TODO: get camera zone
    local kill_x = player.position.x - 1000

    if e.position.x < kill_x then
        self.world:removeEntity(e)
    end
end

function TreeSystem:postProcess(dt)

end

return TreeSystem