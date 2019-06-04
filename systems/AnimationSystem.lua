local tiny = require "tiny"

local AnimationSystem = tiny.processingSystem()
AnimationSystem.filter = tiny.requireAll("spritesheet", "sprite", "animations", "animation")

function AnimationSystem:onAdd(entity)
    if not entity.quad then
        local frame_i = assert(entity.animations[entity.animation].frames[1])
        entity.quad = entity.spritesheet.sprites[entity.sprite][frame_i].quad
        self.world:addEntity(entity)
    end
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
    local anim = e.animations[e.animation]

    if #anim.frames == 1 then
        local frame_i = anim.frames[1]
        e.quad = e.spritesheet.sprites[e.sprite][frame_i].quad
        return
    end

    local old_frame_i = e.cur_frame or 1

    if e.last_frame_anim and e.last_frame_anim ~= e.animation then
        e.frame_time = 0
        e.cur_frame = 1
        old_frame_i = 1
    end

    local cur_frame = e.spritesheet.sprites[e.sprite][anim.frames[old_frame_i]]

    if not cur_frame then
        print(anim.name, e.last_frame_anim)
        print(old_frame_i)
        error("no frame")
    end

    e.frame_time = (e.frame_time or 0) + dt * (e.animation_speed or 1)
    
    if e.frame_time > cur_frame.duration / 1000 then
        e.frame_time = 0
        e.cur_frame = (#anim.frames > 1) and ((old_frame_i % #anim.frames) + 1) or 1
        local frame_i = anim.frames[e.cur_frame]
        e.quad = e.spritesheet.sprites[e.sprite][frame_i].quad
    end

    e.last_frame_anim = e.animation
end

function AnimationSystem:postProcess(dt)

end

return AnimationSystem