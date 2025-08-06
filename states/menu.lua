local Menu = {}
local FontSystem = require("systems.font_system")
local ChineseText = require("systems.chinese_text")

local start_button = {x = 300, y = 250, width = 200, height = 80}
local reset_button = {x = 300, y = 340, width = 200, height = 50}
local reset_confirm = false

function Menu.draw()
    FontSystem.setFont()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Game title
    love.graphics.printf(ChineseText.get("game_title"), 0, 100, 800, "center")
    love.graphics.printf(ChineseText.get("game_subtitle"), 0, 130, 800, "center")
    
    -- Instructions
    love.graphics.printf("穿越5个世界，挑战250个关卡", 0, 180, 800, "center")
    love.graphics.printf("战斗间隙选择技能强化", 0, 200, 800, "center") 
    love.graphics.printf("每个世界第50关为BOSS战", 0, 220, 800, "center")
    
    -- Start button
    love.graphics.rectangle("line", start_button.x, start_button.y, start_button.width, start_button.height)
    love.graphics.printf(ChineseText.get("start_game"), 0, 275, 800, "center")
    
    -- Reset button
    love.graphics.setColor(1, 0.5, 0.5, 1) -- Light red color
    love.graphics.rectangle("line", reset_button.x, reset_button.y, reset_button.width, reset_button.height)
    love.graphics.setColor(1, 1, 1, 1)
    if reset_confirm then
        love.graphics.printf("确认重置？", 0, 355, 800, "center")
    else
        love.graphics.printf("重置游戏", 0, 355, 800, "center")
    end
    
    -- Controls hint
    love.graphics.printf(ChineseText.get("start_hint"), 0, 410, 800, "center")
    
    -- Control hints (optional)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("按 'L' 键切换中英文 | 按 'Delete' 键快速重置", 0, 480, 800, "center")
    love.graphics.printf("每关开始时生命值自动恢复满血", 0, 500, 800, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu.mousepressed(x, y, button)
    if button == 1 then
        -- Start button
        if x > start_button.x and x < start_button.x + start_button.width and
           y > start_button.y and y < start_button.y + start_button.height then
            -- 确保开始游戏时HP满血
            local SaveSystem = require("systems.save_system")
            local player = SaveSystem.getPlayer()
            player.stats.hp = player.stats.max_hp
            SaveSystem.save()
            
            local GameState = require("systems.game_state")
            GameState.switch("skill_selection")
        -- Reset button
        elseif x > reset_button.x and x < reset_button.x + reset_button.width and
               y > reset_button.y and y < reset_button.y + reset_button.height then
            if reset_confirm then
                -- 确认重置
                local SaveSystem = require("systems.save_system")
                SaveSystem.createNewGame()
                SaveSystem.save()
                reset_confirm = false
            else
                -- 第一次点击，显示确认
                reset_confirm = true
            end
        else
            -- 点击其他地方取消重置确认
            reset_confirm = false
        end
    end
end

function Menu.keypressed(key)
    if key == "space" or key == "return" then
        -- 确保开始游戏时HP满血
        local SaveSystem = require("systems.save_system")
        local player = SaveSystem.getPlayer()
        player.stats.hp = player.stats.max_hp
        SaveSystem.save()
        
        local GameState = require("systems.game_state")
        GameState.switch("skill_selection")
    elseif key == "l" then
        -- 切换语言
        ChineseText.setChinese(not ChineseText.isChinese())
    elseif key == "r" then
        -- 重新加载字体
        FontSystem.reload()
    elseif key == "delete" then
        -- Delete键重置游戏
        if reset_confirm then
            local SaveSystem = require("systems.save_system")
            SaveSystem.createNewGame()
            SaveSystem.save()
            reset_confirm = false
        else
            reset_confirm = true
        end
    elseif key == "escape" then
        -- Escape键取消重置
        reset_confirm = false
    end
end

return Menu