return {
    timer = -2,
    mode = 'stamina',
    allModes = {'stamina', 'rush', 'doom'},
    modeFields = {
        stamina = {
            display = 'STAMINA',
            tagline = 'Are you ready to prove that you\'re a grandmaster? Fight through 10 levels of intense gameplay to get the best grade!',
            difficulty = 2, -- 0-5
            levels = 10,
        },
        rush = {
            display = 'RUSH',
            tagline = 'Get ready for high speed stacking! Think you can make it?',
            difficulty = 3, -- 0-5
            levels = 10,
        },
        doom = {
            display = 'DOOM',
            tagline = 'Are you ready for intense maximum gravity stacking?',
            difficulty = 4, -- 0-5
            levels = 10,
        },
    },
    modeColours = {
        stamina = {0, 0.5, 0.7},
        rush = {1, 0.25, 0},
        doom = {0.7, 0, 0}
    },
    level = 0,
    levelLock = 0, -- pieces since level was locked
    points = {0, 200}, -- {current, required}
    gradePoints = 0,
    gradeLetter = function(gradePercent)
            if gradePercent < 0.25 then return "F"
        elseif gradePercent < 0.5  then return "D"
        elseif gradePercent < 0.6  then return "C"
        elseif gradePercent < 0.7  then return "B"
        elseif gradePercent < 0.8  then return "A"
        elseif gradePercent < 0.9  then return "S"
        elseif gradePercent < 0.95 then return "M"
        else return "GM" end
    end,
    grades = {},
    pieces = 0,
    lastPieceTime = 0,
    pps = 0,
    lines = {
        total = 0,
        individual = {0, 0, 0, 0}, -- each type of clear
        clearNames = {'SINGLE', 'DOUBLE', 'TRIPLE', 'QUADRA'},
        lastClearTime = 0,
        lastClearLineCount = 0,
    },
    grid = {
        grid = generateNewGrid(),
        xCount = 10,
        yCount = 22,
    },
    pieces = require 'scenes.pieces',
    currentPiece = {
        id = 2,
        pos = {4, 0},
        orientation = 1,
        active = false,
        previouslyGrounded = false,
        resets = {0, 20}, -- {current, max}
    },
    hold = {
        id = nil,
        available = true,
    },
    spawnDelay = {0, 0.3}, -- {current, max}
    gravityDelay = {0, 1, 0.3, false}, -- {current, max, soft drop max, 20G}
    lockDelay = {0, 0.5}, -- {current, max}
    linesToClear = {},
    lineClearDelay = {0, 0.5}, -- {current, max}
    DAS = {0, 0.135}, -- {current, max}
    ARR = {0, 0.03}, -- {current, max}
    DASDirection = 0, -- -1 <-> 1
    gameOver = false,
    wonGame = false,
    readyGoSE = 0,
    curves = {
        stamina = {
            points = {200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 1900},
            gravityDelay = function(level, points, maxPoints)
                local netLevel = level + points/maxPoints
                    if netLevel < 0.5 then return 1
                elseif netLevel < 0.75 then return 0.85
                elseif netLevel < 1 then return 0.7
                elseif netLevel < 1.25 then return 0.65
                elseif netLevel < 1.5 then return 0.6
                elseif netLevel < 1.75 then return 0.55
                elseif netLevel < 2 then return 0.5
                elseif netLevel < 2.25 then return 0.4
                elseif netLevel < 2.5 then return 0.3
                elseif netLevel < 3 then return 0.7
                elseif netLevel < 3.25 then return 0.6
                elseif netLevel < 3.5 then return 0.5
                elseif netLevel < 3.75 then return 0.4
                elseif netLevel < 4 then return 0.3
                elseif netLevel < 4.125 then return 0.25
                elseif netLevel < 4.5 then return 0.1
                elseif netLevel < 4.75 then return 0.05
                elseif netLevel < 5 then return 1/60
                else return 0 end
            end,
            spawnDelay = function(level, points, maxPoints)
                return 0.3 - level/(game.modeFields[game.mode].levels)*0.2
            end,
            lockDelay = function(level, points, maxPoints)
                    if level < 5 then return 0.5
                elseif level < 6 then return 0.45
                elseif level < 7 then return 0.4
                elseif level < 8 then return 0.35
                else return 1/3 end
            end,
            lineClearDelay = function(level, points, maxPoints)
                return 0.5 - level/(game.modeFields[game.mode].levels)*0.4
            end,
        },
        rush = {
            points = {350, 500, 650, 800, 1000, 1200, 1500, 1800, 1900, 2000},
            gravityDelay = function(level, points, maxPoints)
                local netLevel = level + points/maxPoints
                    if netLevel < 0.5 then return 1/30
                elseif netLevel < 0.75 then return 1/60
                elseif netLevel < 1 then return 1/70
                elseif netLevel < 1.25 then return 1/80
                elseif netLevel < 1.5 then return 1/90
                elseif netLevel < 1.75 then return 1/100
                elseif netLevel < 2 then return 1/150
                elseif netLevel < 2.25 then return 1/30
                elseif netLevel < 2.5 then return 0.3
                elseif netLevel < 3 then return 0.7
                elseif netLevel < 3.25 then return 0.6
                elseif netLevel < 3.5 then return 0.5
                elseif netLevel < 3.75 then return 0.4
                elseif netLevel < 4 then return 0.3
                elseif netLevel < 4.125 then return 0.25
                elseif netLevel < 4.5 then return 0.1
                elseif netLevel < 4.75 then return 0.05
                elseif netLevel < 5 then return 1/60
                else return 0 end
            end,
            spawnDelay = function(level, points, maxPoints)
                return 0.4 - level/game.modeFields[game.mode].levels*0.2
            end,
            lockDelay = function(level, points, maxPoints)
                    if level < 5 then return 0.5
                elseif level < 6 then return 0.45
                elseif level < 7 then return 0.4
                elseif level < 8 then return 0.35
                elseif level < 9 then return 0.3
                else return 0.2 end
            end,
            lineClearDelay = function(level, points, maxPoints)
                return 0.3 - level/(game.modeFields[game.mode].levels)*0.2
            end,
        }
    },
    randomizer = {
        queue = {},
        history = {},
        generate = function(n)
            for i = 1,n do
                local piece = love.math.random(#game.pieces)
                while table.contains(game.randomizer.history, piece) do
                    piece = love.math.random(#game.pieces)
                end
                table.insert(game.randomizer.queue, piece)
                table.insert(game.randomizer.history, piece)
                if #game.randomizer.history > 5 then
                    table.remove(game.randomizer.history, 1)
                end
            end
        end,
    }
}