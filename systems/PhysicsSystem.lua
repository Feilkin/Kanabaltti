local tiny = require "tiny"
local bump = require "bump"

local PhysicsSystem = tiny.processingSystem()
PhysicsSystem.filter = tiny.requireAll(tiny.requireAny("body", "speed"), "position")

function PhysicsSystem:onAdd(entity)
    local ex, ey = entity.position.x, entity.position.y
    local b = entity.body

    if b then
        b.entity = entity

        self.world.bump:add(entity, ex + (b.x or 0), ey + (b.y or 0), b.width, b.height)
    
        if DEBUG then print("added  " .. entity.name .. " to physics") end
    end
end

function PhysicsSystem:onRemove(entity)
    if self.world.bump:hasItem(entity) then
        self.world.bump:remove(entity)
    end
end

function PhysicsSystem:onModify(dt)

end

function PhysicsSystem:onAddToWorld(world)
    world.bump = bump.newWorld(512)
end

function PhysicsSystem:onRemoveFromWorld(world)
    world.bump = nil
end

function PhysicsSystem:process(e, dt)
    local b = e.body

    if b and  b.teleport then
        self.world.bump:update(e, e.position.x + (b.x or 0), e.position.y + (b.y or 0), b.width, b.height)
        b.teleport = nil
    end

    if e.speed then
        -- accelerate
        if e.acceleration then
            e.speed.x = math.min(e.speed.x + e.acceleration.x * dt, e.max_speed.x)
            e.speed.y = math.min(e.speed.y + e.acceleration.y * dt, e.max_speed.y)
        end

        local targetX, targetY = e.position.x + e.speed.x * dt,
                                 e.position.y + e.speed.y * dt

        --targetX, targetY = math.floor(targetX), math.floor(targetY)

        if b then
            local actualX, actualY, cols, len = self.world.bump:move(e, targetX + (b.x or 0), targetY + (b.y or 0), b.filter)
            e.position.x = actualX - (b.x or 0)
            e.position.y = actualY - (b.y or 0)
    
            e.on_ground = false
            for i = 1, len do
                local col = cols[i]
                -- TODO: collision handling
                local skip_collision_handling
                if e.collide then
                    skip_collision_handling = e:collide(col)
                end
    
                if not skip_collision_handling then
                    if col.type == "slide" then
                        if col.normal.y == -1 then
                            e.speed.y = 0
                            e.on_ground = true
                        end
    
                        if col.normal.x == -1 then
                            e.speed.x = math.min(e.speed.x, 0)
                        elseif col.normal.x == 1 then
                            e.speed.x = math.max(e.speed.x, 0)
                        end
                    elseif col.type == "bounce" then
                        e.speed.x = e.speed.x * (col.normal.x < 0 and -1 or 1) * col.other.body.bounciness
                        e.speed.y = e.speed.y * (col.normal.y < 0 and -1 or 1) * col.other.body.bounciness
                    end
                end
            end
        else
            e.position.x, e.position.y = targetX, targetY
        end
    end
end

return PhysicsSystem