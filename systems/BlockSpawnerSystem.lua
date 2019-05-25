local tiny = require "tiny"

local min, max = math.min, math.max

local BlockSpawnerSystem = tiny.sortedProcessingSystem()
BlockSpawnerSystem.filter = tiny.requireAll("block")
BlockSpawnerSystem.compare = function(self, a, b) return a.position.x < b.position.x end

local block_i = 0

function BlockSpawnerSystem:newBarn(spritesheet, last_block)
    local rng = self.world._block_spawner_rng
    local last_edge_x, last_edge_y = last_block.position.x + last_block.body.width, last_block.position.y

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

    local length = 700 --rng:random(min_length, max_length)

    local shade = rng:random() * 0.5 + 0.5

    local block = { -- base block
        spritesheet = spritesheet,
        sprite = "barn",
        render_order = 0,
        animation = "Idle",
        animations = spritesheet.meta.frameTags,
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

    return { block }
end

function BlockSpawnerSystem:newTallBarn(spritesheet, last_block)
    local rng = self.world._block_spawner_rng
    local last_edge_x, last_edge_y = last_block.position.x + last_block.body.width, last_block.position.y

    local min_length = 200
    local max_length = 800
    local max_y = -200 -- blocks are never lower than 500px
    local min_y = -300
    local max_gap = 500
    local min_gap = 50
    local max_fall = min(200, max_y - last_edge_y)
    local max_rise = max(-300, min_y - last_edge_y)

    local x_diff = rng:random(min_gap, max_gap)
    local y_diff = rng:random(max_rise, max_fall)

    local length = 1024 --rng:random(min_length, max_length)

    local shade = rng:random() * 0.2 + 0.8

    local block_x, block_y = last_edge_x + x_diff, last_edge_y + y_diff

    local block = {
        spritesheet = spritesheet,
        sprite = "tall-barn",
        render_order = 0,
        animation = "Idle",
        animations = spritesheet.meta.frameTags,
        color = { shade, shade, shade, 1 },
        position = {
            x = block_x,
            y = block_y,
        },
        body = {
            width = length,
            height = 1000,
            type = "cross",
        },
        block = true,
    }

    -- floor
    local block_floor = {
        position = {
            x = block_x,
            y = block_y + 404,
        },
        body = {
            width = length,
            height = 596,
        },
    }

    return { block, block_floor }
end

local generators = {
    --"newBarn",
    "newTallBarn",
}
function BlockSpawnerSystem:newRandomBlock(...)
    local rng = self.world._block_spawner_rng
    local gen_name = generators[rng:random(1, #generators)]
    return self[gen_name](self, ...)
end

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

    local spritesheet = spritesheet("assets/sprites/spritesheet.json")

    while entities < 10 do
        -- spawn block
        local blocks
        if last_block then
            blocks = self:newRandomBlock(spritesheet, last_block)
        else
            -- it's the first block
            local block = {
                spritesheet = spritesheet,
                sprite = "barn",
                render_order = 0,
                animation = "Idle",
                animations = spritesheet.meta.frameTags,
                color = {0.8, 0.8, 0.8, 1},
                position = {
                    x = -100,
                    y = 100,
                },
                body = {
                    width = 700,
                    height = 1000,
                },
                block = true
            }
            blocks = { block }
        end

        block_i = block_i + 1
        for i, block in ipairs(blocks) do
            if DEBUG then block.name = "block-" .. block_i .. "-" .. i end
    
            self.world:addEntity(block)
        end

        entities = entities + 1
        last_block = blocks[1]
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