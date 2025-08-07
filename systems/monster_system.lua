local MonsterSystem = {}
local json = require("libraries.json")

local monster_data = nil

function MonsterSystem.load()
    local file = io.open("data/monsters.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        monster_data = json.decode(content)
    end
end

function MonsterSystem.generateMonster(world, level)
    if not monster_data then return nil end
    
    -- Correctly access the first monster from the array
    local base_monster = monster_data.base_monsters[1]
    if not base_monster then return nil end -- Safety check

    local scaling = monster_data.scaling
    
    local total_level = (world - 1) * 50 + level
    
    local monster = {
        name = base_monster.name,
        image = love.filesystem.getInfo(base_monster.image) and love.graphics.newImage(base_monster.image) or nil,
        hp = base_monster.base_stats.hp + (scaling.hp_per_level * total_level),
        max_hp = base_monster.base_stats.hp + (scaling.hp_per_level * total_level),
        attack = base_monster.base_stats.attack + (scaling.attack_per_level * total_level),
        defense = base_monster.base_stats.defense + (scaling.defense_per_level * total_level),
        special_attack = base_monster.base_stats.special_attack + (scaling.attack_per_level * total_level),
        special_defense = base_monster.base_stats.special_defense + (scaling.defense_per_level * total_level),
        attack_speed = base_monster.base_stats.attack_speed + (scaling.speed_per_level * total_level),
        crit_rate = base_monster.base_stats.crit_rate,
        evasion = base_monster.base_stats.evasion + (scaling.evasion_per_level or 0 * total_level),
        ultimate_value = 0,
        is_boss = (level == 50),
        boss_ability = nil
    }
    
    -- Apply passive skills if they exist
    if base_monster.passive_skills then
        local SkillSystem = require("systems.skill_system")
        SkillSystem.applyMonsterPassiveSkills(monster, base_monster.passive_skills)
    end
    
    -- Add boss abilities for x-50 levels
    if monster.is_boss then
        for _, boss_data in ipairs(monster_data.boss_abilities) do
            if boss_data.world == world then
                monster.boss_ability = boss_data.ability
                monster.name = "Boss " .. monster.name
                
                -- 双倍攻击BOSS的攻击速度翻倍
                if monster.boss_ability == "double_attack" then
                    monster.attack_speed = monster.attack_speed * 2
                end
                
                break
            end
        end
    end
    
    return monster
end

function MonsterSystem.applyBossAbility(monster, player)
    if not monster.boss_ability then return end
    
    if monster.boss_ability == "double_attack" then
        -- Implementation handled in combat state
        return 0
    elseif monster.boss_ability == "regeneration" then
        local heal_amount = math.floor(monster.max_hp * 0.1)
        monster.hp = math.min(monster.max_hp, monster.hp + heal_amount)
        return heal_amount
    end
    return 0
end

return MonsterSystem