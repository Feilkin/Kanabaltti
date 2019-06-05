local tiny = require "tiny"

local AnimationSystem = tiny.processingSystem()
AnimationSystem.filter = tiny.requireAll(tiny.requireAny("position", "time_to_live"), tiny.rejectAny("player"))

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

    if e.position and e.position.x + (e.body and e.body.width or 0) < kill_x then
        self.world:removeEntity(e)
    end

    -- timed death
    if e.time_to_live then
        e.time_to_live = e.time_to_live - dt

        if e.time_to_live < 0 then
            self.world:removeEntity(e)
        end
    end
end

function AnimationSystem:postProcess(dt)

end

return AnimationSystem