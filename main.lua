local GameState = require("systems.game_state")
local SaveSystem = require("systems.save_system")
local SkillSystem = require("systems.skill_system")
local MonsterSystem = require("systems.monster_system")
local FontSystem = require("systems.font_system")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    FontSystem.load()
    FontSystem.setFont()
    SaveSystem.load()
    SkillSystem.load()
    MonsterSystem.load()
    GameState.load()
end

function love.update(dt)
    GameState.update(dt)
end

function love.draw()
    GameState.draw()
end

function love.keypressed(key)
    GameState.keypressed(key)
end

function love.mousepressed(x, y, button)
    GameState.mousepressed(x, y, button)
end