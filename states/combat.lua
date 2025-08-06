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
local waiting_for_animation = false

function Combat.load(data)
    player = SaveSystem.getPlayer()
    monster = MonsterSystem.generateMonster(player.current_world, player.current_level)
    combat_log = {}
    table.insert(combat_log, "第 " .. player.current_world .. " 世界 - 第 " .. player.current_level .. " 关")
    
    -- 计算攻击间隔：使用新的速度公式
    -- 速度50 = 1.0秒间隔, 速度1000 = 0.03秒间隔
    player_attack_interval = CombatEngine.speedToInterval(player.stats.attack_speed)
    monster_attack_interval = CombatEngine.speedToInterval(monster.attack_speed)
    
    combat_timer = 0
    player_attack_timer = 0
    monster_attack_timer = 0
    combat_phase = "fighting"
    waiting_for_animation = false
    AnimationSystem.clear()
    
    table.insert(combat_log, "战斗开始！")
    table.insert(combat_log, string.format("玩家速度:%d (%.3f秒/次)", player.stats.attack_speed, player_attack_interval))
    table.insert(combat_log, string.format("怪物速度:%d (%.3f秒/次)", monster.attack_speed, monster_attack_interval))
end

function Combat.update(dt)
    combat_timer = combat_timer + dt
    AnimationSystem.update(dt)
    
    if combat_phase == "fighting" and not waiting_for_animation then
        -- 更新玩家攻击计时器
        player_attack_timer = player_attack_timer + dt
        if player_attack_timer >= player_attack_interval and player.stats.hp > 0 and monster.hp > 0 then
            Combat.executePlayerAttack()
            player_attack_timer = 0
        end
        
        -- 更新怪物攻击计时器
        monster_attack_timer = monster_attack_timer + dt
        if monster_attack_timer >= monster_attack_interval and monster.hp > 0 and player.stats.hp > 0 then
            Combat.executeMonsterAttack()
            monster_attack_timer = 0
        end
        
        -- 检查胜负
        if monster.hp <= 0 and combat_phase == "fighting" then
            combat_phase = "victory"
            combat_timer = 0
        elseif player.stats.hp <= 0 and combat_phase == "fighting" then
            combat_phase = "defeat" 
            combat_timer = 0
        end
        
    elseif combat_phase == "victory" and combat_timer > 2.0 then
        Combat.handleVictory()
        
    elseif combat_phase == "defeat" and combat_timer > 2.0 then
        Combat.handleDefeat()
    end
end

function Combat.executePlayerAttack()
    -- Calculate damage first
    local damage, is_crit
    local is_ultimate = false
    
    if CombatEngine.incrementUltimate(player.stats) then
        damage = CombatEngine.calculateUltimateDamage(player.stats, monster)
        is_ultimate = true
        CombatEngine.resetUltimate(player.stats)
    else
        damage, is_crit = CombatEngine.calculateDamage(player.stats, monster)
    end
    
    -- Create animation from player position to monster position
    waiting_for_animation = true
    AnimationSystem.createBulletAnimation(
        200, 200, -- Player position (approximate)
        600, 200, -- Monster position (approximate)
        0.3, -- Duration
        function()
            -- Apply damage when animation completes
            monster.hp = monster.hp - damage
            if monster.hp <= 0 then
                monster.hp = 0
            end
            
            -- Add combat log message
            if is_ultimate then
                table.insert(combat_log, "玩家发动奥义！造成 " .. damage .. " 点伤害！")
            else
                table.insert(combat_log, "玩家攻击造成 " .. damage .. (is_crit and " 点伤害！(暴击！)" or " 点伤害"))
            end
            
            waiting_for_animation = false
        end
    )
end

function Combat.executeMonsterAttack()
    -- BOSS回血能力（每次攻击时检查）
    if monster.boss_ability == "regeneration" then
        local healed = MonsterSystem.applyBossAbility(monster, player.stats)
        if healed > 0 then
            table.insert(combat_log, "BOSS回复了 " .. healed .. " 点生命值！")
        end
    end
    
    -- BOSS双倍攻击能力：攻击间隔减半
    if monster.boss_ability == "double_attack" then
        -- 双倍攻击已经通过攻击间隔减半实现
    end
    
    -- Calculate damage first
    local damage, is_crit
    local is_ultimate = false
    
    if CombatEngine.incrementUltimate(monster) then
        damage = CombatEngine.calculateUltimateDamage(monster, player.stats)
        is_ultimate = true
        CombatEngine.resetUltimate(monster)
    else
        damage, is_crit = CombatEngine.calculateDamage(monster, player.stats)
    end
    
    -- Create animation from monster position to player position
    waiting_for_animation = true
    AnimationSystem.createBulletAnimation(
        600, 200, -- Monster position (approximate)
        200, 200, -- Player position (approximate)
        0.3, -- Duration
        function()
            -- Apply damage when animation completes
            player.stats.hp = player.stats.hp - damage
            if player.stats.hp <= 0 then
                player.stats.hp = 0
            end
            
            -- Add combat log message
            if is_ultimate then
                table.insert(combat_log, "怪物发动奥义！造成 " .. damage .. " 点伤害！")
            else
                table.insert(combat_log, "怪物攻击造成 " .. damage .. (is_crit and " 点伤害！(暴击！)" or " 点伤害"))
            end
            
            waiting_for_animation = false
        end
    )
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