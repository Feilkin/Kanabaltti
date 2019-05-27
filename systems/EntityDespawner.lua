local tiny = require "tiny"

local AnimationSystem = tiny.processingSystem()
AnimationSystem.filter = tiny.requireAll("position", tiny.rejectAny("player"))

function AnimationSystem:onAdd(entity)
end

function AnimationSystem:onRemove(entity)

end

function AnimationSystem:onModify(dt)

end

function AnimationSystem:onAddToWorld(world)

end

function AnimationSystem:onRemoveFromWorld(world)

end

function AnimationSystem:preProcess(dt)
end

function AnimationSystem:process(e, dt)
    -- if block is past camera zone, remove it
    -- TODO: get camera zone
    local kill_x = player.position.x - 1000

    if e.position.x + (e.body and e.body.width or 0) < kill_x then
        self.world:removeEntity(e)
    end
end

function AnimationSystem:postProcess(dt)

end

return AnimationSystem