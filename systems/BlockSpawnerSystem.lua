local tiny = require "tiny"

local BlockSpawnerSystem = tiny.sortedProcessingSystem()
BlockSpawnerSystem.filter = tiny.requireAll("block")
BlockSpawnerSystem.compare = function(self, a, b) return a.position.x < b.position.x end

local block_i = 0

function BlockSpawnerSystem:reseed(seed)
    self.world._block_spawner_rng = love.math.newRandomGenerator(seed or os.time())
end

function BlockSpawnerSystem:onAddToWorld(world)
    self:reseed(os.time())
end

function BlockSpawnerSystem:onRemoveFromWorld(world)
    world._block_spawner_rng = nil
end

function BlockSpawnerSystem:preProcess(dt)
    local rng = self.world._block_spawner_rng
    -- spawn new blocks if needed
    local entities = #self.entities
    local last_block = self.entities[entities]

    local min, max = math.min, math.max

    while entities < 10 do
        -- spawn block
        local block
        if last_block then
            local last_edge_x, last_edge_y = last_block.position.x + last_block.body.width,
                                             last_block.position.y
            
            local min_length = 200
            local max_length = 800
            local max_y = 200 -- blocks are never lower than 500px
            local min_y = -200
            local max_gap = 500
            local min_gap = 50
            local max_fall = min(200, max(max_y - last_edge_y, 0))
            local max_rise = max(-100, min(min_y - last_edge_y, 0)) -- TODO: multi-floor blocks?

            local x_diff = rng:random(min_gap, max_gap)
            local y_diff = rng:random(max_rise, max_fall)

            local length = rng:random(min_length, max_length)

            local shade = rng:random() * 0.2 + 0.2

            block = {
                color = { shade, shade, shade, 1 },
                position = {
                    x = last_edge_x + x_diff,
                    y = last_edge_y + y_diff,
                },
                body = {
                    width = length,
                    height = 1000,
                },
                block = true,
            }
        else
            -- it's the first block
            block = {
                color = {0.2, 0.2, 0.2, 1},
                position = {
                    x = -1000,
                    y = 100,
                },
                body = {
                    width = 1500,
                    height = 1000,
                },
                block = true
            }
        end

        block_i = block_i + 1
        if DEBUG then block.name = "block-" .. block_i end

        self.world:addEntity(block)
        entities = entities + 1
        last_block = block
    end
end

function BlockSpawnerSystem:process(e, dt)
    -- if block is past camera zone, remove it
    -- TODO: get camera zone
    local kill_x = player.position.x - 1000

    if e.position.x + e.body.width < kill_x then
        self.world:removeEntity(e)
    end
end

return BlockSpawnerSystem