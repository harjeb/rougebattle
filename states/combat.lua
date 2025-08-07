-- In states/combat.lua
local Combat = {}
local CombatEngine = require("systems.combat_engine")
local MonsterSystem = require("systems.monster_system")
local SkillSystem = require("systems.skill_system")
local SaveSystem = require("systems.save_system")
local CombatUI = require("ui.combat_ui") -- Require the new UI module
local AnimationSystem = require("systems.animation_system")

local player = nil
local monster = nil
local combat_log = {}
local combat_timer = 0
local combat_phase = "fighting"
local player_attack_timer = 0
local monster_attack_timer = 0
local player_attack_interval = 1.0
local monster_attack_interval = 1.0

function Combat.load(data)
    player = SaveSystem.getPlayer()
    monster = MonsterSystem.generateMonster(player.current_world, player.current_level)
    combat_log = {}
    table.insert(combat_log, "第 " .. player.current_world .. " 世界 - 第 " .. player.current_level .. " 关")
    
    -- Initialize active_debuffs for monster if not present
    if not monster.active_debuffs then
        monster.active_debuffs = {}
    end
    
    -- 计算攻击间隔：使用新的速度公式和技能效果
    local effective_player_speed = CombatEngine.calculateEffectiveSpeed(player.stats)
    local effective_monster_speed = CombatEngine.calculateEffectiveSpeed(monster)
    player_attack_interval = CombatEngine.speedToInterval(effective_player_speed)
    monster_attack_interval = CombatEngine.speedToInterval(effective_monster_speed)
    
    combat_timer = 0
    player_attack_timer = 0
    monster_attack_timer = 0
    combat_phase = "fighting"
    AnimationSystem.clear()
    pending_attacks = {}
    last_attack_timestamp = 0
    
    table.insert(combat_log, "战斗开始！")
    table.insert(combat_log, string.format("玩家速度:%d (%.3f秒/次)", effective_player_speed, player_attack_interval))
    table.insert(combat_log, string.format("怪物速度:%d (%.3f秒/次)", effective_monster_speed, monster_attack_interval))
end

function Combat.update(dt)
    combat_timer = combat_timer + dt
    AnimationSystem.update(dt)
    
    -- Process collision detection for concurrent attacks
    AnimationSystem.checkAttackCollision()
    
    -- Process completed attacks
    Combat.processCompletedAttacks()
    
    if combat_phase == "fighting" then
        -- Update skill effect timers for both player and monster
        local SkillSystem = require("systems.skill_system")
        SkillSystem.updateActiveEffects(player.stats, dt)
        SkillSystem.updateActiveEffects(monster, dt)
        
        -- Recalculate attack intervals with conditional effects and debuffs
        local effective_player_speed = CombatEngine.calculateEffectiveSpeed(player.stats)
        local effective_monster_speed = CombatEngine.calculateEffectiveSpeed(monster)
        player_attack_interval = CombatEngine.speedToInterval(effective_player_speed)
        monster_attack_interval = CombatEngine.speedToInterval(effective_monster_speed)
        
        -- 玩家攻击计时（不受动画影响）
        player_attack_timer = player_attack_timer + dt
        if player_attack_timer >= player_attack_interval and player.stats.hp > 0 and monster.hp > 0 then
            Combat.queuePlayerAttack()
            player_attack_timer = 0
        end
        
        -- 怪物攻击计时（不受动画影响）
        monster_attack_timer = monster_attack_timer + dt
        if monster_attack_timer >= monster_attack_interval and monster.hp > 0 and player.stats.hp > 0 then
            Combat.queueMonsterAttack()
            monster_attack_timer = 0
        end
        
        -- 检查胜负（基于当前血量）
        Combat.checkCombatEnd()
        
    elseif combat_phase == "victory" and combat_timer > 2.0 then
        Combat.handleVictory()
        
    elseif combat_phase == "defeat" and combat_timer > 2.0 then
        Combat.handleDefeat()
    end
end

-- Real-time combat functions (replaced old execute functions)
function Combat.queuePlayerAttack()
    local damage, is_crit, is_ultimate, is_dodged = Combat.calculatePlayerDamage()
    local timestamp = love.timer.getTime()
    local bullet_id = AnimationSystem.generateBulletId()
    
    -- Create attack data
    local attack = {
        attacker = "player",
        damage = damage,
        is_critical = is_crit,
        is_ultimate = is_ultimate,
        is_dodged = is_dodged,
        timestamp = timestamp,
        bullet_id = bullet_id
    }
    
    -- Create animation
    AnimationSystem.createBulletAnimation(
        200, 200,  -- Player position
        600, 200,  -- Monster position
        0.3,       -- Duration
        {1, 1, 0.2, 1},  -- Yellow bullet
        "player",
        timestamp,
        function()
            Combat.applyAttackDamage(attack)
        end
    )
    
    -- Store in pending attacks
    pending_attacks[bullet_id] = attack
end

function Combat.queueMonsterAttack()
    local damage, is_crit, is_ultimate, is_dodged = Combat.calculateMonsterDamage()
    local timestamp = love.timer.getTime()
    local bullet_id = AnimationSystem.generateBulletId()
    
    -- Create attack data
    local attack = {
        attacker = "monster",
        damage = damage,
        is_critical = is_crit,
        is_ultimate = is_ultimate,
        is_dodged = is_dodged,
        timestamp = timestamp,
        bullet_id = bullet_id
    }
    
    -- Create animation
    AnimationSystem.createBulletAnimation(
        600, 200,  -- Monster position
        200, 200,  -- Player position
        0.3,       -- Duration
        {1, 0.2, 0.2, 1},  -- Red bullet
        "monster",
        timestamp,
        function()
            Combat.applyAttackDamage(attack)
        end
    )
    
    -- Store in pending attacks
    pending_attacks[bullet_id] = attack
end

function Combat.calculatePlayerDamage()
    local damage, is_crit, is_dodged = 0, false, false
    local is_ultimate = false
    
    if CombatEngine.incrementUltimate(player.stats) then
        damage = CombatEngine.calculateUltimateDamage(player.stats, monster)
        is_ultimate = true
        CombatEngine.resetUltimate(player.stats)
    else
        damage, is_crit, is_dodged = CombatEngine.calculateDamage(player.stats, monster)
    end
    
    return damage, is_crit, is_ultimate, is_dodged
end

function Combat.calculateMonsterDamage()
    local damage, is_crit, is_dodged = 0, false, false
    local is_ultimate = false
    
    -- Handle BOSS healing ability during attack timing
    if monster.boss_ability == "regeneration" then
        local healed = MonsterSystem.applyBossAbility(monster, player.stats)
        if healed > 0 then
            table.insert(combat_log, "BOSS回复了 " .. healed .. " 点生命值！")
        end
    end
    
    if CombatEngine.incrementUltimate(monster) then
        damage = CombatEngine.calculateUltimateDamage(monster, player.stats)
        is_ultimate = true
        CombatEngine.resetUltimate(monster)
    else
        damage, is_crit, is_dodged = CombatEngine.calculateDamage(monster, player.stats)
    end
    
    return damage, is_crit, is_ultimate, is_dodged
end

function Combat.applyAttackDamage(attack)
    -- Remove from pending attacks
    pending_attacks[attack.bullet_id] = nil
    
    -- 处理闪避
    if attack.is_dodged then
        if attack.attacker == "player" then
            table.insert(combat_log, "怪物闪避了玩家的攻击！")
        else
            table.insert(combat_log, "玩家闪避了怪物的攻击！")
        end
        return  -- 闪避后不再造成伤害
    end
    
    -- Apply damage based on attacker type
    if attack.attacker == "player" then
        monster.hp = monster.hp - attack.damage
        if monster.hp <= 0 then
            monster.hp = 0
        end
        
        -- Apply attack consequences (reflection, debuffs)
        local reflect_damage = CombatEngine.applyAttackConsequences(player.stats, monster, attack.damage)
        if reflect_damage > 0 then
            table.insert(combat_log, "玩家受到 " .. reflect_damage .. " 点反伤！")
        end
        
        -- Add combat log
        if attack.is_ultimate then
            table.insert(combat_log, "玩家发动奥义！造成 " .. attack.damage .. " 点伤害！")
        else
            table.insert(combat_log, "玩家攻击造成 " .. attack.damage .. (attack.is_critical and " 点伤害！(暴击！)" or " 点伤害"))
        end
    else
        player.stats.hp = player.stats.hp - attack.damage
        if player.stats.hp <= 0 then
            player.stats.hp = 0
        end
        
        -- Apply attack consequences (reflection, debuffs)
        local reflect_damage = CombatEngine.applyAttackConsequences(monster, player.stats, attack.damage)
        if reflect_damage > 0 then
            table.insert(combat_log, "怪物受到 " .. reflect_damage .. " 点反伤！")
        end
        
        -- Add combat log
        if attack.is_ultimate then
            table.insert(combat_log, "怪物发动奥义！造成 " .. attack.damage .. " 点伤害！")
        else
            table.insert(combat_log, "怪物攻击造成 " .. attack.damage .. (attack.is_critical and " 点伤害！(暴击！)" or " 点伤害"))
        end
    end
end

function Combat.processCompletedAttacks()
    -- Animation callbacks handle damage application automatically
    -- This function reserved for future batch processing if needed
end

function Combat.checkCombatEnd()
    if monster.hp <= 0 and combat_phase == "fighting" then
        combat_phase = "victory"
        combat_timer = 0
    elseif player.stats.hp <= 0 and combat_phase == "fighting" then
        combat_phase = "defeat"
        combat_timer = 0
    end
end

function Combat.handleVictory()
    player.victory_count = player.victory_count + 1
    SkillSystem.applyVictoryBonuses(player)
    
    -- 重置奥义值
    player.stats.ultimate_value = 0
    
    player.current_level = player.current_level + 1
    if player.current_level > 50 then
        player.current_world = player.current_world + 1
        player.current_level = 1
    end
    
    if player.current_world > 5 then
        local GameState = require("systems.game_state")
        GameState.switch("game_over", {victory = true})
    else
        SaveSystem.save()
        local GameState = require("systems.game_state")
        GameState.switch("skill_selection")
    end
end

function Combat.handleDefeat()
    -- 失败后重置到当前世界第一关
    player.current_level = 1
    player.stats.hp = player.stats.max_hp
    -- 重置奥义值
    player.stats.ultimate_value = 0
    SaveSystem.save()
    local GameState = require("systems.game_state")
    GameState.switch("game_over", {victory = false})
end

function Combat.draw()
    -- Delegate drawing to the UI module
    CombatUI.draw(player, monster, combat_log, combat_phase)
    -- Draw animations on top
    AnimationSystem.draw()
end

return Combat