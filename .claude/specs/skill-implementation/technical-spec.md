# Technical Specification: Skill System Enhancement

## Problem Statement
- **Business Issue**: Current skill system only supports permanent stat bonuses and victory bonuses, limiting gameplay depth and tactical variety
- **Current State**: Skills are limited to "permanent_stat" and "victory_bonus" types with basic stat modifications (attack, defense, hp, attack_speed, special_attack, special_defense)
- **Expected Outcome**: Expanded skill system with 10 new skills featuring dynamic effects: dodge/crit bonuses, on-hit effects, conditional buffs, chance-based effects, lifesteal, and enemy debuffs with timer system

## Solution Overview
- **Approach**: Extend existing skill system architecture with new effect types while maintaining backward compatibility with current JSON data structure and skill application flow
- **Core Changes**: Add new effect types to SkillSystem, extend combat engine for skill effect processing, implement timer system for temporary effects, enhance player stats with new fields
- **Success Criteria**: All 10 skills function correctly with proper stacking behavior, UI differentiation, and integration with existing combat system

## Technical Implementation

### Database Changes
- **Tables to Modify**: None (file-based JSON data structure)
- **New Tables**: None required
- **Migration Scripts**: Not applicable (JSON file modification)

### Data Structure Extensions

#### Extended skills.json Schema
```json
{
  "skills": [
    {
      "id": "dodge_stance_1",
      "name": "闪避姿态I",
      "description": "每次胜利增加0.5%闪避概率",
      "type": "victory_bonus",
      "effects": {
        "dodge_chance_per_victory": 0.005
      },
      "stackable": true
    },
    {
      "id": "poison_blade",
      "name": "淬毒",
      "description": "每次攻击附带特殊攻击力的20%",
      "type": "on_hit",
      "effects": {
        "poison_damage_percent": 0.20
      },
      "stackable": false
    },
    {
      "id": "reflect_blade",
      "name": "反伤之刺",
      "description": "每次受到攻击对敌方造成2点伤害",
      "type": "on_hit_received",
      "effects": {
        "reflect_damage": 2
      },
      "stackable": true
    },
    {
      "id": "brave",
      "name": "勇猛",
      "description": "HP在70%以上时攻击速度增加50",
      "type": "conditional",
      "effects": {
        "attack_speed_bonus": 50,
        "hp_threshold_min": 0.7
      },
      "stackable": true
    },
    {
      "id": "desperate",
      "name": "背水",
      "description": "HP在30%以下时攻击速度增加100",
      "type": "conditional",
      "effects": {
        "attack_speed_bonus": 100,
        "hp_threshold_max": 0.3
      },
      "stackable": true
    },
    {
      "id": "healing_blade",
      "name": "恢复之刃",
      "description": "每次攻击回复1点HP",
      "type": "on_hit",
      "effects": {
        "heal_per_hit": 1
      },
      "stackable": true
    },
    {
      "id": "whirlwind",
      "name": "漩涡",
      "description": "攻击时有25%概率额外造成50%特殊攻击力伤害",
      "type": "chance_effect",
      "effects": {
        "trigger_chance": 0.25,
        "bonus_damage_percent": 0.5
      },
      "stackable": false
    },
    {
      "id": "lifesteal",
      "name": "吸血",
      "description": "每次攻击回复自身5%造成伤害的HP",
      "type": "on_hit",
      "effects": {
        "lifesteal_percent": 0.05
      },
      "stackable": true
    },
    {
      "id": "frost_blade",
      "name": "冰霜之刃",
      "description": "每次攻击会造成敌方速度降低5，持续1秒",
      "type": "debuff",
      "effects": {
        "speed_reduction": 5,
        "duration": 1.0
      },
      "stackable": true
    }
  ]
}
```

#### Extended Player Stats Structure
```lua
player.stats = {
  -- Existing stats
  attack = 25,
  defense = 10,
  hp = 200,
  max_hp = 200,
  attack_speed = 60,
  special_attack = 15,
  special_defense = 8,
  ultimate_value = 0,
  
  -- New stats for skill system
  dodge_chance = 0.0,    -- Base dodge chance (0.0 to 1.0)
  crit_chance = 0.0,     -- Base critical hit chance (0.0 to 1.0)
  evasion = 0.0          -- Alias for dodge_chance (combat_engine compatibility)
}
```

#### Temporary Effects Storage
```lua
player.active_effects = {
  debuffs_applied_to_enemy = {
    {
      type = "speed_reduction",
      value = 5,
      duration = 1.0,
      remaining_time = 0.8,
      source_skill = "frost_blade",
      stacks = 1
    }
  }
}

monster.active_debuffs = {
  {
    type = "speed_reduction",
    value = 5,
    duration = 1.0,
    remaining_time = 0.8,
    source_skill = "frost_blade",
    stacks = 1
  }
}
```

### System Architecture Changes

#### SkillSystem Extensions

**New Effect Type Handlers**
```lua
-- File: systems/skill_system.lua

function SkillSystem.applySkill(player, skill_id)
  -- Existing implementation stays the same
  -- Add new effect type handlers:
  
  if skill.type == "on_hit" then
    player.skills[skill_id] = skill.stackable and ((player.skills[skill_id] or 0) + 1) or true
  elseif skill.type == "on_hit_received" then
    player.skills[skill_id] = skill.stackable and ((player.skills[skill_id] or 0) + 1) or true
  elseif skill.type == "conditional" then
    player.skills[skill_id] = skill.stackable and ((player.skills[skill_id] or 0) + 1) or true
  elseif skill.type == "chance_effect" then
    player.skills[skill_id] = skill.stackable and ((player.skills[skill_id] or 0) + 1) or true
  elseif skill.type == "debuff" then
    player.skills[skill_id] = skill.stackable and ((player.skills[skill_id] or 0) + 1) or true
  end
end

function SkillSystem.applyVictoryBonuses(player)
  -- Existing implementation plus new dodge/crit bonuses:
  
  if skill.effects.dodge_chance_per_victory and actual_count > 0 then
    local bonus = skill.effects.dodge_chance_per_victory * actual_count
    player.stats.dodge_chance = (player.stats.dodge_chance or 0) + bonus
    player.stats.evasion = player.stats.dodge_chance  -- Sync with combat_engine
  end
  
  if skill.effects.crit_chance_per_victory and actual_count > 0 then
    local bonus = skill.effects.crit_chance_per_victory * actual_count
    player.stats.crit_chance = (player.stats.crit_chance or 0) + bonus
  end
end

function SkillSystem.calculateConditionalEffects(player)
  local speed_bonus = 0
  
  for skill_id, count in pairs(player.skills) do
    local skill = SkillSystem.getSkillById(skill_id)
    if skill and skill.type == "conditional" then
      local actual_count = (type(count) == "number") and count or (count and 1 or 0)
      local hp_percent = player.stats.hp / player.stats.max_hp
      
      if skill.effects.hp_threshold_min and hp_percent >= skill.effects.hp_threshold_min then
        speed_bonus = speed_bonus + (skill.effects.attack_speed_bonus * actual_count)
      elseif skill.effects.hp_threshold_max and hp_percent <= skill.effects.hp_threshold_max then
        speed_bonus = speed_bonus + (skill.effects.attack_speed_bonus * actual_count)
      end
    end
  end
  
  return speed_bonus
end

function SkillSystem.processOnHitEffects(attacker, defender, damage_dealt)
  if not attacker.skills then return 0 end
  
  local additional_damage = 0
  local healing_amount = 0
  
  for skill_id, count in pairs(attacker.skills) do
    local skill = SkillSystem.getSkillById(skill_id)
    if skill and skill.type == "on_hit" then
      local actual_count = (type(count) == "number") and count or (count and 1 or 0)
      
      -- Poison damage
      if skill.effects.poison_damage_percent then
        additional_damage = additional_damage + (attacker.stats.special_attack * skill.effects.poison_damage_percent)
      end
      
      -- Healing per hit
      if skill.effects.heal_per_hit then
        healing_amount = healing_amount + (skill.effects.heal_per_hit * actual_count)
      end
      
      -- Lifesteal
      if skill.effects.lifesteal_percent then
        healing_amount = healing_amount + (damage_dealt * skill.effects.lifesteal_percent * actual_count)
      end
    elseif skill and skill.type == "chance_effect" then
      if love.math.random() < skill.effects.trigger_chance then
        additional_damage = additional_damage + (attacker.stats.special_attack * skill.effects.bonus_damage_percent)
      end
    end
  end
  
  -- Apply healing
  if healing_amount > 0 then
    attacker.stats.hp = math.min(attacker.stats.max_hp, attacker.stats.hp + healing_amount)
  end
  
  return additional_damage
end

function SkillSystem.processOnHitReceivedEffects(attacker, defender, damage_dealt)
  if not defender.skills then return 0 end
  
  local reflect_damage = 0
  
  for skill_id, count in pairs(defender.skills) do
    local skill = SkillSystem.getSkillById(skill_id)
    if skill and skill.type == "on_hit_received" then
      local actual_count = (type(count) == "number") and count or (count and 1 or 0)
      
      if skill.effects.reflect_damage then
        reflect_damage = reflect_damage + (skill.effects.reflect_damage * actual_count)
      end
    end
  end
  
  return reflect_damage
end

function SkillSystem.applyDebuffs(attacker, defender)
  if not attacker.skills then return end
  
  for skill_id, count in pairs(attacker.skills) do
    local skill = SkillSystem.getSkillById(skill_id)
    if skill and skill.type == "debuff" then
      local actual_count = (type(count) == "number") and count or (count and 1 or 0)
      
      if skill.effects.speed_reduction and skill.effects.duration then
        SkillSystem.addDebuffToTarget(defender, {
          type = "speed_reduction",
          value = skill.effects.speed_reduction * actual_count,
          duration = skill.effects.duration,
          source_skill = skill_id
        })
      end
    end
  end
end
```

**Timer System for Temporary Effects**
```lua
-- File: systems/skill_system.lua

function SkillSystem.updateActiveEffects(target, dt)
  if not target.active_debuffs then
    target.active_debuffs = {}
  end
  
  for i = #target.active_debuffs, 1, -1 do
    local debuff = target.active_debuffs[i]
    debuff.remaining_time = debuff.remaining_time - dt
    
    if debuff.remaining_time <= 0 then
      -- Remove expired debuff
      table.remove(target.active_debuffs, i)
    end
  end
end

function SkillSystem.addDebuffToTarget(target, debuff_data)
  if not target.active_debuffs then
    target.active_debuffs = {}
  end
  
  -- Check for existing debuff of same type from same source
  local found_existing = false
  for _, existing_debuff in ipairs(target.active_debuffs) do
    if existing_debuff.type == debuff_data.type and existing_debuff.source_skill == debuff_data.source_skill then
      -- Refresh duration and add to value if stackable
      existing_debuff.remaining_time = debuff_data.duration
      existing_debuff.value = existing_debuff.value + debuff_data.value
      found_existing = true
      break
    end
  end
  
  if not found_existing then
    table.insert(target.active_debuffs, {
      type = debuff_data.type,
      value = debuff_data.value,
      duration = debuff_data.duration,
      remaining_time = debuff_data.duration,
      source_skill = debuff_data.source_skill
    })
  end
end

function SkillSystem.getActiveDebuffValue(target, debuff_type)
  if not target.active_debuffs then return 0 end
  
  local total_value = 0
  for _, debuff in ipairs(target.active_debuffs) do
    if debuff.type == debuff_type then
      total_value = total_value + debuff.value
    end
  end
  
  return total_value
end
```

### Combat Integration Points

#### CombatEngine Modifications

**File: systems/combat_engine.lua**
```lua
function CombatEngine.calculateDamage(attacker, defender)
  -- Apply conditional speed bonuses before calculating
  local SkillSystem = require("systems.skill_system")
  local speed_bonus = SkillSystem.calculateConditionalEffects(attacker)
  local effective_speed = attacker.attack_speed + speed_bonus
  
  -- Apply debuffs to defender's speed
  local speed_debuff = SkillSystem.getActiveDebuffValue(defender, "speed_reduction")
  local defender_effective_speed = math.max(1, defender.attack_speed - speed_debuff)
  
  -- Update combat intervals if needed for real-time combat
  -- Existing evasion/crit calculation stays the same
  local evasion_chance = (defender.dodge_chance or 0) + (defender.evasion or 0)
  if love.math.random() < evasion_chance then
    return 0, false, true  -- 0伤害，非暴击，已闪避
  end
  
  local damage_variance = love.math.random() * 0.2 + 0.9
  local base_damage = attacker.attack * damage_variance
  local damage_reduction = defender.defense / (defender.defense + 100)
  local after_defense_damage = base_damage * (1 - damage_reduction)
  
  -- Apply skill-based damage bonuses
  local additional_damage = SkillSystem.processOnHitEffects(attacker, defender, after_defense_damage)
  
  local crit_chance = (attacker.crit_chance or 0) + (attacker.crit_rate or 0)
  local is_critical = love.math.random() < crit_chance
  local final_damage = is_critical and (after_defense_damage * 1.5) or after_defense_damage
  
  final_damage = final_damage + additional_damage
  
  return math.floor(final_damage), is_critical, false
end

function CombatEngine.applyAttackConsequences(attacker, defender, damage_dealt)
  local SkillSystem = require("systems.skill_system")
  
  -- Process reflection damage
  local reflect_damage = SkillSystem.processOnHitReceivedEffects(attacker, defender, damage_dealt)
  if reflect_damage > 0 then
    attacker.hp = math.max(0, attacker.hp - reflect_damage)
  end
  
  -- Apply debuffs to defender
  SkillSystem.applyDebuffs(attacker, defender)
  
  return reflect_damage
end
```

#### Combat State Integration

**File: states/combat.lua**
```lua
function Combat.update(dt)
  -- Existing combat logic...
  
  -- Update skill effect timers
  local SkillSystem = require("systems.skill_system")
  SkillSystem.updateActiveEffects(player.stats, dt)
  SkillSystem.updateActiveEffects(monster, dt)
  
  -- Recalculate attack intervals with conditional effects
  local player_speed_bonus = SkillSystem.calculateConditionalEffects(player)
  local player_speed_debuff = SkillSystem.getActiveDebuffValue(player.stats, "speed_reduction")
  local effective_player_speed = math.max(1, player.stats.attack_speed + player_speed_bonus - player_speed_debuff)
  player_attack_interval = CombatEngine.speedToInterval(effective_player_speed)
  
  local monster_speed_debuff = SkillSystem.getActiveDebuffValue(monster, "speed_reduction")
  local effective_monster_speed = math.max(1, monster.attack_speed - monster_speed_debuff)
  monster_attack_interval = CombatEngine.speedToInterval(effective_monster_speed)
  
  -- Rest of existing combat logic...
end

function Combat.applyAttackDamage(attack)
  -- Existing damage application logic...
  
  -- Apply attack consequences (reflection, debuffs)
  if not attack.is_dodged then
    local reflect_damage = CombatEngine.applyAttackConsequences(
      attack.attacker == "player" and player.stats or monster,
      attack.attacker == "player" and monster or player.stats,
      attack.damage
    )
    
    if reflect_damage > 0 then
      if attack.attacker == "player" then
        table.insert(combat_log, "玩家受到 " .. reflect_damage .. " 点反伤！")
      else
        table.insert(combat_log, "怪物受到 " .. reflect_damage .. " 点反伤！")
      end
    end
  end
end
```

### UI Integration Changes

#### Skill Card Visual Differentiation

**File: ui/skill_cards.lua**
```lua
function SkillCards.drawSkillCard(skill, x, y, width, height, is_selected)
  -- Determine border style based on stackability
  local border_style = "solid"
  local border_color = {1, 1, 1, 1}  -- White
  
  if not skill.stackable then
    border_style = "dashed"
    border_color = {1, 1, 0, 1}  -- Yellow for non-stackable
  end
  
  if is_selected then
    border_color = {0, 1, 0, 1}  -- Green for selected
  end
  
  -- Draw card background
  love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
  love.graphics.rectangle("fill", x, y, width, height)
  
  -- Draw border (solid or dashed)
  love.graphics.setColor(border_color)
  love.graphics.setLineWidth(2)
  
  if border_style == "solid" then
    love.graphics.rectangle("line", x, y, width, height)
  else
    -- Draw dashed border
    SkillCards.drawDashedRectangle(x, y, width, height)
  end
  
  -- Rest of card content drawing...
end

function SkillCards.drawDashedRectangle(x, y, width, height)
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
```

### Configuration Changes
- **Settings**: None required
- **Environment Variables**: None required
- **Feature Flags**: None required

## Implementation Sequence

### Phase 1: Data Structure and Core Skill System Extensions
1. **Update data/skills.json** - Add all 10 new skills with proper effect definitions
2. **Extend systems/skill_system.lua** - Add new effect type handlers and helper functions
3. **Initialize player stats** - Add dodge_chance and crit_chance fields to player initialization
4. **Add timer system functions** - Implement SkillSystem.updateActiveEffects() and related functions

### Phase 2: Combat Engine Integration
1. **Modify systems/combat_engine.lua** - Integrate skill effects into damage calculation
2. **Update calculateDamage function** - Add conditional effects and debuff processing
3. **Add applyAttackConsequences function** - Handle reflection damage and debuff application
4. **Extend states/combat.lua** - Add skill effect timer updates and attack interval recalculation

### Phase 3: UI and Final Integration
1. **Update ui/skill_cards.lua** - Add visual differentiation for stackable vs non-stackable skills
2. **Test all skill effects** - Verify each of the 10 skills functions correctly
3. **Add combat log messages** - Ensure all new effects are properly reported to player
4. **Validate stacking behavior** - Confirm stackable skills accumulate correctly and non-stackable skills don't

## Validation Plan

### Unit Tests
- **Skill Effect Calculation**: Test each skill type's effect calculation with various stack counts
- **Timer System**: Verify debuff duration tracking and cleanup
- **Conditional Effects**: Test HP threshold calculations for conditional bonuses
- **Chance Effects**: Validate probability-based skill triggers
- **Victory Bonuses**: Confirm dodge/crit bonuses accumulate correctly per victory

### Integration Tests
- **Combat Flow**: Test complete combat scenarios with multiple skill combinations
- **Damage Calculation**: Verify damage includes all skill effects (poison, chance bonuses, lifesteal)
- **Debuff Application**: Test speed reduction debuffs apply and stack correctly
- **UI Rendering**: Confirm skill cards display correct border styles based on stackability
- **Save/Load**: Ensure skill effects persist correctly through save system

### Business Logic Verification
- **Gameplay Balance**: Each skill provides meaningful tactical choice
- **Visual Clarity**: Players can distinguish between stackable and non-stackable skills
- **Effect Timing**: All effects trigger at appropriate moments in combat
- **Stack Management**: Stackable skills accumulate properly, non-stackable skills are enforced
- **Performance**: Real-time combat maintains smooth performance with all effects active