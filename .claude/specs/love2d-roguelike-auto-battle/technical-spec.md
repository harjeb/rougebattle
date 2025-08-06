# Love2D Roguelike Auto-Battle Game - Technical Specification

## Problem Statement
- **Business Issue**: Need an engaging roguelike auto-battle game with skill-based progression and black/white pixel art aesthetics
- **Current State**: Empty project requiring complete Love2D implementation from scratch
- **Expected Outcome**: Fully functional 250-level auto-battle game with persistent progression and JSON-configurable skills

## Solution Overview
- **Approach**: Create a turn-based auto-battle system using Love2D with modular architecture for easy skill and monster configuration
- **Core Changes**: Implement complete game from main.lua with separate modules for combat, skills, UI, and data management
- **Success Criteria**: Player can progress through 5 worlds × 50 levels with skill selection, combat automation, and progress persistence

## Technical Implementation

### File Structure
```
rougebattle/
├── main.lua                          # Love2D entry point and game loop
├── conf.lua                          # Love2D configuration
├── states/
│   ├── menu.lua                      # Main menu state
│   ├── skill_selection.lua           # Skill selection interface
│   ├── combat.lua                    # Auto-battle combat state  
│   └── game_over.lua                 # Game over/restart state
├── systems/
│   ├── game_state.lua                # State management system
│   ├── combat_engine.lua             # Combat calculations and logic
│   ├── skill_system.lua              # Skill loading and application
│   ├── monster_system.lua            # Monster generation and scaling
│   └── save_system.lua               # Progress persistence
├── ui/
│   ├── skill_cards.lua               # Card-based skill selection UI
│   ├── combat_ui.lua                 # HP bars and combat display
│   └── pixel_font.lua                # Black/white pixel font rendering
├── data/
│   ├── skills.json                   # Skill definitions (user-editable)
│   ├── monsters.json                 # Monster base stats and abilities
│   └── save_data.json                # Player progress (auto-generated)
└── assets/
    └── pixel_sprites/                # Black/white 1x1 pixel assets
        ├── ui_elements.png
        └── borders.png
```

### Database/Data Structure Changes

#### skills.json Schema
```json
{
  "skills": [
    {
      "id": "fixed_attack",
      "name": "Fixed Attack Boost",
      "description": "+10 Attack permanently",
      "type": "permanent_stat",
      "effects": {
        "attack": 10
      },
      "stackable": true
    },
    {
      "id": "fixed_defense", 
      "name": "Fixed Defense Boost",
      "description": "+5 Defense permanently",
      "type": "permanent_stat",
      "effects": {
        "defense": 5
      },
      "stackable": true
    },
    {
      "id": "victory_attack",
      "name": "Victory Attack Stack",
      "description": "+2 Attack per victory",
      "type": "victory_bonus",
      "effects": {
        "attack_per_victory": 2
      },
      "stackable": true
    },
    {
      "id": "victory_speed",
      "name": "Victory Speed Stack", 
      "description": "+1 Attack Speed per victory",
      "type": "victory_bonus",
      "effects": {
        "speed_per_victory": 1
      },
      "stackable": true
    },
    {
      "id": "victory_heal",
      "name": "Victory Heal",
      "description": "+20% max HP healing after victory",
      "type": "victory_bonus", 
      "effects": {
        "heal_percent": 0.2
      },
      "stackable": false
    }
  ]
}
```

#### monsters.json Schema
```json
{
  "base_monsters": [
    {
      "id": "goblin",
      "name": "Goblin",
      "base_stats": {
        "hp": 50,
        "attack": 12,
        "defense": 5,
        "special_attack": 8,
        "special_defense": 3,
        "attack_speed": 10,
        "crit_rate": 0.1,
        "ultimate_value": 0
      }
    }
  ],
  "scaling": {
    "hp_per_level": 8,
    "attack_per_level": 2,
    "defense_per_level": 1,
    "speed_per_level": 0.5
  },
  "boss_abilities": [
    {
      "world": 1,
      "ability": "double_attack",
      "description": "Attacks twice per turn"
    },
    {
      "world": 2, 
      "ability": "regeneration",
      "description": "Heals 10% HP each turn"
    }
  ]
}
```

#### save_data.json Schema
```json
{
  "player": {
    "current_world": 1,
    "current_level": 1,
    "stats": {
      "hp": 100,
      "max_hp": 100,
      "attack": 20,
      "defense": 10,
      "special_attack": 15,
      "special_defense": 8,
      "attack_speed": 15,
      "crit_rate": 0.05,
      "ultimate_value": 0
    },
    "skills": {
      "fixed_attack": 0,
      "fixed_defense": 0,
      "victory_attack": 0,
      "victory_speed": 0,
      "victory_heal": false
    },
    "victory_count": 0
  }
}
```

### Core System Implementation

#### conf.lua Configuration
```lua
function love.conf(t)
    t.title = "Roguelike Auto Battle"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.console = false
end
```

#### main.lua Entry Point
```lua
local GameState = require("systems.game_state")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
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
```

### Code Changes

#### systems/game_state.lua - State Management
```lua
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
    states[current_state].update(dt)
end

function GameState.draw()
    states[current_state].draw()
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
```

#### systems/combat_engine.lua - Combat Calculations
```lua
local CombatEngine = {}

function CombatEngine.calculateDamage(attacker, defender)
    -- 浮动比例 = random(0.9, 1.1)
    local damage_variance = love.math.random() * 0.2 + 0.9  -- 0.9 to 1.1
    
    -- 基础伤害 = 攻击力 * 浮动比例
    local base_damage = attacker.attack * damage_variance
    
    -- 减伤率 = 防御力 / (防御力 + 100)
    local damage_reduction = defender.defense / (defender.defense + 100)
    
    -- 防御后伤害 = 基础伤害 * (1 - 减伤率)
    local after_defense_damage = base_damage * (1 - damage_reduction)
    
    -- 是否暴击 = random(0, 1) < 暴击率
    local is_critical = love.math.random() < attacker.crit_rate
    
    -- 最终伤害 = 是否暴击 ? 防御后伤害 * 1.5 : 防御后伤害
    local final_damage = is_critical and (after_defense_damage * 1.5) or after_defense_damage
    
    return math.floor(final_damage), is_critical
end

function CombatEngine.calculateUltimateDamage(attacker, defender)
    local base_damage = (attacker.attack + attacker.special_attack)
    local damage_reduction = defender.special_defense / (defender.special_defense + 100)
    local final_damage = base_damage * (1 - damage_reduction)
    return math.floor(final_damage)
end

function CombatEngine.determineTurnOrder(player, monster)
    return player.attack_speed >= monster.attack_speed and "player" or "monster"
end

function CombatEngine.incrementUltimate(character)
    character.ultimate_value = character.ultimate_value + 2
    return character.ultimate_value >= 100
end

function CombatEngine.resetUltimate(character)
    character.ultimate_value = 0
end

return CombatEngine
```

#### systems/skill_system.lua - Skill Management
```lua
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
            if skill.effects.attack_per_victory and count and count > 0 then
                player.stats.attack = player.stats.attack + (skill.effects.attack_per_victory * count)
            end
            if skill.effects.speed_per_victory and count and count > 0 then
                player.stats.attack_speed = player.stats.attack_speed + (skill.effects.speed_per_victory * count)
            end
            if skill.effects.heal_percent and count then
                local heal_amount = math.floor(player.stats.max_hp * skill.effects.heal_percent)
                player.stats.hp = math.min(player.stats.max_hp, player.stats.hp + heal_amount)
            end
        end
    end
end

return SkillSystem
```

#### systems/monster_system.lua - Monster Generation
```lua
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
    
    local base_monster = monster_data.base_monsters[1]  -- Use first monster as base
    local scaling = monster_data.scaling
    
    local total_level = (world - 1) * 50 + level
    
    local monster = {
        name = base_monster.name,
        hp = base_monster.base_stats.hp + (scaling.hp_per_level * total_level),
        max_hp = base_monster.base_stats.hp + (scaling.hp_per_level * total_level),
        attack = base_monster.base_stats.attack + (scaling.attack_per_level * total_level),
        defense = base_monster.base_stats.defense + (scaling.defense_per_level * total_level),
        special_attack = base_monster.base_stats.special_attack + (scaling.attack_per_level * total_level),
        special_defense = base_monster.base_stats.special_defense + (scaling.defense_per_level * total_level),
        attack_speed = base_monster.base_stats.attack_speed + (scaling.speed_per_level * total_level),
        crit_rate = base_monster.base_stats.crit_rate,
        ultimate_value = 0,
        is_boss = (level == 50),
        boss_ability = nil
    }
    
    -- Add boss abilities for x-50 levels
    if monster.is_boss then
        for _, boss_data in ipairs(monster_data.boss_abilities) do
            if boss_data.world == world then
                monster.boss_ability = boss_data.ability
                monster.name = "Boss " .. monster.name
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
        return "double_attack"
    elseif monster.boss_ability == "regeneration" then
        local heal_amount = math.floor(monster.max_hp * 0.1)
        monster.hp = math.min(monster.max_hp, monster.hp + heal_amount)
        return "regeneration"
    end
end

return MonsterSystem
```

### UI Implementation

#### states/skill_selection.lua - Skill Selection Interface
```lua
local SkillSelection = {}
local GameState = require("systems.game_state")
local SkillSystem = require("systems.skill_system")
local SaveSystem = require("systems.save_system")

local skills = {}
local selected_skill = nil

function SkillSelection.load(data)
    skills = SkillSystem.getRandomSkills(3)
    selected_skill = nil
end

function SkillSelection.update(dt)
    -- Auto-advance if skill selected
    if selected_skill then
        SkillSystem.applySkill(SaveSystem.getPlayer(), selected_skill.id)
        SaveSystem.save()
        GameState.switch("combat")
    end
end

function SkillSelection.draw()
    love.graphics.setColor(1, 1, 1, 1)  -- White color
    love.graphics.printf("Choose a Skill:", 0, 50, 800, "center")
    
    -- Draw skill cards
    for i, skill in ipairs(skills) do
        local x = 100 + (i - 1) * 200
        local y = 150
        local width = 180
        local height = 300
        
        -- Card background
        love.graphics.setColor(0, 0, 0, 1)  -- Black background
        love.graphics.rectangle("fill", x, y, width, height)
        love.graphics.setColor(1, 1, 1, 1)  -- White border
        love.graphics.rectangle("line", x, y, width, height)
        
        -- Skill text
        love.graphics.printf(skill.name, x + 10, y + 20, width - 20, "center")
        love.graphics.printf(skill.description, x + 10, y + 80, width - 20, "center")
    end
    
    love.graphics.printf("Click a card to select", 0, 500, 800, "center")
end

function SkillSelection.mousepressed(x, y, button)
    if button == 1 then  -- Left click
        for i, skill in ipairs(skills) do
            local card_x = 100 + (i - 1) * 200
            local card_y = 150
            local width = 180
            local height = 300
            
            if x >= card_x and x <= card_x + width and y >= card_y and y <= card_y + height then
                selected_skill = skill
                break
            end
        end
    end
end

return SkillSelection
```

#### states/combat.lua - Auto-Battle Combat State
```lua
local Combat = {}
local GameState = require("systems.game_state")
local CombatEngine = require("systems.combat_engine")
local MonsterSystem = require("systems.monster_system")
local SkillSystem = require("systems.skill_system")
local SaveSystem = require("systems.save_system")

local player = nil
local monster = nil
local combat_log = {}
local combat_timer = 0
local combat_phase = "start"  -- start, player_turn, monster_turn, victory, defeat
local turn_delay = 1.0

function Combat.load(data)
    player = SaveSystem.getPlayer()
    monster = MonsterSystem.generateMonster(player.current_world, player.current_level)
    combat_log = {}
    combat_timer = 0
    combat_phase = "start"
end

function Combat.update(dt)
    combat_timer = combat_timer + dt
    
    if combat_phase == "start" and combat_timer > 1.0 then
        local first_turn = CombatEngine.determineTurnOrder(player.stats, monster)
        combat_phase = first_turn == "player" and "player_turn" or "monster_turn"
        combat_timer = 0
        table.insert(combat_log, "Combat begins!")
    
    elseif combat_phase == "player_turn" and combat_timer > turn_delay then
        Combat.executePlayerTurn()
        combat_timer = 0
        
    elseif combat_phase == "monster_turn" and combat_timer > turn_delay then
        Combat.executeMonsterTurn()
        combat_timer = 0
        
    elseif combat_phase == "victory" and combat_timer > 2.0 then
        Combat.handleVictory()
        
    elseif combat_phase == "defeat" and combat_timer > 2.0 then
        Combat.handleDefeat()
    end
end

function Combat.executePlayerTurn()
    local can_ultimate = CombatEngine.incrementUltimate(player.stats)
    
    if can_ultimate then
        local damage = CombatEngine.calculateUltimateDamage(player.stats, monster)
        monster.hp = monster.hp - damage
        CombatEngine.resetUltimate(player.stats)
        table.insert(combat_log, "Player uses ULTIMATE! " .. damage .. " damage!")
    else
        local damage, is_crit = CombatEngine.calculateDamage(player.stats, monster)
        monster.hp = monster.hp - damage
        local crit_text = is_crit and " (CRITICAL!)" or ""
        table.insert(combat_log, "Player attacks for " .. damage .. " damage!" .. crit_text)
    end
    
    if monster.hp <= 0 then
        combat_phase = "victory"
    else
        combat_phase = "monster_turn"
    end
end

function Combat.executeMonsterTurn()
    -- Apply boss ability
    if monster.boss_ability == "regeneration" then
        MonsterSystem.applyBossAbility(monster, player.stats)
        table.insert(combat_log, "Boss regenerates health!")
    end
    
    local can_ultimate = CombatEngine.incrementUltimate(monster)
    local attack_count = (monster.boss_ability == "double_attack") and 2 or 1
    
    for i = 1, attack_count do
        if can_ultimate and i == attack_count then
            local damage = CombatEngine.calculateUltimateDamage(monster, player.stats)
            player.stats.hp = player.stats.hp - damage
            CombatEngine.resetUltimate(monster)
            table.insert(combat_log, "Monster uses ULTIMATE! " .. damage .. " damage!")
        else
            local damage, is_crit = CombatEngine.calculateDamage(monster, player.stats)
            player.stats.hp = player.stats.hp - damage
            local crit_text = is_crit and " (CRITICAL!)" or ""
            table.insert(combat_log, "Monster attacks for " .. damage .. " damage!" .. crit_text)
        end
    end
    
    if player.stats.hp <= 0 then
        combat_phase = "defeat"
    else
        combat_phase = "player_turn"
    end
end

function Combat.handleVictory()
    player.victory_count = player.victory_count + 1
    SkillSystem.applyVictoryBonuses(player)
    
    player.current_level = player.current_level + 1
    if player.current_level > 50 then
        player.current_world = player.current_world + 1
        player.current_level = 1
    end
    
    if player.current_world > 5 then
        -- Game completed!
        GameState.switch("game_over", {victory = true})
    else
        SaveSystem.save()
        GameState.switch("skill_selection")
    end
end

function Combat.handleDefeat()
    player.current_level = 1  -- Restart current world
    player.stats.hp = player.stats.max_hp  -- Full heal
    SaveSystem.save()
    GameState.switch("skill_selection")
end

function Combat.draw()
    -- HP Bars
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Player HP: " .. player.stats.hp .. "/" .. player.stats.max_hp, 50, 50, 300, "left")
    love.graphics.printf("Monster HP: " .. monster.hp .. "/" .. monster.max_hp, 450, 50, 300, "right")
    
    -- HP Bar visualization
    local player_hp_percent = player.stats.hp / player.stats.max_hp
    local monster_hp_percent = monster.hp / monster.max_hp
    
    love.graphics.setColor(0, 0, 0, 1)  -- Black background
    love.graphics.rectangle("fill", 50, 80, 300, 20)
    love.graphics.rectangle("fill", 450, 80, 300, 20)
    
    love.graphics.setColor(1, 1, 1, 1)  -- White fill
    love.graphics.rectangle("fill", 50, 80, 300 * player_hp_percent, 20)
    love.graphics.rectangle("fill", 450, 80, 300 * monster_hp_percent, 20)
    
    love.graphics.rectangle("line", 50, 80, 300, 20)  -- Border
    love.graphics.rectangle("line", 450, 80, 300, 20)  -- Border
    
    -- Level info
    love.graphics.printf("World " .. player.current_world .. "-" .. player.current_level, 0, 120, 800, "center")
    
    -- Combat log
    for i = math.max(1, #combat_log - 10), #combat_log do
        love.graphics.printf(combat_log[i], 50, 200 + (i - math.max(1, #combat_log - 10)) * 25, 700, "left")
    end
end

return Combat
```

### API Changes
No external APIs required - all data is local JSON files.

### Configuration Changes

#### systems/save_system.lua - Progress Persistence
```lua
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
            attack = 20,
            defense = 10,
            special_attack = 15,
            special_defense = 8,
            attack_speed = 15,
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
```

## Implementation Sequence

### Phase 1: Core Framework Setup
1. **Create conf.lua** - Love2D window configuration (800x600, nearest filtering)
2. **Create main.lua** - Entry point with basic game loop delegation
3. **Create systems/game_state.lua** - State management system for menu/skill/combat/gameover
4. **Create basic states/menu.lua** - Simple start menu with "Start Game" button
5. **Set up basic file structure** - All required directories and placeholder files

### Phase 2: Data Systems Implementation  
1. **Create data/skills.json** - Complete skill definitions with all 5 skill types
2. **Create data/monsters.json** - Monster base stats and scaling formulas
3. **Create systems/save_system.lua** - JSON-based save/load functionality
4. **Create systems/skill_system.lua** - Skill loading, random selection, and application
5. **Create systems/monster_system.lua** - Monster generation with level scaling

### Phase 3: Combat Engine Implementation
1. **Create systems/combat_engine.lua** - Damage calculation with exact formula implementation
2. **Create states/combat.lua** - Auto-battle state with turn management and boss abilities
3. **Create states/skill_selection.lua** - Card-based UI for skill selection
4. **Create states/game_over.lua** - Victory/defeat handling and world restart logic
5. **Implement ultimate system** - +2 per attack, 100-point threshold trigger

### Phase 4: UI and Polish
1. **Create ui/combat_ui.lua** - HP bars, level display, combat log visualization
2. **Create ui/skill_cards.lua** - Black/white card-based skill selection interface
3. **Create ui/pixel_font.lua** - Pixel-perfect font rendering system
4. **Implement black/white pixel art styling** - All UI elements in monochrome theme
5. **Add victory bonuses application** - Heal, attack stacking, speed stacking after wins

## Validation Plan

### Unit Tests
- **Combat Engine Tests**: Verify damage formula accuracy with known inputs/outputs
- **Skill System Tests**: Confirm skill application and stacking mechanics
- **Monster Scaling Tests**: Validate monster stat progression across 250 levels
- **Save System Tests**: Ensure progress persistence across game sessions

### Integration Tests
- **Complete Game Loop**: Player can select skills → auto-battle → advance levels
- **Boss Battle Flow**: Special abilities trigger correctly at x-50 levels  
- **World Restart Logic**: Death properly resets to world beginning with stats preserved
- **Victory Bonuses**: Cumulative bonuses apply correctly after multiple victories

### Business Logic Verification
- **250 Level Progression**: Player can theoretically reach 5-50 with optimal skill selection
- **Skill Balance**: All 5 skill types provide meaningful strategic choices
- **Monster Difficulty Curve**: Provides challenge while remaining beatable with good skill choices
- **Progress Persistence**: Save system maintains player advancement across sessions
- **JSON Configuration**: Skills and monsters easily modifiable through JSON editing

Each phase should be independently testable and deployable, allowing for incremental development and validation of core systems before moving to UI polish and final integration.