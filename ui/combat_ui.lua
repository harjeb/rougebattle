-- In ui/combat_ui.lua
local CombatUI = {}
local FontSystem = require("systems.font_system")
local ChineseText = require("systems.chinese_text")

function CombatUI.draw(player, monster, combat_log, combat_phase)
    FontSystem.setFont()
    -- Draw monster image or placeholder
    love.graphics.setColor(1, 1, 1, 1)
    if monster and monster.image then
        -- Draw the monster image centered above its HP bar
        local img_x = 450 + (300 - monster.image:getWidth()) / 2
        local img_y = 150
        love.graphics.draw(monster.image, img_x, img_y)
    else
        -- Draw a simple placeholder for the monster
        love.graphics.rectangle("line", 550, 150, 100, 80)
        love.graphics.printf("怪物", 550, 180, 100, "center")
    end

    -- HP Bars
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(ChineseText.get("player_hp", math.max(0, math.floor(player.stats.hp)), player.stats.max_hp), 50, 50, 300, "left")
    local monster_name_display = monster.name
    if monster.is_boss then
        monster_name_display = "BOSS: " .. monster.name
    end
    love.graphics.printf(ChineseText.get("monster_hp", monster_name_display, math.max(0, math.floor(monster.hp)), monster.max_hp), 450, 50, 300, "right")
    
    -- HP Bar visualization
    local player_hp_percent = math.max(0, player.stats.hp / player.stats.max_hp)
    local monster_hp_percent = math.max(0, monster.hp / monster.max_hp)
    
    love.graphics.setColor(0, 0, 0, 1) -- Black background
    love.graphics.rectangle("fill", 50, 80, 300, 20)
    love.graphics.rectangle("fill", 450, 80, 300, 20)
    
    love.graphics.setColor(1, 1, 1, 1) -- White fill
    love.graphics.rectangle("fill", 50, 80, 300 * player_hp_percent, 20)
    love.graphics.rectangle("fill", 450, 80, 300 * monster_hp_percent, 20)
    
    love.graphics.rectangle("line", 50, 80, 300, 20) -- Border
    love.graphics.rectangle("line", 450, 80, 300, 20) -- Border
    
    -- Level info
    love.graphics.printf(ChineseText.get("world_level", player.current_world, player.current_level), 0, 120, 800, "center")
    
    -- Attack speed and ultimate display
    love.graphics.setColor(1, 1, 1, 1)
    local player_ult = math.min(100, player.stats.ultimate_value or 0)
    local monster_ult = math.min(100, monster.ultimate_value or 0)
    local CombatEngine = require("systems.combat_engine")
    local player_attack_interval = CombatEngine.speedToInterval(player.stats.attack_speed)
    local monster_attack_interval = CombatEngine.speedToInterval(monster.attack_speed)
    
    -- Ultimate bars (3px high, golden gradient, 5px below HP bars)
    local ultimate_bar_y = 105 -- HP bars are at y=80 with height=20, so 80+20+5=105
    local player_ult_percent = math.max(0, player_ult / 100)
    local monster_ult_percent = math.max(0, monster_ult / 100)
    
    -- Player ultimate bar
    love.graphics.setColor(0.5, 0.4, 0.2, 1) -- Dark gold border
    love.graphics.rectangle("fill", 50, ultimate_bar_y, 300, 3)
    love.graphics.setColor(1, 0.85, 0, 1) -- Gold fill
    love.graphics.rectangle("fill", 50, ultimate_bar_y, 300 * player_ult_percent, 3)
    love.graphics.setColor(0.5, 0.4, 0.2, 1) -- Dark gold border
    love.graphics.rectangle("line", 50, ultimate_bar_y, 300, 3)
    
    -- Monster ultimate bar
    love.graphics.setColor(0.5, 0.4, 0.2, 1) -- Dark gold border
    love.graphics.rectangle("fill", 450, ultimate_bar_y, 300, 3)
    love.graphics.setColor(1, 0.85, 0, 1) -- Gold fill
    love.graphics.rectangle("fill", 450, ultimate_bar_y, 300 * monster_ult_percent, 3)
    love.graphics.setColor(0.5, 0.4, 0.2, 1) -- Dark gold border
    love.graphics.rectangle("line", 450, ultimate_bar_y, 300, 3)
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    
    love.graphics.printf(string.format("奥义: %d/100 (%.3fs/次)", player_ult, player_attack_interval), 50, 113, 300, "left")
    love.graphics.printf(string.format("奥义: %d/100 (%.3fs/次)", monster_ult, monster_attack_interval), 450, 113, 300, "right")
    
    -- Combat log
    local log_start_y = 200
    local log_spacing = 25
    local max_log_lines = 12
    local start_index = math.max(1, #combat_log - max_log_lines + 1)

    for i = start_index, #combat_log do
        love.graphics.printf(combat_log[i], 50, log_start_y + (i - start_index) * log_spacing, 700, "left")
    end

    -- Combat Phase text
    if combat_phase == "victory" then
        love.graphics.setColor(0, 1, 0, 1) -- Green for victory
        love.graphics.printf(ChineseText.get("victory"), 0, 480, 800, "center")
    elseif combat_phase == "defeat" then
        love.graphics.setColor(1, 0, 0, 1) -- Red for defeat
        love.graphics.printf(ChineseText.get("defeat"), 0, 480, 800, "center")
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

return CombatUI