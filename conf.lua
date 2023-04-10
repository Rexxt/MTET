function love.conf(t)
    local version = {1, 2, 0}
    t.window.title = 'MTET' .. version[1] .. '.' .. version[2] .. (version[3] > 0 and '+' .. version[3] or '')
    t.identity = 'MTET'
    t.console = true
end