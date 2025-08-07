local SkillSelection = {}
local SkillSystem = require("systems.skill_system")
local SaveSystem = require("systems.save_system")
local FontSystem = require("systems.font_system")
local ChineseText = require("systems.chinese_text")

local skills = {}
local selected_skill = nil
local card_width = 180
local card_height = 250
local card_y = 150

function SkillSelection.load(data)
    skills = SkillSystem.getRandomSkills(3)
    selected_skill = nil
end

function SkillSelection.update(dt)
    if selected_skill then
        local player = SaveSystem.getPlayer()
        SkillSystem.applySkill(player, selected_skill.id)
        
        -- 每关开始前完全恢复HP
        player.stats.hp = player.stats.max_hp
        
        SaveSystem.save()
        local GameState = require("systems.game_state")
        GameState.switch("combat")
    end
end

function SkillSelection.draw()
    FontSystem.setFont()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(ChineseText.get("choose_skill"), 0, 50, 800, "center")
    
    local player = SaveSystem.getPlayer()
    love.graphics.printf(ChineseText.get("world_level", player.current_world, player.current_level), 0, 80, 800, "center")

    for i, skill in ipairs(skills) do
        local x = 100 + (i - 1) * 220
        
        -- Draw card background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", x, card_y, card_width, card_height)
        
        -- Determine border color and style based on stackability
        local border_color = {1, 1, 1, 1}  -- White for stackable
        local is_stackable = skill.stackable
        
        if not is_stackable then
            border_color = {1, 1, 0, 1}  -- Yellow for non-stackable
        end
        
        love.graphics.setColor(border_color)
        love.graphics.setLineWidth(2)
        
        -- Draw border (solid for stackable, dashed for non-stackable)
        if is_stackable then
            love.graphics.rectangle("line", x, card_y, card_width, card_height)
        else
            -- Draw dashed border for non-stackable skills
            SkillSelection.drawDashedRectangle(x, card_y, card_width, card_height)
        end
        
        -- Reset line width
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
        
        love.graphics.printf("[" .. i .. "] " .. skill.name, x + 10, card_y + 20, card_width - 20, "center")
        love.graphics.printf(skill.description, x + 10, card_y + 80, card_width - 20, "center")
        
        -- Show if skill is already owned
        local owned_count = player.skills[skill.id] or 0
        local is_owned = false
        
        -- 处理不同类型的技能拥有状态
        if type(owned_count) == "boolean" then
            is_owned = owned_count
            owned_count = is_owned and 1 or 0
        elseif type(owned_count) == "number" then
            is_owned = owned_count > 0
        end
        
        if is_owned then
            if skill.stackable and owned_count > 1 then
                love.graphics.printf(ChineseText.get("owned_count", owned_count), x + 10, card_y + 120, card_width - 20, "center")
            else
                love.graphics.printf(ChineseText.get("owned"), x + 10, card_y + 120, card_width - 20, "center")
            end
        end
    end
    
    love.graphics.printf(ChineseText.get("click_to_select"), 0, 450, 800, "center")
    
    -- Display current player stats
    love.graphics.printf(ChineseText.get("current_stats", 
        player.stats.attack, player.stats.defense, player.stats.attack_speed,
        player.stats.hp, player.stats.max_hp, player.victory_count), 0, 480, 800, "center")
end

function SkillSelection.mousepressed(x, y, button)
    if button == 1 then
        for i, skill in ipairs(skills) do
            local card_x = 100 + (i - 1) * 220
            if x >= card_x and x <= card_x + card_width and y >= card_y and y <= card_y + card_height then
                selected_skill = skill
                break
            end
        end
    end
end

function SkillSelection.keypressed(key)
    if key == "1" or key == "2" or key == "3" then
        local skill_index = tonumber(key)
        if skills[skill_index] then
            selected_skill = skills[skill_index]
        end
    end
end

function SkillSelection.drawDashedRectangle(x, y, width, height)
    local dash_length = 8
    local gap_length = 4
    local total_pattern = dash_length + gap_length
    
    -- Draw top edge
    for i = 0, width, total_pattern do
        local segment_width = math.min(dash_length, width - i)
        love.graphics.rectangle("fill", x + i, y, segment_width, 2)
    end
    
    -- Draw bottom edge
    for i = 0, width, total_pattern do
        local segment_width = math.min(dash_length, width - i)
        love.graphics.rectangle("fill", x + i, y + height - 2, segment_width, 2)
    end
    
    -- Draw left edge
    for i = 0, height, total_pattern do
        local segment_height = math.min(dash_length, height - i)
        love.graphics.rectangle("fill", x, y + i, 2, segment_height)
    end
    
    -- Draw right edge
    for i = 0, height, total_pattern do
        local segment_height = math.min(dash_length, height - i)
        love.graphics.rectangle("fill", x + width - 2, y + i, 2, segment_height)
    end
end

return SkillSelection