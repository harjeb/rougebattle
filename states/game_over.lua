local GameOver = {}
local SaveSystem = require("systems.save_system")
local FontSystem = require("systems.font_system")
local ChineseText = require("systems.chinese_text")

local is_victory = false

function GameOver.load(data)
    is_victory = data.victory
end

function GameOver.draw()
    FontSystem.setFont()
    love.graphics.setColor(1, 1, 1, 1)
    if is_victory then
        love.graphics.printf(ChineseText.get("congratulations"), 0, 250, 800, "center")
        love.graphics.printf(ChineseText.get("all_worlds_conquered"), 0, 280, 800, "center")
    else
        love.graphics.printf(ChineseText.get("game_over"), 0, 250, 800, "center")
        love.graphics.printf(ChineseText.get("retry_world"), 0, 280, 800, "center")
    end
    love.graphics.printf(ChineseText.get("return_to_menu"), 0, 320, 800, "center")
end

function GameOver.mousepressed(x, y, button)
    if button == 1 then
        -- On defeat, the world is already reset. On victory, we can reset the whole game.
        if is_victory then
             SaveSystem.createNewGame()
             SaveSystem.save()
        end
        local GameState = require("systems.game_state")
        GameState.switch("menu")
    end
end

return GameOver