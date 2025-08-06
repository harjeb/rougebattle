# 实时战斗系统技术规格书

## Problem Statement

**Business Issue**: 当前战斗系统存在回合制限制，玩家和怪物必须轮流攻击，攻击动画期间全局等待，造成战斗节奏不流畅，不符合"实时战斗"的预期体验。

**Current State**: 
- 使用`waiting_for_animation`标志强制等待单个攻击动画完成
- 玩家和怪物攻击计时器在动画期间暂停
- 子弹动画颜色统一为黄色，无法区分攻击来源
- 伤害应用与动画完成同步，造成攻击间隔不连续

**Expected Outcome**: 
- 完全移除回合制限制，实现真正的并发攻击
- 玩家和怪物按各自速度独立攻击，互不干扰
- 子弹动画支持并发播放，颜色区分攻击来源
- 伤害按实际子弹到达时间应用，保持连续战斗节奏

## Solution Overview

**Approach**: 重构战斗循环和动画系统，将同步阻塞式动画改为异步并发式，通过独立计时器和子弹队列管理实现真正的实时战斗。

**Core Changes**:
1. 移除全局`waiting_for_animation`状态管理机制
2. 实现支持并发播放的动画系统
3. 增加子弹颜色区分和视觉标识
4. 重构伤害应用逻辑为异步回调
5. 优化战斗日志按时间顺序记录

**Success Criteria**:
- 玩家和怪物可同时发起攻击
- 攻击动画可重叠播放无明显延迟
- 子弹颜色正确区分攻击来源（玩家黄色，怪物红色）
- 战斗节奏流畅，攻击间隔严格按速度计算
- 所有现有功能（奥义、BOSS技能等）保持兼容

## Technical Implementation

### Database Changes
无数据库变更需求，所有数据存储在内存状态管理中。

### Code Changes

#### 1. Animation System 重构 (systems/animation_system.lua)

**新增数据结构**:
```lua
-- 子弹动画增强参数
local animation = {
    type = "bullet",
    start_x, start_y, end_x, end_y,  -- 位置参数保持不变
    duration, time, progress,        -- 时间参数保持不变
    color = {r, g, b, a},           -- 新增：颜色参数
    attacker_type = "player"|"monster", -- 新增：攻击者类型
    attack_timestamp,               -- 新增：攻击发起时间戳
    on_complete = function,         -- 回调函数保持不变
    bullet_id = string              -- 新增：唯一标识符
}
```

**函数签名变更**:
```lua
-- 原函数：createBulletAnimation(start_x, start_y, end_x, end_y, duration, on_complete)
-- 新函数：createBulletAnimation(start_x, start_y, end_x, end_y, duration, color, attacker_type, attack_timestamp, on_complete)
function AnimationSystem.createBulletAnimation(start_x, start_y, end_x, end_y, duration, color, attacker_type, attack_timestamp, on_complete)
```

**新增函数**:
```lua
-- 生成唯一子弹ID
function AnimationSystem.generateBulletId()
    return "bullet_" .. tostring(love.timer.getTime()) .. "_" .. tostring(math.random(1000, 9999))
end

-- 获取活跃动画数量
function AnimationSystem.getActiveAnimationCount()
    return #active_animations
end

-- 按攻击时间排序动画（用于日志记录）
function AnimationSystem.getAnimationsByTimestamp()
    local sorted = {}
    for _, anim in ipairs(active_animations) do
        table.insert(sorted, anim)
    end
    table.sort(sorted, function(a, b) return a.attack_timestamp < b.attack_timestamp end)
    return sorted
end
```

#### 2. Combat State 重构 (states/combat.lua)

**移除的全局状态**:
```lua
-- 移除：local waiting_for_animation = false
```

**新增状态管理**:
```lua
-- 新增：攻击队列管理
local pending_attacks = {}  -- 存储待处理攻击的队列
local last_attack_timestamp = 0  -- 最后攻击时间戳

-- 新增：攻击数据结构
local attack_data = {
    attacker = "player"|"monster",
    damage = number,
    is_critical = boolean,
    is_ultimate = boolean,
    timestamp = number,
    bullet_id = string
}
```

**函数重写**:

**Combat.update 重构**:
```lua
function Combat.update(dt)
    combat_timer = combat_timer + dt
    AnimationSystem.update(dt)
    
    -- 处理已完成动画的攻击
    Combat.processCompletedAttacks()
    
    if combat_phase == "fighting" then
        -- 玩家攻击计时（独立运行，不受动画影响）
        player_attack_timer = player_attack_timer + dt
        if player_attack_timer >= player_attack_interval and player.stats.hp > 0 and monster.hp > 0 then
            Combat.queuePlayerAttack()
            player_attack_timer = 0
        end
        
        -- 怪物攻击计时（独立运行，不受动画影响）
        monster_attack_timer = monster_attack_timer + dt
        if monster_attack_timer >= monster_attack_interval and monster.hp > 0 and player.stats.hp > 0 then
            Combat.queueMonsterAttack()
            monster_attack_timer = 0
        end
        
        -- 检查胜负（基于当前血量）
        Combat.checkCombatEnd()
    end
    
    -- 胜利/失败处理保持不变
end
```

**新增攻击队列函数**:
```lua
function Combat.queuePlayerAttack()
    local damage, is_crit, is_ultimate = Combat.calculatePlayerDamage()
    local timestamp = love.timer.getTime()
    local bullet_id = AnimationSystem.generateBulletId()
    
    -- 创建攻击数据
    local attack = {
        attacker = "player",
        damage = damage,
        is_critical = is_crit,
        is_ultimate = is_ultimate,
        timestamp = timestamp,
        bullet_id = bullet_id
    }
    
    -- 创建动画
    AnimationSystem.createBulletAnimation(
        200, 200,  -- 玩家位置
        600, 200,  -- 怪物位置
        0.3,       -- 持续时间
        {1, 1, 0.2, 1},  -- 黄色子弹
        "player",
        timestamp,
        function()
            Combat.applyAttackDamage(attack)
        end
    )
    
    -- 记录到待处理队列
    pending_attacks[bullet_id] = attack
end

function Combat.queueMonsterAttack()
    local damage, is_crit, is_ultimate = Combat.calculateMonsterDamage()
    local timestamp = love.timer.getTime()
    local bullet_id = AnimationSystem.generateBulletId()
    
    -- 创建攻击数据
    local attack = {
        attacker = "monster",
        damage = damage,
        is_critical = is_crit,
        is_ultimate = is_ultimate,
        timestamp = timestamp,
        bullet_id = bullet_id
    }
    
    -- 创建动画
    AnimationSystem.createBulletAnimation(
        600, 200,  -- 怪物位置
        200, 200,  -- 玩家位置
        0.3,       -- 持续时间
        {1, 0.2, 0.2, 1},  -- 红色子弹
        "monster",
        timestamp,
        function()
            Combat.applyAttackDamage(attack)
        end
    )
    
    -- 记录到待处理队列
    pending_attacks[bullet_id] = attack
end
```

**伤害计算函数分离**:
```lua
function Combat.calculatePlayerDamage()
    local damage, is_crit = 0, false
    local is_ultimate = false
    
    if CombatEngine.incrementUltimate(player.stats) then
        damage = CombatEngine.calculateUltimateDamage(player.stats, monster)
        is_ultimate = true
        CombatEngine.resetUltimate(player.stats)
    else
        damage, is_crit = CombatEngine.calculateDamage(player.stats, monster)
    end
    
    return damage, is_crit, is_ultimate
end

function Combat.calculateMonsterDamage()
    local damage, is_crit = 0, false
    local is_ultimate = false
    
    -- 处理BOSS技能
    if monster.boss_ability == "regeneration" then
        local healed = MonsterSystem.applyBossAbility(monster, player.stats)
        if healed > 0 then
            -- 注意：回血逻辑现在与攻击动画并行
            table.insert(combat_log, "BOSS回复了 " .. healed .. " 点生命值！")
        end
    end
    
    if CombatEngine.incrementUltimate(monster) then
        damage = CombatEngine.calculateUltimateDamage(monster, player.stats)
        is_ultimate = true
        CombatEngine.resetUltimate(monster)
    else
        damage, is_crit = CombatEngine.calculateDamage(monster, player.stats)
    end
    
    return damage, is_crit, is_ultimate
end
```

**异步伤害应用**:
```lua
function Combat.applyAttackDamage(attack)
    -- 从待处理队列移除
    pending_attacks[attack.bullet_id] = nil
    
    -- 应用伤害
    if attack.attacker == "player" then
        monster.hp = monster.hp - attack.damage
        if monster.hp <= 0 then
            monster.hp = 0
        end
        
        -- 添加战斗日志
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
        
        -- 添加战斗日志
        if attack.is_ultimate then
            table.insert(combat_log, "怪物发动奥义！造成 " .. attack.damage .. " 点伤害！")
        else
            table.insert(combat_log, "怪物攻击造成 " .. attack.damage .. (attack.is_critical and " 点伤害！(暴击！)" or " 点伤害"))
        end
    end
end

function Combat.processCompletedAttacks()
    -- 动画系统回调会自动处理已完成攻击
    -- 此函数用于批量处理可能需要的额外逻辑
end
```

**胜负判定优化**:
```lua
function Combat.checkCombatEnd()
    if monster.hp <= 0 and combat_phase == "fighting" then
        combat_phase = "victory"
        combat_timer = 0
    elseif player.stats.hp <= 0 and combat_phase == "fighting" then
        combat_phase = "defeat"
        combat_timer = 0
    end
end
```

#### 3. Animation System 视觉增强 (systems/animation_system.lua)

**drawBullet 函数更新**:
```lua
function AnimationSystem.drawBullet(anim)
    -- 计算当前位置
    local current_x = anim.start_x + (anim.end_x - anim.start_x) * anim.progress
    local current_y = anim.start_y + (anim.end_y - anim.start_y) * anim.progress
    
    -- 使用指定的颜色绘制子弹
    love.graphics.setColor(anim.color[1], anim.color[2], anim.color[3], anim.color[4])
    love.graphics.circle("fill", current_x, current_y, 3)
    
    -- 绘制轨迹线，颜色与子弹匹配但透明度递减
    local alpha = math.max(0, 0.5 - anim.progress * 0.5)
    love.graphics.setColor(anim.color[1], anim.color[2], anim.color[3], alpha * 0.5)
    love.graphics.line(anim.start_x, anim.start_y, current_x, current_y)
    
    love.graphics.setColor(1, 1, 1, 1) -- 重置颜色
end
```

**攻击时机冲突检测**:
```lua
function AnimationSystem.checkAttackCollision()
    -- 检测是否有多个动画同时到达目标
    local threshold = 0.1  -- 100ms内视为同时
    local arrivals = {}
    
    for _, anim in ipairs(active_animations) do
        if anim.progress >= 0.95 then  -- 即将到达
            table.insert(arrivals, {
                anim = anim,
                time_to_arrival = (1 - anim.progress) * anim.duration
            })
        end
    end
    
    -- 如果有多个同时到达，轻微错开时间
    if #arrivals > 1 then
        table.sort(arrivals, function(a, b) return a.time_to_arrival < b.time_to_arrival end)
        for i = 2, #arrivals do
            if math.abs(arrivals[i].time_to_arrival - arrivals[1].time_to_arrival) < threshold then
                -- 轻微延迟后续攻击的回调
                local original_callback = arrivals[i].anim.on_complete
                arrivals[i].anim.on_complete = function()
                    -- 延迟50ms执行
                    Timer.after(0.05 * (i - 1), original_callback)
                end
            end
        end
    end
end
```

### API Changes

#### 新增函数接口
- `AnimationSystem.createBulletAnimation(start_x, start_y, end_x, end_y, duration, color, attacker_type, attack_timestamp, on_complete)`
- `AnimationSystem.generateBulletId()`
- `AnimationSystem.getActiveAnimationCount()`
- `Combat.queuePlayerAttack()`
- `Combat.queueMonsterAttack()`
- `Combat.calculatePlayerDamage()`
- `Combat.calculateMonsterDamage()`
- `Combat.applyAttackDamage(attack)`
- `Combat.processCompletedAttacks()`
- `Combat.checkCombatEnd()`

#### 移除的接口
- 无（保持向后兼容）

### Configuration Changes

#### 新增配置参数
```lua
-- 战斗配置
COMBAT_CONFIG = {
    BULLET_SPEED = 0.3,           -- 子弹飞行时间（秒）
    PLAYER_BULLET_COLOR = {1, 1, 0.2, 1},    -- 玩家子弹颜色（黄色）
    MONSTER_BULLET_COLOR = {1, 0.2, 0.2, 1}, -- 怪物子弹颜色（红色）
    ATTACK_COLLISION_THRESHOLD = 0.1,        -- 攻击冲突检测阈值（秒）
    MAX_CONCURRENT_ANIMATIONS = 10           -- 最大并发动画数
}
```

## Implementation Sequence

### Phase 1: Animation System Enhancement
**目标**: 增强动画系统支持并发和颜色区分

**具体任务**:
1. `systems/animation_system.lua`: 修改createBulletAnimation函数增加颜色参数
2. `systems/animation_system.lua`: 更新drawBullet函数使用指定颜色
3. `systems/animation_system.lua`: 添加子弹ID生成和管理
4. 测试：验证颜色区分和并发播放

### Phase 2: Combat State Refactoring
**目标**: 重构战斗状态移除回合制限制

**具体任务**:
1. `states/combat.lua`: 移除waiting_for_animation状态变量
2. `states/combat.lua`: 创建新的攻击队列系统
3. `states/combat.lua`: 实现异步伤害应用逻辑
4. `states/combat.lua`: 分离伤害计算和动画创建
5. 测试：验证独立计时器工作正常

### Phase 3: Visual Enhancement & Polish
**目标**: 优化视觉效果和用户体验

**具体任务**:
1. `states/combat.lua`: 实现子弹颜色区分（玩家黄色，怪物红色）
2. `systems/animation_system.lua`: 添加攻击冲突检测和错开机制
3. `ui/combat_ui.lua`: 确保战斗日志按时间顺序显示
4. 全面测试：验证所有功能兼容性

## Validation Plan

### Unit Tests

#### Animation System测试
```lua
-- Test 1: 并发动画创建
function test_concurrent_animations()
    AnimationSystem.clear()
    AnimationSystem.createBulletAnimation(0,0,100,100,0.3,{1,0,0,1},"player",1,function() end)
    AnimationSystem.createBulletAnimation(0,0,100,100,0.3,{0,1,0,1},"monster",2,function() end)
    assert(AnimationSystem.getActiveAnimationCount() == 2)
end

-- Test 2: 颜色区分验证
function test_color_distinction()
    AnimationSystem.clear()
    local player_anim = AnimationSystem.createBulletAnimation(0,0,100,100,0.3,{1,1,0.2,1},"player",1,function() end)
    local monster_anim = AnimationSystem.createBulletAnimation(0,0,100,100,0.3,{1,0.2,0.2,1},"monster",2,function() end)
    assert(player_anim.color == {1,1,0.2,1})
    assert(monster_anim.color == {1,0.2,0.2,1})
end
```

#### Combat逻辑测试
```lua
-- Test 3: 独立攻击计时器
function test_independent_attack_timers()
    Combat.load(mock_data)
    local initial_player_timer = player_attack_timer
    local initial_monster_timer = monster_attack_timer
    
    -- 模拟1秒时间流逝
    Combat.update(1.0)
    
    assert(player_attack_timer ~= initial_player_timer)
    assert(monster_attack_timer ~= initial_monster_timer)
end

-- Test 4: 异步伤害应用
function test_async_damage_application()
    Combat.load(mock_data)
    local initial_monster_hp = monster.hp
    
    -- 模拟玩家攻击
    Combat.queuePlayerAttack()
    
    -- 验证伤害在动画完成后应用
    assert(monster.hp == initial_monster_hp) -- 动画未完成时血量不变
end
```

### Integration Tests

#### 端到端战斗测试
1. **并发攻击测试**: 创建玩家和怪物速度相同的场景，验证可同时发起攻击
2. **颜色区分测试**: 验证玩家子弹为黄色，怪物子弹为红色
3. **胜负时机测试**: 验证基于攻击发起时间的胜负判定
4. **BOSS技能兼容性**: 验证回血和双倍攻击技能在并发环境下正常工作
5. **奥义系统兼容性**: 验证奥义充能和释放机制不受影响

### Business Logic Verification

#### 实时战斗体验验证
- **测试场景1**: 玩家速度100，怪物速度50，预期玩家攻击频率是怪物2倍
- **测试场景2**: 双方速度相同，预期攻击动画同时飞行，伤害同时应用
- **测试场景3**: 高速攻击场景（速度1000），验证0.03秒间隔正常工作
- **测试场景4**: 同时致命攻击，验证先发起攻击的一方获胜

#### 性能验证
- **并发动画数量**: 验证10个并发动画下帧率保持稳定
- **内存管理**: 验证动画完成后内存正确释放
- **状态一致性**: 验证并发攻击下游戏状态始终一致

## 实施完成标准

1. ✅ 所有回合制限制已移除
2. ✅ 玩家和怪物攻击完全独立
3. ✅ 子弹动画支持并发播放
4. ✅ 颜色区分实现（玩家黄色，怪物红色）
5. ✅ 战斗日志按实际时间顺序记录
6. ✅ 所有现有功能保持兼容性
7. ✅ 性能测试通过（10并发动画稳定60fps）
8. ✅ 端到端测试通过（所有验证场景）