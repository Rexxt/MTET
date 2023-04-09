return {
    playSound = function(sound, volume)
        sound:stop()
        sound:setVolume(volume)
        sound:play()
    end,
    img = {
        blocks = {
            garbage = love.graphics.newImage("res/img/garbage.png"),
            ghost = love.graphics.newImage("res/img/ghost.png"),
            g = love.graphics.newImage("res/img/garbage.png"),
            i = love.graphics.newImage("res/img/I.png"),
            j = love.graphics.newImage("res/img/J.png"),
            l = love.graphics.newImage("res/img/L.png"),
            o = love.graphics.newImage("res/img/O.png"),
            s = love.graphics.newImage("res/img/S.png"),
            t = love.graphics.newImage("res/img/T.png"),
            z = love.graphics.newImage("res/img/Z.png"),
        },
        medals = {
            love.graphics.newImage("res/img/medals/F.png"),
            love.graphics.newImage("res/img/medals/D.png"),
            love.graphics.newImage("res/img/medals/C.png"),
            love.graphics.newImage("res/img/medals/B.png"),
            love.graphics.newImage("res/img/medals/A.png"),
            love.graphics.newImage("res/img/medals/S.png"),
            love.graphics.newImage("res/img/medals/M.png"),
            love.graphics.newImage("res/img/medals/GM.png"),
        }
    },
    sounds = {
        bell = love.audio.newSource("res/sounds/bell.wav", "static"), -- just before hitting a new level
        bottom = love.audio.newSource("res/sounds/bottom.wav", "static"), -- hitting the ground or kicking piece
        cursor = love.audio.newSource("res/sounds/cursor.wav", "static"), -- changing selection on the menu
        erase = love.audio.newSource("res/sounds/erase.wav", "static"), -- line clear
        fall = love.audio.newSource("res/sounds/fall.wav", "static"), -- end of line clear
        gameclear = love.audio.newSource("res/sounds/gameclear.wav", "static"), -- clearing the game
        gameover = love.audio.newSource("res/sounds/gameover.wav", "static"), -- when the game ends in a loss
        garbage = love.audio.newSource("res/sounds/garbage.wav", "static"), -- garbage appearing on screen
        go = love.audio.newSource("res/sounds/go.wav", "static"), -- 1s before starting the game
        hold = love.audio.newSource("res/sounds/hold.wav", "static"), -- putting a piece on hold
        ihs = love.audio.newSource("res/sounds/ihs.wav", "static"), -- holding a piece before it spawns
        irs = love.audio.newSource("res/sounds/irs.wav", "static"), -- rotating a piece before it spawns
        levelup = love.audio.newSource("res/sounds/levelup.wav", "static"), -- going up a level
        lock = love.audio.newSource("res/sounds/lock.wav", "static"), -- when the piece locks
        main_decide = love.audio.newSource("res/sounds/main_decide.wav", "static"), -- navigating through the menu
        medal = love.audio.newSource("res/sounds/medal.wav", "static"), -- when you up your grade
        mode_decide = love.audio.newSource("res/sounds/mode_decide.wav", "static"), -- selecting a mode
        move = love.audio.newSource("res/sounds/move.wav", "static"), -- selecting a mode
        pieces = {
            love.audio.newSource("res/sounds/piece_i.wav", "static"),
            love.audio.newSource("res/sounds/piece_j.wav", "static"),
            love.audio.newSource("res/sounds/piece_l.wav", "static"),
            love.audio.newSource("res/sounds/piece_o.wav", "static"),
            love.audio.newSource("res/sounds/piece_s.wav", "static"),
            love.audio.newSource("res/sounds/piece_t.wav", "static"),
            love.audio.newSource("res/sounds/piece_z.wav", "static"),
        },
        ready = love.audio.newSource("res/sounds/ready.wav", "static"), -- 2s before starting the game
        rotate = love.audio.newSource("res/sounds/rotate.wav", "static"), -- rotating a piece
    }
}