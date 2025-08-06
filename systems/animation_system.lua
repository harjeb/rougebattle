local AnimationSystem = {}

local active_animations = {}

-- Animation types
local ANIMATION_TYPE = {
    BULLET = "bullet"
}

function AnimationSystem.update(dt)
    for i = #active_animations, 1, -1 do
        local anim = active_animations[i]
        anim.time = anim.time + dt
        
        if anim.type == ANIMATION_TYPE.BULLET then
            anim.progress = math.min(1, anim.time / anim.duration)
            
            if anim.progress >= 1 then
                -- Animation complete - trigger callback
                if anim.on_complete then
                    anim.on_complete()
                end
                table.remove(active_animations, i)
            end
        end
    end
end

function AnimationSystem.draw()
    for _, anim in ipairs(active_animations) do
        if anim.type == ANIMATION_TYPE.BULLET then
            AnimationSystem.drawBullet(anim)
        end
    end
end

function AnimationSystem.drawBullet(anim)
    -- Calculate current position along trajectory
    local current_x = anim.start_x + (anim.end_x - anim.start_x) * anim.progress
    local current_y = anim.start_y + (anim.end_y - anim.start_y) * anim.progress
    
    -- Draw bullet as a small circle
    love.graphics.setColor(1, 1, 0.2, 1) -- Yellow bullet
    love.graphics.circle("fill", current_x, current_y, 3)
    
    -- Draw trajectory line with fade effect
    local alpha = math.max(0, 0.5 - anim.progress * 0.5)
    love.graphics.setColor(1, 0.8, 0, alpha)
    love.graphics.line(anim.start_x, anim.start_y, current_x, current_y)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function AnimationSystem.createBulletAnimation(start_x, start_y, end_x, end_y, duration, on_complete)
    local animation = {
        type = ANIMATION_TYPE.BULLET,
        start_x = start_x,
        start_y = start_y,
        end_x = end_x,
        end_y = end_y,
        duration = duration or 0.3,
        time = 0,
        progress = 0,
        on_complete = on_complete
    }
    
    table.insert(active_animations, animation)
    return animation
end

function AnimationSystem.clear()
    active_animations = {}
end

function AnimationSystem.hasActiveAnimations()
    return #active_animations > 0
end

return AnimationSystem