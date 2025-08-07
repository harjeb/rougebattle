# Skill Implementation Requirements Confirmation

## Feature Overview
Implement 10 new skills from `data/skills.txt` into the existing skill system with proper combat integration and UI differentiation.

## Original Request
"我在data\skills.txt 增加了几个技能，你根据我的描述帮我实现"

## Requirements Quality Score: 92/100
- **Functional Clarity (28/30)**: Clear skill effects and UI differentiation
- **Technical Specificity (23/25)**: Combat integration and stat additions specified  
- **Implementation Completeness (23/25)**: Timing and effect triggers defined
- **Business Context (20/20)**: Gameplay enhancement value clear

## Confirmed Requirements

### New Skills to Implement
1. **闪避姿态I** - Victory bonus: +0.5% dodge chance per victory (stackable)
2. **暴击姿态I** - Victory bonus: +1% critical hit rate per victory (stackable)
3. **淬毒** - On-hit effect: +20% special attack poison damage (non-stackable)
4. **反伤之刃** - Reflect damage: 2 damage to attacker when hit (stackable)
5. **勇猛** - Conditional: +50 attack speed when HP > 70% (stackable)
6. **背水** - Conditional: +100 attack speed when HP < 30% (stackable)
7. **恢复之刃** - On-hit healing: +1 HP per attack (stackable)
8. **漩涡** - Chance effect: 25% chance for +50% special attack damage (non-stackable)
9. **吸血** - Lifesteal: heal 5% of damage dealt (stackable)
10. **冰霜之刃** - Enemy debuff: -5 speed for 1s, timer starts on hit (stackable)

### Technical Implementation Details
- **Stats Extension**: Add `dodge_chance`, `crit_chance` fields to player stats
- **Combat Integration**: Modify `combat_engine.lua` to check skill effects during attacks
- **Data Structure**: Follow existing `skills.json` format
- **Stackability**: 淬毒, 漩涡 non-stackable; others stackable
- **UI Differentiation**: Non-stackable skills use dashed border, stackable use solid border
- **Timer System**: Real-time effects (冰霜之刃) start timing after attack hits enemy

### Effect Types Implementation
- **Victory Bonus Effects**: Applied after combat wins
- **On-Hit Effects**: Triggered during attack resolution  
- **Conditional Effects**: Checked during combat based on HP percentage
- **Chance-based Effects**: Use `love.math.random()` for probability
- **Temporary Debuffs**: Timer-based effects with duration tracking

## Clarification Rounds
**Round 1**: Technical implementation questions
- Skill effect system integration: ✅ Confirmed
- Combat system modifications: ✅ Confirmed  
- Data structure approach: ✅ Follow existing format
- Effect timing mechanisms: ✅ Defined

## User Approval Required
Requirements are now clear (92+ points). Ready to proceed with implementation.