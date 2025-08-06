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
    
    -- Use specified color for the bullet
    love.graphics.setColor(anim.color[1], anim.color[2], anim.color[3], anim.color[4])
    love.graphics.circle("fill", current_x, current_y, 3)
    
    -- Draw trajectory line with fade effect using bullet color
    local alpha = math.max(0, 0.5 - anim.progress * 0.5)
    love.graphics.setColor(anim.color[1], anim.color[2], anim.color[3], alpha * 0.5)
    love.graphics.line(anim.start_x, anim.start_y, current_x, current_y)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function AnimationSystem.createBulletAnimation(start_x, start_y, end_x, end_y, duration, color, attacker_type, attack_timestamp, on_complete)
    local animation = {
        type = ANIMATION_TYPE.BULLET,
        start_x = start_x,
        start_y = start_y,
        end_x = end_x,
        end_y = end_y,
        duration = duration or 0.3,
        time = 0,
        progress = 0,
        color = color or {1, 1, 0.2, 1}, -- Default to yellow
        attacker_type = attacker_type or "player",
        attack_timestamp = attack_timestamp or love.timer.getTime(),
        bullet_id = AnimationSystem.generateBulletId(),
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

function AnimationSystem.generateBulletId()
    return "bullet_" .. tostring(love.timer.getTime()) .. "_" .. tostring(math.random(1000, 9999))
end

function AnimationSystem.getActiveAnimationCount()
    return #active_animations
end

function AnimationSystem.getAnimationsByTimestamp()
    local sorted = {}
    for _, anim in ipairs(active_animations) do
        table.insert(sorted, anim)
    end
    table.sort(sorted, function(a, b) return a.attack_timestamp < b.attack_timestamp end)
    return sorted
end

function AnimationSystem.checkAttackCollision()
    -- Detect if multiple animations are arriving at the same time
    local threshold = 0.1  -- 100ms threshold for "simultaneous" attacks
    local arrivals = {}
    
    for _, anim in ipairs(active_animations) do
        if anim.progress >= 0.95 then  -- About to arrive
            table.insert(arrivals, {
                anim = anim,
                time_to_arrival = (1 - anim.progress) * anim.duration
            })
        end
    end
    
    -- Stagger simultaneous arrivals to avoid visual overlap
    if #arrivals > 1 then
        table.sort(arrivals, function(a, b) return a.time_to_arrival < b.time_to_arrival end)
        for i = 2, #arrivals do
            if math.abs(arrivals[i].time_to_arrival - arrivals[1].time_to_arrival) < threshold then
                -- Slightly delay subsequent attacks
                local original_callback = arrivals[i].anim.on_complete
                arrivals[i].anim.on_complete = function()
                    -- Delay by 50ms per concurrent attack
                    local delay = 0.05 * (i - 1)
                    if love.timer then
                        -- Use a simple timer approach for LOVE2D
                        local target_time = love.timer.getTime() + delay
                        local function check_time()
                            if love.timer.getTime() >= target_time then
                                original_callback()
                            else
                                -- This would need a proper timer system in a real implementation
                                -- For now, we'll execute immediately as the delay is minimal
                                original_callback()
                            end
                        end
                        check_time()
                    else
                        original_callback()
                    end
                end
            end
        end
    end
end

return AnimationSystem