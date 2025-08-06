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

function SkillSystem.applySkill(player, skill_id)
    if not skills_data then return end
    
    local skill = nil
    for _, s in ipairs(skills_data.skills) do
        if s.id == skill_id then
            skill = s
            break
        end
    end
    
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
    end
end

function SkillSystem.applyVictoryBonuses(player)
    if not skills_data then return end
    
    for skill_id, count in pairs(player.skills) do
        local skill = nil
        for _, s in ipairs(skills_data.skills) do
            if s.id == skill_id then
                skill = s
                break
            end
        end
        
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
        end
    end
end

function SkillSystem.applyMonsterPassiveSkills(monster, passive_skill_ids)
    if not skills_data or not passive_skill_ids then return end
    
    for _, skill_id in ipairs(passive_skill_ids) do
        local skill = nil
        for _, s in ipairs(skills_data.skills) do
            if s.id == skill_id then
                skill = s
                break
            end
        end
        
        if skill and skill.type == "permanent_stat" then
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
                end
            end
        end
    end
end

return SkillSystem