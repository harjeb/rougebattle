local CombatEngine = {}

-- 速度转攻击间隔公式
-- 速度50 = 1.0秒间隔, 速度1000 = 0.03秒间隔
-- 使用指数衰减公式: interval = 1.0 * (0.03/1.0)^((speed-50)/(1000-50))
function CombatEngine.speedToInterval(speed)
    if speed <= 50 then
        return 1.0
    elseif speed >= 1000 then
        return 0.03
    else
        local progress = (speed - 50) / (1000 - 50)  -- 0到1的进度
        local interval = 1.0 * math.pow(0.03, progress)
        return interval
    end
end

function CombatEngine.calculateDamage(attacker, defender)
    local damage_variance = love.math.random() * 0.2 + 0.9
    local base_damage = attacker.attack * damage_variance
    local damage_reduction = defender.defense / (defender.defense + 100)
    local after_defense_damage = base_damage * (1 - damage_reduction)
    local is_critical = love.math.random() < attacker.crit_rate
    local final_damage = is_critical and (after_defense_damage * 1.5) or after_defense_damage
    return math.floor(final_damage), is_critical
end

function CombatEngine.calculateUltimateDamage(attacker, defender)
    local base_damage = (attacker.attack + attacker.special_attack)
    local damage_reduction = defender.special_defense / (defender.special_defense + 100)
    local final_damage = base_damage * (1 - damage_reduction)
    return math.floor(final_damage)
end

function CombatEngine.determineTurnOrder(player, monster)
    return player.attack_speed >= monster.attack_speed and "player" or "monster"
end

function CombatEngine.incrementUltimate(character)
    character.ultimate_value = (character.ultimate_value or 0) + 2
    return character.ultimate_value >= 100
end

function CombatEngine.resetUltimate(character)
    character.ultimate_value = 0
end

return CombatEngine