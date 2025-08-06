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
            ultimate_value = 0
        },
        skills = {},
        victory_count = 0
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