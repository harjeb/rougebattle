local SaveSystem = {}
local json = require("libraries.json")

local player_data = nil
local save_file = "data/save_data.json"

function SaveSystem.load()
    local file = io.open(save_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content)
        player_data = data.player
        
        -- 升级旧存档的攻击速度系统
        if player_data.stats.attack_speed and player_data.stats.attack_speed < 30 then
            -- 旧的速度系统，需要升级
            player_data.stats.attack_speed = 50  -- 重置为新系统的默认值
        end
        
        -- 升级旧存档添加新的技能系统字段 - using standardized field names
        if not player_data.stats.evasion then
            player_data.stats.evasion = 0.05  -- Default 5% evasion
        end
        if not player_data.stats.crit_rate then
            player_data.stats.crit_rate = 0.05  -- Default 5% crit rate
        end
        
        -- Migrate old field names to standardized ones
        if player_data.stats.dodge_chance then
            player_data.stats.evasion = (player_data.stats.evasion or 0) + player_data.stats.dodge_chance
            player_data.stats.dodge_chance = nil  -- Remove old field
        end
        if player_data.stats.crit_chance then
            player_data.stats.crit_rate = (player_data.stats.crit_rate or 0) + player_data.stats.crit_chance
            player_data.stats.crit_chance = nil  -- Remove old field
        end
        if not player_data.active_effects then
            player_data.active_effects = {
                debuffs_applied_to_enemy = {}
            }
        end
    else
        SaveSystem.createNewGame()
    end
end

function SaveSystem.createNewGame()
    player_data = {
        current_world = 1,
        current_level = 1,
        stats = {
            hp = 100,
            max_hp = 100,
            attack = 10,
            defense = 10,
            special_attack = 15,
            special_defense = 8,
            attack_speed = 50,  -- 50速度 = 1.0秒间隔
            crit_rate = 0.05,
            evasion = 0.05,     -- 闪避率（5%）
            ultimate_value = 0,
            -- Note: evasion and crit_rate are already defined above with proper defaults
        },
        skills = {},
        victory_count = 0,
        active_effects = {
            debuffs_applied_to_enemy = {}
        }
    }
end

function SaveSystem.save()
    local save_data = {
        player = player_data
    }
    
    local file = io.open(save_file, "w")
    if file then
        file:write(json.encode(save_data))
        file:close()
    end
end

function SaveSystem.getPlayer()
    return player_data
end

return SaveSystem