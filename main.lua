--[[
    MTET: Block-stacking game focused on nyooms.
    Version: 1.1
    Developer: Mizu
    Graphics: Mizu
]]

function table.contains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end
function table.sum(table)
    local sum = 0
    for k, v in pairs(table) do
        sum = sum + v
    end
    return sum
end

binser = require "modules.binser"

local info = love.filesystem.getInfo('config.binser')
configFile = love.filesystem.newFile('config.binser')
if info == nil then
    love.filesystem.write('config.binser', binser.s({
        sfxVolume = 0.6,
    }))
end
configFile:open('r')
contents, size = configFile:read()
config = binser.deserialize(contents)[1]
--table.foreach(config, print)
configFile:close()

info = love.filesystem.getInfo('keys.binser')
keysFile = love.filesystem.newFile('keys.binser')
if info == nil then
    love.filesystem.write('keys.binser', binser.s({
        moveLeft = 'left',
        moveRight = 'right',
        softDrop = 'down',
        hardDrop = 'space',
        rotateCCW = 'z',
        rotateCW = 'x',
        rotate180 = 's',
        hold = 'c'
    }))
end
keysFile:open('r')
contents, size = keysFile:read()
keys = binser.deserialize(contents)[1]
--table.foreach(keys, print)
keysFile:close()

scene = {"menu"}
timer = 0

function generateNewGrid()
    local grid = {}
    for y=1,22 do
        grid[y]={' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '}
    end

    return grid
end

res = require "modules.res"
fonts = require "modules.fonts"

local blockSize = 20

local TinyParticleSystem = require 'modules.psys'
local LineParticles = TinyParticleSystem(res.img.blocks.garbage)
LineParticles.particle_size = 0.25
LineParticles.particle_speed = 500
--LineParticles:setParticleRotationRange(math.pi/4, 3*math.pi/4)
LineParticles.particle_update = function(part, dt)
    part.x = part.x + part.speed*part.mod_x*dt*(1 - part.life/part.expiration)*2
    part.y = part.y + part.speed*part.mod_y*dt*(1 - part.life/part.expiration)*2
    part.size = (1 - part.life/part.expiration)/4
end

menu = {
    options = {
        {'Play', 'modeSelect'},
        {'Options', 'config'},
        {'Key Configuration', 'keyconfig'},
        {'Exit', love.event.quit}
    },
    currentChoice = 1,
    lastChoiceTime = love.timer.getTime()
}

modeSelect = {
    currentChoice = 1,
    lastChoiceTime = love.timer.getTime()
}

game = require "scenes.game"

function deepCopy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function canPieceMove(tx, ty, orientation)
    for y = 1, #game.pieces[game.currentPiece.id][orientation] do
        for x = 1, #game.pieces[game.currentPiece.id][orientation][y] do
            if game.pieces[game.currentPiece.id][orientation][y][x] ~= ' ' then
                if (ty + y) > game.grid.yCount or (tx + x) > game.grid.xCount then
                    return false
                end
                if game.grid.grid[ty + y][tx + x] ~= ' ' then
                    return false
                end
            end
        end
    end

    return true
end

function spawnNewPiece()
    game.currentPiece.id = game.randomizer.queue[1]
    table.remove(game.randomizer.queue, 1)
    res.playSound(res.sounds.pieces[game.randomizer.queue[1]], config.sfxVolume)
    game.currentPiece.pos = {3, 0}
    game.currentPiece.orientation = 1
    game.currentPiece.active = true
    game.hold.available = true
    game.currentPiece.resets[1] = 0
    -- ihs
    if love.keyboard.isDown(keys.hold) then
        holdPiece(true)
    end

    -- irs
    local testRot = 1
    if love.keyboard.isDown(keys.rotateCW) and not love.keyboard.isDown(keys.rotateCCW) then
        testRot = testRot + 1
        if testRot > #game.pieces[game.currentPiece.id] then
            testRot = testRot - #game.pieces[game.currentPiece.id]
        end
        if canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2], testRot) then
            res.playSound(res.sounds.irs, config.sfxVolume)
            game.currentPiece.orientation = testRot
        end
    elseif love.keyboard.isDown(keys.rotateCCW) and not love.keyboard.isDown(keys.rotateCW) then
        testRot = testRot - 1
        if testRot < 1 then
            testRot = #game.pieces[game.currentPiece.id]
        end
        if canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2], testRot) then
            res.playSound(res.sounds.irs, config.sfxVolume)
            game.currentPiece.orientation = testRot
        end
    elseif love.keyboard.isDown(keys.rotateCW) and love.keyboard.isDown(keys.rotateCCW) then
        testRot = testRot + 2
        if testRot > #game.pieces[game.currentPiece.id] then
            testRot = #game.pieces[game.currentPiece.id]
        end
        if canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2], testRot) then
            res.playSound(res.sounds.irs, config.sfxVolume)
            game.currentPiece.orientation = testRot
        end
    end
    
    -- check if blocked
    if not canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2], game.currentPiece.orientation) then
        -- game over
        game.currentPiece.active = false
        game.gameOver = true
        res.playSound(res.sounds.gameover, config.sfxVolume)
    end
end

function holdPiece(init)
    if game.hold.available then
        if init then res.playSound(res.sounds.ihs, config.sfxVolume) else res.playSound(res.sounds.hold, config.sfxVolume) end
        if game.hold.id then
            game.hold.id, game.currentPiece.id = game.currentPiece.id, game.hold.id
        else
            game.hold.id = game.currentPiece.id
            game.currentPiece.id = game.randomizer.queue[1]
            table.remove(game.randomizer.queue, 1)
            res.playSound(res.sounds.pieces[game.randomizer.queue[1]], config.sfxVolume)
        end
        game.hold.available = false
        game.currentPiece.pos = {3, 0}
        game.currentPiece.orientation = 1
        game.currentPiece.active = true
        game.gravityDelay[1] = 0
        game.lockDelay[1] = 0
        game.currentPiece.resets[1] = 0

        -- check if blocked
        if not canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2], game.currentPiece.orientation) then
            -- game over
            game.currentPiece.active = false
            game.gameOver = true
            res.playSound(res.sounds.gameover, config.sfxVolume)
        end
    end
end

function kickPiece(rotDirection, endRot)
    local testPos = deepCopy(game.currentPiece.pos)

    if canPieceMove(testPos[1] + rotDirection, testPos[2], endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[1] = testPos[1] + rotDirection
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1] + rotDirection, testPos[2] + 1, endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[1] = testPos[1] + rotDirection
        game.currentPiece.pos[2] = testPos[2] + 1
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1], testPos[2] + 1, endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[2] = testPos[2] + 1
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1] - rotDirection, testPos[2] + 1, endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[1] = testPos[1] - rotDirection
        game.currentPiece.pos[2] = testPos[2] + 1
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1] - rotDirection, testPos[2], endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[1] = testPos[1] - rotDirection
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1], testPos[2] - 1, endRot) then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[2] = testPos[2] - 1
        game.currentPiece.orientation = endRot
    elseif canPieceMove(testPos[1], testPos[2] - 2, endRot) and game.currentPiece.id == 1 then
        res.playSound(res.sounds.bottom, config.sfxVolume)
        game.currentPiece.pos[2] = testPos[2] - 2
        game.currentPiece.orientation = endRot
    end
end

function love.keypressed(key)
    if scene[1] == 'game' then
        if game.currentPiece.active then
            local testPos = deepCopy(game.currentPiece.pos)
            local testRot = game.currentPiece.orientation
            if key == keys.rotateCW then
                res.playSound(res.sounds.rotate, config.sfxVolume)
                if (game.currentPiece.orientation + 1) <= #game.pieces[game.currentPiece.id] then
                    testRot = game.currentPiece.orientation + 1
                    local test = canPieceMove(testPos[1], testPos[2], testRot)
                    if test then
                        game.currentPiece.orientation = testRot
                    else
                        kickPiece(1, testRot)
                    end
                else
                    testRot = 1
                    local test = canPieceMove(testPos[1], testPos[2], testRot)
                    if test then
                        game.currentPiece.orientation = testRot
                    else
                        kickPiece(1, testRot)
                    end
                end
                if game.currentPiece.previouslyGrounded then
                    game.currentPiece.resets[1] = game.currentPiece.resets[1] + 1
                    game.lockDelay[1] = game.lockDelay[2] * (game.currentPiece.resets[1]/game.currentPiece.resets[2])
                end
            end
            if key == keys.rotateCCW then
                res.playSound(res.sounds.rotate, config.sfxVolume)
                if (game.currentPiece.orientation - 1) < 1 then
                    testRot = #game.pieces[game.currentPiece.id]
                    local test = canPieceMove(testPos[1], testPos[2], testRot)
                    if test then
                        game.currentPiece.orientation = testRot
                    else
                        kickPiece(-1, testRot)
                    end
                else
                    testRot = game.currentPiece.orientation - 1
                    local test = canPieceMove(testPos[1], testPos[2], testRot)
                    if test then
                        game.currentPiece.orientation = testRot
                    else
                        kickPiece(-1, testRot)
                    end
                end
                if game.currentPiece.previouslyGrounded then
                    game.currentPiece.resets[1] = game.currentPiece.resets[1] + 1
                    game.lockDelay[1] = game.lockDelay[2] * (game.currentPiece.resets[1]/game.currentPiece.resets[2])
                end
            end
            if key == keys.hardDrop then
                -- hard drop
                while canPieceMove(testPos[1], game.currentPiece.pos[2] + 1, testRot) do
                    game.currentPiece.pos[2] = game.currentPiece.pos[2] + 1
                    game.gravityDelay[1] = 0
                end
                placeToGrid(game.currentPiece)
                game.currentPiece.active = false
                game.lockDelay[1] = 0
            end
            --[[if key == 'up' then
                game.currentPiece.pos[2] = game.currentPiece.pos[2] - 1
            end]]
            if key == keys.softDrop then
                testPos[2] = game.currentPiece.pos[2] + 1
                local test = canPieceMove(testPos[1], testPos[2], testRot)
                if test then
                    res.playSound(res.sounds.move, config.sfxVolume)
                    game.currentPiece.pos[2] = testPos[2]
                    game.gravityDelay[1] = 0
                end
            end
            if key == keys.moveLeft then
                testPos[1] = game.currentPiece.pos[1] - 1
                local test = canPieceMove(testPos[1], testPos[2], testRot)
                if test then
                    res.playSound(res.sounds.move, config.sfxVolume)
                    game.currentPiece.pos[1] = testPos[1]
                end
                if game.currentPiece.previouslyGrounded then
                    game.currentPiece.resets[1] = game.currentPiece.resets[1] + 1
                    game.lockDelay[1] = game.lockDelay[2] * (game.currentPiece.resets[1]/game.currentPiece.resets[2])
                end
            end
            if key == keys.moveRight then
                testPos[1] = game.currentPiece.pos[1] + 1
                local test = canPieceMove(testPos[1], testPos[2], testRot)
                if test then
                    res.playSound(res.sounds.move, config.sfxVolume)
                    game.currentPiece.pos[1] = testPos[1]
                end
                if game.currentPiece.previouslyGrounded then
                    game.currentPiece.resets[1] = game.currentPiece.resets[1] + 1
                    game.lockDelay[1] = game.lockDelay[2] * (game.currentPiece.resets[1]/game.currentPiece.resets[2])
                end
            end
            if key == keys.hold then
                holdPiece(false)
            end
        elseif game.timer < -1 then
            if love.keyboard.isDown('lshift') then
                if key == keys.moveLeft then
                    game.level = math.max(game.level - 1, 0)
                    game.timer = -2
                end
                if key == keys.moveRight then
                    game.level = math.min(game.level + 1, game.modeFields[game.mode].levels - 1)
                    game.timer = -2
                end
            end
        end
    elseif scene[1] == "menu" then
        if key == 'up' then
            menu.currentChoice = math.max(menu.currentChoice - 1, 1)
            menu.lastChoiceTime = love.timer.getTime()
            res.playSound(res.sounds.cursor, config.sfxVolume)
        elseif key == 'down' then
            menu.currentChoice = math.min(menu.currentChoice + 1, #menu.options)
            menu.lastChoiceTime = love.timer.getTime()
            res.playSound(res.sounds.cursor, config.sfxVolume)
        elseif key == 'return' then
            res.playSound(res.sounds.main_decide, config.sfxVolume)
            if type(menu.options[menu.currentChoice][2]) == 'string' then
                scene = {menu.options[menu.currentChoice][2]}
            else
                menu.options[menu.currentChoice][2]()
            end
        end
    elseif scene[1] == "modeSelect" then
        if key == 'up' then
            modeSelect.currentChoice = math.max(modeSelect.currentChoice - 1, 1)
            modeSelect.lastChoiceTime = love.timer.getTime()
            res.playSound(res.sounds.cursor, config.sfxVolume)
        elseif key == 'down' then
            modeSelect.currentChoice = math.min(modeSelect.currentChoice + 1, #game.allModes)
            modeSelect.lastChoiceTime = love.timer.getTime()
            res.playSound(res.sounds.cursor, config.sfxVolume)
        elseif key == 'return' then
            res.playSound(res.sounds.mode_decide, config.sfxVolume)
            scene = {"game"}
            --table.foreach(game.allModes, print)
            game.mode = game.allModes[modeSelect.currentChoice]
        end
    end
end

function clearLines(lines)
    for i, v in ipairs(lines) do
        -- remove line
        table.remove(game.grid.grid, v)
        -- add empty line to top
        table.insert(game.grid.grid, 1, {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '})
    end
    res.playSound(res.sounds.fall, config.sfxVolume)
    game.linesToClear = {}
end

function placeToGrid(piece)
    -- lock sfx
    res.playSound(res.sounds.lock, config.sfxVolume)
    if game.lastPieceTime > 0 then
        game.pps = 1/(love.timer.getTime()-game.lastPieceTime)
    end
    game.lastPieceTime = love.timer.getTime()
    game.points[1] = game.points[1] + math.ceil(math.max(1, game.pps*2))
    -- level lock
    if game.points[1] >= game.points[2] then
        game.points[1] = game.points[2] - 1
        game.levelLock = game.levelLock + 1
        -- hurry up
        if game.levelLock == 2 then
            res.playSound(res.sounds.bell, config.sfxVolume)
        end
    else
        game.levelLock = 0
    end
    for y = 1, #game.pieces[piece.id][piece.orientation] do
        for x = 1, #game.pieces[piece.id][piece.orientation][y] do
            if game.pieces[piece.id][piece.orientation][y][x] ~= ' ' then
                game.grid.grid[piece.pos[2] + y][piece.pos[1] + x] = game.pieces[piece.id][piece.orientation][y][x]
            end
        end
    end
    for y = 1, game.grid.yCount do
        local full = true
        for x = 1, game.grid.xCount do
            if game.grid.grid[y][x] == ' ' then
                full = false
                break
            end
        end
        if full then
            table.insert(game.linesToClear, y)
            for x = 1, game.grid.xCount do
                LineParticles.image = res.img.blocks[game.grid.grid[y][x]]
                for i = 1,5 do
                    LineParticles:spawnParticle((x - 1) * blockSize + 10, (y - 1)*blockSize + 10)
                end
            end
        end
    end
    if #game.linesToClear > 0 then
        res.playSound(res.sounds.erase, config.sfxVolume)
        game.lines.lastClearLineCount = #game.linesToClear
        game.lines.lastClearTime = love.timer.getTime()
        game.lines.total = game.lines.total + #game.linesToClear
        game.lines.individual[math.min(#game.linesToClear, 5)] = game.lines.individual[math.min(#game.linesToClear, 5)] + 1
        game.points[1] = game.points[1] + 2^(#game.linesToClear-1)
    end
end

function love.load()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    -- Temporary
    --[[
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'i'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'j'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'l'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'o'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 's'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 't'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'z'
        game.grid.grid[math.random(3,22)][math.random(1,10)] = 'g'
    ]]
end

function love.update(dt)
    timer = timer + dt
    LineParticles:update(dt)
    if scene[1] == "game" and not game.gameOver then
        game.timer = game.timer + dt

        -- updating randomizer
        if #game.randomizer.queue < 14 then
            game.randomizer.generate(14 - #game.randomizer.queue)
        end
        
        -- level
        game.points[2] = game.curves[game.mode].points[game.level + 1]
        if game.points[1] >= game.points[2] then
            game.points[1] = game.points[1] % game.points[2]
            game.level = game.level + 1
            if game.level < game.modeFields[game.mode].levels then
                res.playSound(res.sounds.levelup, config.sfxVolume)
            else
                game.gameOver = true
                game.wonGame = true
                res.playSound(res.sounds.gameclear, config.sfxVolume)
                return
            end
        end
        
        if game.timer >= 0 then
            -- DAS
            if love.keyboard.isDown('left') and not love.keyboard.isDown('right') then
                if game.DASDirection == -1 then
                    game.DAS[1] = game.DAS[1] + dt
                else
                    game.DASDirection = -1
                end
            elseif love.keyboard.isDown('right') and not love.keyboard.isDown('left') then
                if game.DASDirection == 1 then
                    game.DAS[1] = game.DAS[1] + dt
                else
                    game.DASDirection = 1
                end
            else
                game.DASDirection = 0
                game.DAS[1] = 0
            end

            if game.currentPiece.active then
                -- automove
                if game.DASDirection ~= 0 and game.DAS[1] >= game.DAS[2] then
                    game.ARR[1] = game.ARR[1] + dt
                    if game.ARR[1] >= game.ARR[2] then
                        game.ARR[1] = game.ARR[1] % game.ARR[2]
                        local testPos = deepCopy(game.currentPiece.pos)
                        testPos[1] = game.currentPiece.pos[1] + game.DASDirection
                        local test = canPieceMove(testPos[1], testPos[2], game.currentPiece.orientation)
                        if test then
                            res.playSound(res.sounds.move, config.sfxVolume)
                            game.currentPiece.pos[1] = testPos[1]
                        end
                    end
                end

                -- gravity
                game.gravityDelay[2] = game.curves[game.mode].gravityDelay(game.level, game.points[1], game.points[2])
                local testY = game.currentPiece.pos[2] + 1
                if canPieceMove(game.currentPiece.pos[1], testY, game.currentPiece.orientation) then
                    game.currentPiece.previouslyGrounded = false
                    if game.gravityDelay[2] > 0 then
                        game.gravityDelay[1] = game.gravityDelay[1] + (love.keyboard.isDown("down") and dt * 50 or dt)
                        if game.gravityDelay[1] >= game.gravityDelay[2] then
                            if love.keyboard.isDown("down") then
                                res.playSound(res.sounds.move, config.sfxVolume)
                            end
                            game.gravityDelay[1] = game.gravityDelay[1] % game.gravityDelay[2]
                            game.lockDelay[1] = 0
                            game.currentPiece.pos[2] = game.currentPiece.pos[2] + 1
                        end
                    else
                        while canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2] + 1, game.currentPiece.orientation) do
                            game.currentPiece.pos[2] = game.currentPiece.pos[2] + 1
                            game.gravityDelay[1] = 0
                            game.lockDelay[1] = 0
                        end
                        --print(game.currentPiece.pos[2])
                    end
                    if not canPieceMove(game.currentPiece.pos[1], game.currentPiece.pos[2] + 1, game.currentPiece.orientation) then
                        game.gravityDelay[1] = 0
                    end
                else
                    -- grounded piece
                    if not game.currentPiece.previouslyGrounded then
                        res.playSound(res.sounds.bottom, config.sfxVolume)
                        game.currentPiece.previouslyGrounded = true
                    end
                    game.gravityDelay[1] = 0
                    game.lockDelay[1] = game.lockDelay[1] + dt
                    if game.lockDelay[1] >= game.lockDelay[2] then
                        game.lockDelay[1] = game.lockDelay[1] % game.lockDelay[2]
                        placeToGrid(game.currentPiece)
                        game.currentPiece.active = false
                        game.lockDelay[1] = 0
                    end
                end
            elseif #game.linesToClear > 0 then
                game.lineClearDelay[1] = game.lineClearDelay[1] + dt
                if game.lineClearDelay[1] >= game.lineClearDelay[2] then
                    clearLines(game.linesToClear)
                    game.lineClearDelay[1] = 0
                end
            else
                -- entry delay
                game.spawnDelay[2] = game.curves[game.mode].spawnDelay(game.level, game.points[1], game.points[2])
                game.spawnDelay[1] = game.spawnDelay[1] + dt
                if game.spawnDelay[1] >= game.spawnDelay[2] then
                    game.spawnDelay[1] = 0
                    spawnNewPiece()
                end
            end
        else
            game.currentPiece.active = false
        end
    end

    --[[
        game.grid.grid[3][math.floor(math.abs(math.cos(timer)*11))] = 'i'
        game.grid.grid[4][math.floor(math.abs(math.cos(timer)*11))] = 'j'
        game.grid.grid[5][math.floor(math.abs(math.cos(timer)*11))] = 'l'
        game.grid.grid[6][math.floor(math.abs(math.cos(timer)*11))] = 'o'
        game.grid.grid[7][math.floor(math.abs(math.cos(timer)*11))] = 's'
        game.grid.grid[8][math.floor(math.abs(math.cos(timer)*11))] = 't'
        game.grid.grid[9][math.floor(math.abs(math.cos(timer)*11))] = 'z'
        game.grid.grid[10][math.floor(math.abs(math.cos(timer)*11))] = 'g'
    ]]
    --game.currentPiece.id = math.random(1,7)
    --game.currentPiece.orientation = math.random(1,#game.pieces[game.currentPiece.id])
end

function love.draw()
    if scene[1] == "game" then
        local boardX = math.floor(love.graphics.getWidth()/2 - blockSize*game.grid.xCount/2)
        local boardY = math.floor(love.graphics.getHeight()/2 - blockSize*(game.grid.yCount)/2)

        -- board frame
        love.graphics.setLineWidth(5)
        love.graphics.setColor(game.modeColours[game.mode])
        love.graphics.polygon('line', boardX,boardY, boardX+game.grid.xCount*blockSize,boardY, boardX+game.grid.xCount*blockSize,boardY+game.grid.yCount*blockSize,  boardX,boardY+game.grid.yCount*blockSize)
        -- matrix
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle('fill', boardX, boardY, game.grid.xCount*blockSize, game.grid.yCount*blockSize)
        local function drawBlock(isInert, block, x, y, lockAmount)
            local blockDrawSize = blockSize
            if isInert then
                if block ~= ' ' then
                    love.graphics.setColor(0.6, 0.6, 0.6)
                    if not game.gameOver then
                        love.graphics.draw(res.img.blocks[block], (x - 1) * blockSize + boardX, (y - 1) * blockSize + boardY, 0, blockDrawSize/64, blockDrawSize/64)
                    else
                        love.graphics.draw(res.img.blocks.garbage, (x - 1) * blockSize + boardX, (y - 1) * blockSize + boardY, 0, blockDrawSize/64, blockDrawSize/64)
                    end
                end
            else
                if block ~= ' ' then
                    love.graphics.setColor(1 - 0.25*lockAmount, 1 - 0.25*lockAmount, 1 - 0.25*lockAmount)
                    love.graphics.draw(res.img.blocks[block], (x - 1) * blockSize + boardX, (y - 1) * blockSize + boardY, 0, blockDrawSize/64, blockDrawSize/64)
                end
            end
        end

        for y = 3, 22 do
            if not table.contains(game.linesToClear, y) then
                for x = 1, game.grid.xCount do
                    local block = game.grid.grid[y][x]
                    drawBlock(true, block, x, y)
                end
            end
        end

        -- warn line
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.7, 0, 0)
        love.graphics.line(boardX,boardY+2*blockSize, boardX+game.grid.xCount*blockSize,boardY+2*blockSize)

        if game.currentPiece.active then
            -- ghost
            local testPos = deepCopy(game.currentPiece.pos)
            local testRot = game.currentPiece.orientation
            while canPieceMove(testPos[1], testPos[2] + 1, testRot) do
                testPos[2] = testPos[2] + 1
            end
            for y = 1, #game.pieces[game.currentPiece.id][testRot] do
                for x = 1, #game.pieces[game.currentPiece.id][testRot][y] do
                    if game.pieces[game.currentPiece.id][testRot][y][x] ~= ' ' then
                        drawBlock(false, 'ghost', x + testPos[1], y + testPos[2], 0)
                    end
                end
            end

            -- piece
            for y = 1, #game.pieces[game.currentPiece.id][game.currentPiece.orientation] do
                for x = 1, #game.pieces[game.currentPiece.id][game.currentPiece.orientation][y] do
                    local block = game.pieces[game.currentPiece.id][game.currentPiece.orientation][y][x]
                    if game.gravityDelay[2] > 0 then
                        drawBlock(false, block, x + game.currentPiece.pos[1], y + game.currentPiece.pos[2] + game.gravityDelay[1]/game.gravityDelay[2], game.lockDelay[1]/game.lockDelay[2])
                    else
                        drawBlock(false, block, x + game.currentPiece.pos[1], y + game.currentPiece.pos[2], game.lockDelay[1]/game.lockDelay[2])
                    end
                end
            end
        end

        -- next pieces
        for i = 1,3 do
            for y = 1, #game.pieces[game.randomizer.queue[i]][1] do
                for x = 1, #game.pieces[game.randomizer.queue[i]][1][y] do
                    local block = game.pieces[game.randomizer.queue[i]][1][y][x]
                    if i == 1 then
                        if block ~= 'o' then
                            drawBlock(false, block, x + i*5 - 2, y - 3 + game.spawnDelay[1]/game.spawnDelay[2]*3, 0)
                        else
                            drawBlock(false, block, x + i*5 - 2, y - 2 + game.spawnDelay[1]/game.spawnDelay[2]*2, 0)
                        end
                    else
                        if block ~= 'o' then
                            drawBlock(false, block, x + i*5 - 2, y - 3, 0)
                        else
                            drawBlock(false, block, x + i*5 - 2, y - 2, 0)
                        end
                    end
                end
            end
        end
        love.graphics.setFont(fonts.gameplayDisplayText)
        love.graphics.printf('NEXT', boardX + 3*blockSize, boardY - 3*blockSize, 100)

        -- held piece
        if game.hold.id then
            for y = 1, #game.pieces[game.hold.id][1] do
                for x = 1, #game.pieces[game.hold.id][1][y] do
                    local block = game.pieces[game.hold.id][1][y][x]
                    local renderBlock = block
                    if (not game.hold.available) and (renderBlock ~= ' ') then
                        renderBlock = 'garbage'
                    end
                    if block ~= 'o' then
                        drawBlock(false, renderBlock, x - 2, y - 3, 0)
                    else
                        drawBlock(false, renderBlock, x - 2, y - 2, 0)
                    end
                end
            end
        end

        -- ready/go
        if game.timer <= 0 then
            love.graphics.setFont(fonts.readyGoText)
            if game.timer <= -1 then
                if game.readyGoSE == 0 then
                    res.playSound(res.sounds.ready, config.sfxVolume)
                    game.readyGoSE = 1
                end
                love.graphics.printf('READY', boardX, boardY + 5*blockSize, blockSize*game.grid.xCount, 'center')
            else
                if game.readyGoSE == 1 then
                    res.playSound(res.sounds.go, config.sfxVolume)
                    game.readyGoSE = 2
                end
                love.graphics.printf('GO', boardX, boardY + 5*blockSize, blockSize*game.grid.xCount, 'center')
            end
        end

        -- points
        local rightDisplayX = boardX + blockSize*game.grid.xCount + 10
        
        love.graphics.setFont(fonts.gameplayDisplayHeader)
        love.graphics.print('POINTS', rightDisplayX, boardY + blockSize * 2)
        love.graphics.setFont(fonts.gameplayDisplayNumbers)
        love.graphics.printf(game.points[1], rightDisplayX, boardY + blockSize * 2 + 28, 50, 'right')
        love.graphics.printf(game.points[2], rightDisplayX, boardY + blockSize * 2 + 48, 50, 'right')
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.arc('fill', 'pie', rightDisplayX + 55, boardY + blockSize * 2 + 48, 15, -math.pi/2, math.pi/2)
        love.graphics.setColor(1-game.points[1]/game.points[2], game.points[1]/game.points[2], 0)
        love.graphics.arc('fill', 'pie', rightDisplayX + 55, boardY + blockSize * 2 + 48, 15, -math.pi/2, game.points[1]/game.points[2]*math.pi - math.pi/2)

        love.graphics.setColor(1,1,1)
        love.graphics.setFont(fonts.gameplayDisplayHeader)
        love.graphics.print('LEVEL', rightDisplayX, boardY + blockSize * 2 + 70)
        love.graphics.setFont(fonts.gameplayDisplayNumbers)
        love.graphics.printf(game.level, rightDisplayX, boardY + blockSize * 2 + 96, 50, 'left')

        -- lock delay/resets display
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle('fill', boardX, boardY + 23*blockSize, game.grid.xCount*blockSize*(1-game.lockDelay[1]/game.lockDelay[2]), blockSize/2)
        love.graphics.setColor(0.7, 0, 0)
        love.graphics.rectangle('line', boardX, boardY + 23*blockSize, game.grid.xCount*blockSize*(1-game.currentPiece.resets[1]/game.currentPiece.resets[2]), blockSize/2)

        local leftDisplayWidth = 200
        local leftDisplayX = boardX - leftDisplayWidth - 10

        -- mode display
        love.graphics.setColor(game.modeColours[game.mode])
        love.graphics.setFont(fonts.gameplayDisplayHeader)
        love.graphics.printf(game.modeFields[game.mode].display, leftDisplayX, boardY + blockSize * 2, leftDisplayWidth, 'right')
        
        -- line clear message
        if love.timer.getTime() - game.lines.lastClearTime <= 1 then
            if love.timer.getTime() - game.lines.lastClearTime >= 0.5 then
                love.graphics.setColor(1, 1, 1, 1 - math.min(love.timer.getTime() - game.lines.lastClearTime - 0.5, 1))
                love.graphics.printf(game.lines.clearNames[math.min(game.lines.lastClearLineCount, 5)], leftDisplayX, boardY + blockSize * 2 + 30 + fonts.gameplayDisplayHeader:getHeight()/2*math.min((love.timer.getTime() - game.lines.lastClearTime - 0.5)/0.5, 1), leftDisplayWidth, 'right', 0, 1, 1 - math.min((love.timer.getTime() - game.lines.lastClearTime - 0.5)/0.5, 1))
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(game.lines.clearNames[math.min(game.lines.lastClearLineCount, 5)], leftDisplayX, boardY + blockSize * 2 + 30, leftDisplayWidth, 'right')
            end
        end

        -- gravity display
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(fonts.gameplayDisplayHeader)
        love.graphics.printf('GRAVITY', leftDisplayX, boardY + blockSize * 2 + 58, leftDisplayWidth, 'right')
        love.graphics.setFont(fonts.gameplayDisplayNumbers)
        love.graphics.printf(string.format('%.3fG', 1/game.gravityDelay[2]/1/60), leftDisplayX, boardY + blockSize * 2 + 88, leftDisplayWidth, 'right')

        -- spawn time display
        love.graphics.setFont(fonts.gameplayDisplayHeader)
        love.graphics.printf('SPAWN TIME', leftDisplayX, boardY + blockSize * 2 + 106, leftDisplayWidth, 'right')
        love.graphics.setFont(fonts.gameplayDisplayNumbers)
        love.graphics.printf(game.spawnDelay[2]*1000 .. 'ms', leftDisplayX, boardY + blockSize * 2 + 134, leftDisplayWidth, 'right')

        -- particles
        LineParticles:draw(boardX, boardY)

        -- game over stats
        if game.gameOver then
            if game.wonGame then
                love.graphics.setFont(fonts.gameplayDisplayHeader)
                love.graphics.setColor(0, 0.7, 0)
                love.graphics.printf('YOU WIN', boardX, boardY + 5*blockSize, blockSize*game.grid.xCount, 'center')
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(fonts.gameplayDisplayText)
                love.graphics.printf('Objective cleared!', boardX, boardY + 5*blockSize + 30, blockSize*game.grid.xCount, 'center')
            else
                love.graphics.setFont(fonts.gameplayDisplayHeader)
                love.graphics.setColor(0.7, 0, 0)
                love.graphics.printf('GAME OVER', boardX, boardY + 5*blockSize, blockSize*game.grid.xCount, 'center')
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(fonts.gameplayDisplayText)
                love.graphics.printf('Objective failed...', boardX, boardY + 5*blockSize + 30, blockSize*game.grid.xCount, 'center')
            end

            love.graphics.printf('Line clear distribution', boardX, boardY + (game.grid.yCount-5)*blockSize - 30, blockSize*game.grid.xCount, 'center')
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle('fill', boardX + 10, boardY + (game.grid.yCount-5)*blockSize - 10, blockSize*game.grid.xCount - 20, 5*blockSize)
            local poly = {}
            local clearSum = table.sum(game.lines.individual)
            for k, v in pairs(game.lines.individual) do
                table.insert(poly, boardX + 10 + (k-1)/3*(blockSize*game.grid.xCount - 20))
                table.insert(poly, boardY + (game.grid.yCount)*blockSize - 10 - 5*blockSize*v/clearSum)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.line(poly)
        end
    elseif scene[1] == "menu" then
        love.graphics.setFont(fonts.titleFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf('MTET', 0, 20, love.graphics.getWidth(), 'center')

        for i, v in ipairs(menu.options) do
            if menu.currentChoice == i then
                love.graphics.setColor(0, 0.5, 1)
            else
                love.graphics.setColor(1, 1, 1, 0.7)
            end
            love.graphics.setFont(fonts.gameplayDisplayNumbers)
            if menu.currentChoice == i then
                love.graphics.printf(v[1], 15 + 10*math.min((love.timer.getTime() - menu.lastChoiceTime)*4, 1), love.graphics.getHeight()/2-(#menu.options*20)/2 + (i-1)*20, 200 - 10*math.min((love.timer.getTime() - menu.lastChoiceTime)*4, 1), 'left')
            else
                love.graphics.printf(v[1], 15, love.graphics.getHeight()/2-(#menu.options*20)/2 + (i-1)*20, 200, 'left')
            end
        end
    elseif scene[1] == "modeSelect" then
        love.graphics.setFont(fonts.titleFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf('Select Mode', 0, 20, love.graphics.getWidth(), 'center')

        for i, v in ipairs(game.allModes) do
            if modeSelect.currentChoice == i then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(game.modeColours[v])
            end
            love.graphics.setFont(fonts.gameplayDisplayNumbers)
            if modeSelect.currentChoice == i then
                love.graphics.printf(game.modeFields[v].display, 15 + 10*math.min((love.timer.getTime() - modeSelect.lastChoiceTime)*4, 1), love.graphics.getHeight()/2-(#menu.options*20)/2 + (i-1)*20, 200 - 10*math.min((love.timer.getTime() - menu.lastChoiceTime)*4, 1), 'left')
            else
                love.graphics.printf(game.modeFields[v].display, 15, love.graphics.getHeight()/2-(#menu.options*20)/2 + (i-1)*20, 200, 'left')
            end
        end

        love.graphics.setColor(1,1,1)
        love.graphics.printf(game.modeFields[game.allModes[modeSelect.currentChoice]].tagline, 15, love.graphics.getHeight()-100, love.graphics.getWidth() - 30, 'left')
    end
end