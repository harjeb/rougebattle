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
    -- Enhanced evasion check using standardized evasion field
    local evasion_chance = defender.evasion or 0
    if love.math.random() < evasion_chance then
        return 0, false, true  -- 0伤害，非暴击，已闪避
    end
    
    local damage_variance = love.math.random() * 0.2 + 0.9
    local base_damage = attacker.attack * damage_variance
    local damage_reduction = defender.defense / (defender.defense + 100)
    local after_defense_damage = base_damage * (1 - damage_reduction)
    
    -- Enhanced critical hit calculation using standardized crit_rate field  
    local crit_chance = attacker.crit_rate or 0
    local is_critical = love.math.random() < crit_chance
    local final_damage = is_critical and (after_defense_damage * 1.5) or after_defense_damage
    
    -- Apply skill-based damage bonuses (on_hit and chance_effect) - damage only
    local SkillSystem = require("systems.skill_system")
    local additional_damage = SkillSystem.calculateOnHitDamageBonus(attacker, defender, final_damage)
    final_damage = final_damage + additional_damage
    
    return math.floor(final_damage), is_critical, false
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

function CombatEngine.applyAttackConsequences(attacker, defender, damage_dealt)
    local SkillSystem = require("systems.skill_system")
    
    -- Process healing effects for attacker (lifesteal, heal per hit)
    SkillSystem.processOnHitHealingEffects(attacker, defender, damage_dealt)
    
    -- Process reflection damage
    local reflect_damage = SkillSystem.processOnHitReceivedEffects(attacker, defender, damage_dealt)
    if reflect_damage > 0 then
        attacker.hp = math.max(0, attacker.hp - reflect_damage)
    end
    
    -- Apply debuffs to defender
    SkillSystem.applyDebuffs(attacker, defender)
    
    return reflect_damage
end

function CombatEngine.calculateEffectiveSpeed(character)
    local SkillSystem = require("systems.skill_system")
    
    -- Start with base attack speed
    local base_speed = character.attack_speed or 50
    
    -- Add conditional speed bonuses
    local speed_bonus = SkillSystem.calculateConditionalEffects(character)
    
    -- Subtract active debuffs
    local speed_debuff = SkillSystem.getActiveDebuffValue(character, "speed_reduction")
    
    -- Calculate final effective speed (minimum 1)
    local effective_speed = math.max(1, base_speed + speed_bonus - speed_debuff)
    
    return effective_speed
end

return CombatEngine