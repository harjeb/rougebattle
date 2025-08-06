# Love2D Roguelike Auto-Battle Game - Requirements Confirmation

## Original Request
我安装了love2D, 我想用它来制作一个 rougelike 黑白像素的 自动对战游戏， 特点是 玩家 每回合开始前可以 从3个技能中选择 1个技能， 然后 每回合对战一个怪物，默认 有5个大关卡，每个大关卡 50个小关卡， 玩家需要从1-1 打到5-50， 每个大关卡50都是boss战，玩家和怪物 都有 HP、攻击力/防御力/特殊攻击力/特殊防御力/攻击速度/暴击率/奥义值 属性， HP归0则战斗失败 需要从这个大关卡第一关重新开始，随机技能分为很多种，暂时只做5个，最好可以方便我手动添加，有 固定攻击力增加，固定防御力增加/ 每次胜利累计增加攻击力/累计增加攻击速度等

## Clarification Process

### Round 1 Questions & Answers:
**Auto-Battle System:** Players just watch the automatic combat
**Turn Order:** Based on attack speed stats
**Damage Formula:** 
```
浮动比例 = random(0.9, 1.1)
基础伤害 = 攻击力 * 浮动比例
减伤率 = 防御力 / (防御力 + 100)
防御后伤害 = 基础伤害 * (1 - 减伤率)
是否暴击 = random(0, 1) < 暴击率
最终伤害 = 是否暴击 ? 防御后伤害 * 1.5 : 防御后伤害
```
**Skill Selection:** Random pool of 3 skills each turn
**Skill Type:** Permanent stat boosts
**Screen Size:** 800x600
**UI Style:** Card-based skill selection
**Display Info:** HP bars and game state
**Save System:** Yes, progress persistence needed
**Settings:** No options menu needed
**Platform:** Desktop only
**Critical Hits:** 1.5x damage multiplier
**Ultimate System:** +2 per attack, at 100 triggers ultimate (攻击力+特殊攻击力) damage
**Special Attack:** Used for skills and ultimates, not regular attacks

### Round 2 Questions & Answers:
**Defense K Value:** 100
**Crit Multiplier:** 1.5x
**Boss Abilities:** Bosses have special abilities beyond higher stats
**Skill Storage:** JSON format for easy manual addition

### Round 3 - Final Design Decisions:
**5th Skill Type:** Heal after each victory (designed by assistant)
**Monster Scaling:** Balanced progression allowing player victory with skill upgrades

## Final Requirements Quality Score: 92/100

- **Functional Clarity:** 28/30 points
- **Technical Specificity:** 23/25 points  
- **Implementation Completeness:** 23/25 points
- **Business Context:** 18/20 points

## Confirmed Requirements Summary

### Core Game Loop
1. Player selects 1 skill from 3 random options each turn
2. Auto-battle against monster based on attack speed
3. Victory advances to next level, defeat restarts current world
4. Progress from level 1-1 to 5-50 (250 total levels)
5. Every x-50 level is a boss with special abilities

### Combat System
- **Stats:** HP, Attack, Defense, Special Attack, Special Defense, Attack Speed, Crit Rate, Ultimate Value
- **Damage Formula:** Attack * random(0.9,1.1) * (1 - Defense/(Defense+100)) * (crit ? 1.5 : 1)
- **Ultimate System:** +2 per attack, at 100 triggers (Attack + Special Attack) damage
- **Turn Order:** Higher attack speed goes first

### Skill System (JSON-based)
1. **Fixed Attack Boost:** +10 Attack permanently
2. **Fixed Defense Boost:** +5 Defense permanently  
3. **Victory Attack Stack:** +2 Attack per victory
4. **Victory Speed Stack:** +1 Attack Speed per victory
5. **Victory Heal:** +20% max HP healing after each victory

### Technical Specifications
- **Engine:** Love2D framework
- **Resolution:** 800x600 pixels
- **Art Style:** Black and white pixel art
- **UI:** Card-based skill selection interface
- **Save System:** Progress persistence between sessions
- **File Structure:** JSON for skill definitions and monster data
- **Platform:** Desktop only

### Monster Scaling Strategy
- **Balanced Progression:** Monster stats scale to provide challenge while allowing player progression through skill selection
- **Boss Mechanics:** Special abilities at world-50 levels (1-50, 2-50, 3-50, 4-50, 5-50)
- **World Restart:** Death sends player back to current world's first level

**Requirements Status: CONFIRMED - Ready for Implementation (92/100 points)**