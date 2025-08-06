function love.conf(t)
    t.title = "肉鸽自动对战"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.console = false  -- 关闭控制台避免中文乱码
    t.window.vsync = 1
    
    -- 设置UTF-8编码
    if love.filesystem then
        love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";?.lua;?/init.lua")
    end
end