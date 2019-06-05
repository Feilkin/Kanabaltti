local tiny = require "tiny"

local BlockRenderer = tiny.processingSystem()
BlockRenderer.filter = tiny.requireAll("block")
BlockRenderer.renderer = true

function BlockRenderer:onAdd(entity)

end

function BlockRenderer:onRemove(entity)

end

function BlockRenderer:onModify(dt)

end

function BlockRenderer:onAddToWorld(world)

end

function BlockRenderer:onRemoveFromWorld(world)

end

function BlockRenderer:preProcess(dt)
    local camera = self.world.camera
    love.graphics.push()
    love.graphics.translate(camera.x, camera.y)
end

function BlockRenderer:process(e, dt)
    love.graphics.setColor(e.color)
    love.graphics.rectangle("fill", math.floor(e.position.x), math.floor(e.position.y), e.body.width, e.body.height)
end

function BlockRenderer:postProcess(dt)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return BlockRenderer