local SkillSystem = {}
local json = require("libraries.json")  -- Assuming JSON library

local skills_data = nil

function SkillSystem.load()
    local file = io.open("data/skills.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        skills_data = json.decode(content)
    end
end

function SkillSystem.getRandomSkills(count)
    if not skills_data then return {} end
    
    local available_skills = {}
    for _, skill in ipairs(skills_data.skills) do
        table.insert(available_skills, skill)
    end
    
    local selected = {}
    for i = 1, math.min(count, #available_skills) do
        local index = love.math.random(#available_skills)
        table.insert(selected, available_skills[index])
        table.remove(available_skills, index)
    end
    
    return selected
end

function SkillSystem.getSkillById(skill_id)
    if not skills_data then return nil end
    
    for _, skill in ipairs(skills_data.skills) do
        if skill.id == skill_id then
            return skill
        end
    end
    return nil
end

function SkillSystem.applySkill(player, skill_id)
    if not skills_data then return end
    
    local skill = SkillSystem.getSkillById(skill_id)
    if not skill then return end
    
    if skill.type == "permanent_stat" then
        for stat, value in pairs(skill.effects) do
            player.stats[stat] = player.stats[stat] + value
            if stat == "hp" then
                player.stats.max_hp = player.stats.max_hp + value
            end
        end
        
        if skill.stackable then
            player.skills[skill.id] = (player.skills[skill.id] or 0) + 1
        else
            player.skills[skill.id] = true
        end
    elseif skill.type == "victory_bonus" then
        player.skills[skill.id] = skill.stackable and ((player.skills[skill.id] or 0) + 1) or true
    elseif skill.type == "on_hit" then
        if skill.stackable then
            player.skills[skill_id] = (player.skills[skill_id] or 0) + 1
        else
            player.skills[skill_id] = true
        end
    elseif skill.type == "on_hit_received" then
        if skill.stackable then
            player.skills[skill_id] = (player.skills[skill_id] or 0) + 1
        else
            player.skills[skill_id] = true
        end
    elseif skill.type == "conditional" then
        if skill.stackable then
            player.skills[skill_id] = (player.skills[skill_id] or 0) + 1
        else
            player.skills[skill_id] = true
        end
    elseif skill.type == "chance_effect" then
        if skill.stackable then
            player.skills[skill_id] = (player.skills[skill_id] or 0) + 1
        else
            player.skills[skill_id] = true
        end
    elseif skill.type == "debuff" then
        if skill.stackable then
            player.skills[skill_id] = (player.skills[skill_id] or 0) + 1
        else
            player.skills[skill_id] = true
        end
    end
end

function SkillSystem.applyVictoryBonuses(player)
    if not skills_data then return end
    
    for skill_id, count in pairs(player.skills) do
        local skill = SkillSystem.getSkillById(skill_id)
        
        if skill and skill.type == "victory_bonus" then
            -- 标准化计数值（处理布尔值和数字）
            local actual_count = 0
            if type(count) == "boolean" then
                actual_count = count and 1 or 0
            elseif type(count) == "number" then
                actual_count = count
            end
            
            if skill.effects.attack_per_victory and actual_count > 0 then
                player.stats.attack = player.stats.attack + (skill.effects.attack_per_victory * actual_count)
            end
            if skill.effects.speed_per_victory and actual_count > 0 then
                player.stats.attack_speed = player.stats.attack_speed + (skill.effects.speed_per_victory * actual_count)
            end
            if skill.effects.heal_percent and (count == true or actual_count > 0) then
                local heal_amount = math.floor(player.stats.max_hp * skill.effects.heal_percent)
                player.stats.hp = math.min(player.stats.max_hp, player.stats.hp + heal_amount)
            end
            
            -- New victory bonus types
            if skill.effects.dodge_chance_per_victory and actual_count > 0 then
                local bonus = skill.effects.dodge_chance_per_victory * actual_count
                player.stats.evasion = (player.stats.evasion or 0) + bonus
            end
            
            if skill.effects.crit_chance_per_victory and actual_count > 0 then
                local bonus = skill.effects.crit_chance_per_victory * actual_count
                player.stats.crit_rate = (player.stats.crit_rate or 0) + bonus
            end
        end
    end
end

function SkillSystem.applyMonsterPassiveSkills(monster, passive_skill_ids)
    if not skills_data or not passive_skill_ids then return end
    
    -- Initialize monster skills table if not present
    if not monster.skills then
        monster.skills = {}
    end
    
    for _, skill_id in ipairs(passive_skill_ids) do
        local skill = nil
        for _, s in ipairs(skills_data.skills) do
            if s.id == skill_id then
                skill = s
                break
            end
        end
        
        if skill then
            if skill.type == "permanent_stat" then
                -- Apply permanent stat bonuses
                for stat, value in pairs(skill.effects) do
                    if stat == "attack" then
                        monster.attack = monster.attack + value
                    elseif stat == "defense" then
                        monster.defense = monster.defense + value
                    elseif stat == "hp" then
                        monster.hp = monster.hp + value
                        monster.max_hp = monster.max_hp + value
                    elseif stat == "attack_speed" then
                        monster.attack_speed = monster.attack_speed + value
                    elseif stat == "special_attack" then
                        monster.special_attack = monster.special_attack + value
                    elseif stat == "special_defense" then
                        monster.special_defense = monster.special_defense + value
                    elseif stat == "crit_rate" then
                        monster.crit_rate = (monster.crit_rate or 0) + value
                    elseif stat == "evasion" then
                        monster.evasion = (monster.evasion or 0) + value
                    end
                end
            elseif skill.type == "on_hit" or skill.type == "on_hit_received" or 
                   skill.type == "conditional" or skill.type == "chance_effect" or 
                   skill.type == "debuff" then
                -- Add skill to monster's skill list for processing during combat
                if skill.stackable then
                    monster.skills[skill_id] = (monster.skills[skill_id] or 0) + 1
                else
                    monster.skills[skill_id] = true
                end
            end
            -- Note: victory_bonus skills are not applicable to monsters since they don't level up
        end
    end
end

-- New effect calculation functions
function SkillSystem.calculateConditionalEffects(player)
    local speed_bonus = 0
    
    for skill_id, count in pairs(player.skills or {}) do
        local skill = SkillSystem.getSkillById(skill_id)
        if skill and skill.type == "conditional" then
            local actual_count = (type(count) == "number") and count or (count and 1 or 0)
            local hp_percent = player.stats.hp / player.stats.max_hp
            
            if skill.effects.hp_threshold_min and hp_percent >= skill.effects.hp_threshold_min then
                speed_bonus = speed_bonus + (skill.effects.attack_speed_bonus * actual_count)
            elseif skill.effects.hp_threshold_max and hp_percent <= skill.effects.hp_threshold_max then
                speed_bonus = speed_bonus + (skill.effects.attack_speed_bonus * actual_count)
            end
        end
    end
    
    return speed_bonus
end

-- Calculate additional damage from on-hit effects (separated from healing for proper flow)
function SkillSystem.calculateOnHitDamageBonus(attacker, defender, base_damage)
    if not attacker.skills then return 0 end
    
    local additional_damage = 0
    
    for skill_id, count in pairs(attacker.skills) do
        local skill = SkillSystem.getSkillById(skill_id)
        if skill and skill.type == "on_hit" then
            -- Poison damage
            if skill.effects.poison_damage_percent then
                local special_attack = attacker.special_attack or attacker.stats.special_attack
                additional_damage = additional_damage + (special_attack * skill.effects.poison_damage_percent)
            end
        elseif skill and skill.type == "chance_effect" then
            if love.math.random() < skill.effects.trigger_chance then
                local special_attack = attacker.special_attack or attacker.stats.special_attack
                additional_damage = additional_damage + (special_attack * skill.effects.bonus_damage_percent)
            end
        end
    end
    
    return additional_damage
end

-- Process healing effects after damage is applied
function SkillSystem.processOnHitHealingEffects(attacker, defender, damage_dealt)
    if not attacker.skills then return end
    
    local healing_amount = 0
    
    for skill_id, count in pairs(attacker.skills) do
        local skill = SkillSystem.getSkillById(skill_id)
        if skill and skill.type == "on_hit" then
            local actual_count = (type(count) == "number") and count or (count and 1 or 0)
            
            -- Healing per hit
            if skill.effects.heal_per_hit then
                healing_amount = healing_amount + (skill.effects.heal_per_hit * actual_count)
            end
            
            -- Lifesteal
            if skill.effects.lifesteal_percent then
                healing_amount = healing_amount + (damage_dealt * skill.effects.lifesteal_percent * actual_count)
            end
        end
    end
    
    -- Apply healing
    if healing_amount > 0 then
        local current_hp = attacker.hp or attacker.stats.hp
        local max_hp = attacker.max_hp or attacker.stats.max_hp
        
        if attacker.stats then
            attacker.stats.hp = math.min(max_hp, current_hp + healing_amount)
        else
            attacker.hp = math.min(max_hp, current_hp + healing_amount)
        end
    end
end

-- Legacy function kept for backward compatibility but now deprecated
function SkillSystem.processOnHitEffects(attacker, defender, damage_dealt)
    -- This function is deprecated - use calculateOnHitDamageBonus and processOnHitHealingEffects instead
    local additional_damage = SkillSystem.calculateOnHitDamageBonus(attacker, defender, damage_dealt)
    SkillSystem.processOnHitHealingEffects(attacker, defender, damage_dealt)
    return additional_damage
end

function SkillSystem.processOnHitReceivedEffects(attacker, defender, damage_dealt)
    if not defender.skills then return 0 end
    
    local reflect_damage = 0
    
    for skill_id, count in pairs(defender.skills) do
        local skill = SkillSystem.getSkillById(skill_id)
        if skill and skill.type == "on_hit_received" then
            local actual_count = (type(count) == "number") and count or (count and 1 or 0)
            
            if skill.effects.reflect_damage then
                reflect_damage = reflect_damage + (skill.effects.reflect_damage * actual_count)
            end
        end
    end
    
    return reflect_damage
end

-- Timer system for temporary effects
function SkillSystem.updateActiveEffects(target, dt)
    if not target.active_debuffs then
        target.active_debuffs = {}
    end
    
    for i = #target.active_debuffs, 1, -1 do
        local debuff = target.active_debuffs[i]
        debuff.remaining_time = debuff.remaining_time - dt
        
        if debuff.remaining_time <= 0 then
            -- Remove expired debuff
            table.remove(target.active_debuffs, i)
        end
    end
end

function SkillSystem.addDebuffToTarget(target, debuff_data)
    if not target.active_debuffs then
        target.active_debuffs = {}
    end
    
    -- Check for existing debuff of same type from same source
    local found_existing = false
    for _, existing_debuff in ipairs(target.active_debuffs) do
        if existing_debuff.type == debuff_data.type and existing_debuff.source_skill == debuff_data.source_skill then
            -- Refresh duration and add to value if stackable
            existing_debuff.remaining_time = debuff_data.duration
            existing_debuff.value = existing_debuff.value + debuff_data.value
            found_existing = true
            break
        end
    end
    
    if not found_existing then
        table.insert(target.active_debuffs, {
            type = debuff_data.type,
            value = debuff_data.value,
            duration = debuff_data.duration,
            remaining_time = debuff_data.duration,
            source_skill = debuff_data.source_skill
        })
    end
end

function SkillSystem.getActiveDebuffValue(target, debuff_type)
    if not target.active_debuffs then return 0 end
    
    local total_value = 0
    for _, debuff in ipairs(target.active_debuffs) do
        if debuff.type == debuff_type then
            total_value = total_value + debuff.value
        end
    end
    
    return total_value
end

function SkillSystem.applyDebuffs(attacker, defender)
    if not attacker.skills then return end
    
    for skill_id, count in pairs(attacker.skills) do
        local skill = SkillSystem.getSkillById(skill_id)
        if skill and skill.type == "debuff" then
            local actual_count = (type(count) == "number") and count or (count and 1 or 0)
            
            if skill.effects.speed_reduction and skill.effects.duration then
                SkillSystem.addDebuffToTarget(defender, {
                    type = "speed_reduction",
                    value = skill.effects.speed_reduction * actual_count,
                    duration = skill.effects.duration,
                    source_skill = skill_id
                })
            end
        end
    end
end

return SkillSystem