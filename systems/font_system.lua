local FontSystem = {}

local chinese_font = nil
local font_loaded = false
local font_status = "loading"

function FontSystem.load()
    -- 尝试加载自定义字体
    local custom_fonts = {
        "assets/fonts/chinese.ttf",
        "assets/fonts/chinese.otf", 
        "assets/fonts/simhei.ttf",
        "assets/fonts/msyh.ttf",
        "assets/fonts/NotoSansCJK.ttf"
    }
    
    for _, font_path in ipairs(custom_fonts) do
        if love.filesystem.getInfo(font_path) then
            local success, font = pcall(love.graphics.newFont, font_path, 18)
            if success then
                chinese_font = font
                font_loaded = true
                font_status = "loaded: " .. font_path
                return
            else
                font_status = "failed: " .. font_path
            end
        end
    end
    
    -- 尝试默认字体
    font_status = "trying_default"
    local success, font = pcall(love.graphics.newFont, 18)
    if success then
        chinese_font = font
        font_loaded = true
        font_status = "default_18px"
        return
    end
    
    -- 最后使用系统字体
    font_status = "system_font"
    chinese_font = love.graphics.getFont()
    font_loaded = true
end

function FontSystem.getFont()
    if not font_loaded then
        FontSystem.load()
    end
    return chinese_font
end

function FontSystem.setFont()
    if not font_loaded then
        FontSystem.load()
    end
    love.graphics.setFont(chinese_font)
end

function FontSystem.getStatus()
    return font_status
end

function FontSystem.reload()
    font_loaded = false
    chinese_font = nil
    font_status = "reloading"
    FontSystem.load()
end

return FontSystem