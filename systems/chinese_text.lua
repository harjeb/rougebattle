-- 中文文本管理系统 - 避免编码问题的备用方案
local ChineseText = {}

-- 如果中文显示有问题，可以使用英文替代
ChineseText.texts = {
    -- 菜单
    game_title = "Roguelike Auto Battle",
    game_subtitle = "Black & White Edition", 
    start_game = "Start Game",
    start_hint = "Press SPACE or ENTER to start",
    
    -- 技能选择
    choose_skill = "Choose Skill:",
    world_level = "World %d - Level %d",
    owned = "Owned",
    owned_count = "Owned: %d",
    click_to_select = "Click card or press 1/2/3 to select",
    current_stats = "Stats - ATK:%d DEF:%d SPD:%d HP:%d/%d Wins:%d",
    
    -- 战斗
    player_hp = "Player HP: %d/%d",
    monster_hp = "%s HP: %d/%d",
    player_ultimate = "Player Ultimate: %d/100",
    monster_ultimate = "Monster Ultimate: %d/100",
    victory = "VICTORY!",
    defeat = "DEFEAT!",
    
    -- 游戏结束
    congratulations = "Congratulations!",
    all_worlds_conquered = "You conquered all 5 worlds!",
    game_over = "Game Over",
    retry_world = "Try this world again",
    return_to_menu = "Click anywhere to return to menu",
    
    -- 技能名称
    fixed_attack = "Fixed Attack Boost",
    fixed_defense = "Fixed Defense Boost", 
    victory_attack = "Victory Attack Stack",
    victory_speed = "Victory Speed Stack",
    victory_heal = "Victory Heal",
    
    -- 技能描述
    fixed_attack_desc = "+10 Attack permanently",
    fixed_defense_desc = "+5 Defense permanently",
    victory_attack_desc = "+2 Attack per victory",
    victory_speed_desc = "+5 Speed per victory", 
    victory_heal_desc = "+20% max HP healing after victory"
}

-- 尝试使用中文，如果失败则使用英文
ChineseText.chinese_texts = {
    -- 菜单
    game_title = "肉鸽自动对战",
    game_subtitle = "黑白像素版",
    start_game = "开始游戏", 
    start_hint = "按空格键或回车键开始",
    
    -- 技能选择
    choose_skill = "选择技能：",
    world_level = "第 %d 世界 - 第 %d 关",
    owned = "已拥有",
    owned_count = "已拥有: %d",
    click_to_select = "点击卡片或按数字键1/2/3选择",
    current_stats = "当前属性 - 攻击:%d 防御:%d 速度:%d 生命:%d/%d 胜利:%d",
    
    -- 战斗
    player_hp = "玩家生命: %d/%d",
    monster_hp = "%s 生命: %d/%d",
    player_ultimate = "玩家奥义: %d/100",
    monster_ultimate = "怪物奥义: %d/100", 
    victory = "胜利！",
    defeat = "失败！",
    
    -- 游戏结束
    congratulations = "恭喜通关！",
    all_worlds_conquered = "你征服了所有5个世界！",
    game_over = "游戏结束",
    retry_world = "重新挑战这个世界", 
    return_to_menu = "点击任意处返回主菜单",
    
    -- 技能名称
    fixed_attack = "固定攻击强化",
    fixed_defense = "固定防御强化",
    victory_attack = "胜利攻击叠加", 
    victory_speed = "胜利速度叠加",
    victory_heal = "胜利治疗",
    
    -- 技能描述
    fixed_attack_desc = "永久增加10点攻击力",
    fixed_defense_desc = "永久增加5点防御力",
    victory_attack_desc = "每次胜利增加2点攻击力",
    victory_speed_desc = "每次胜利增加5点攻击速度",
    victory_heal_desc = "胜利后恢复20%最大生命值"
}

local use_chinese = true -- 默认启用中文

function ChineseText.get(key, ...)
    local text_table = use_chinese and ChineseText.chinese_texts or ChineseText.texts
    local text = text_table[key] or ChineseText.texts[key] or key
    
    if ... then
        return string.format(text, ...)
    else
        return text
    end
end

function ChineseText.setChinese(enabled)
    use_chinese = enabled
end

function ChineseText.isChinese()
    return use_chinese
end

return ChineseText