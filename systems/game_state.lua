local GameState = {}

local states = {
    menu = require("states.menu"),
    skill_selection = require("states.skill_selection"),
    combat = require("states.combat"),
    game_over = require("states.game_over")
}

local current_state = "menu"
local state_data = {}

function GameState.load()
    if states[current_state].load then
        states[current_state].load(state_data)
    end
end

function GameState.switch(new_state, data)
    current_state = new_state
    state_data = data or {}
    if states[current_state].load then
        states[current_state].load(state_data)
    end
end

function GameState.update(dt)
    if states[current_state].update then
        states[current_state].update(dt)
    end
end

function GameState.draw()
    if states[current_state].draw then
        states[current_state].draw()
    end
end

function GameState.keypressed(key)
    if states[current_state].keypressed then
        states[current_state].keypressed(key)
    end
end

function GameState.mousepressed(x, y, button)
    if states[current_state].mousepressed then
        states[current_state].mousepressed(x, y, button)
    end
end

return GameState