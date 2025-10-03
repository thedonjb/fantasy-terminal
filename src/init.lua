local state    = require "src.state"
local terminal = require "src.terminal"
local commands = require "src.commands"
local history  = require "src.history"

function love.load()
    love.window.setTitle("fantasy-terminal")
    love.window.setMode(640, 480, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    love.keyboard.setKeyRepeat(true)

    state.font = love.graphics.newFont("src/assets/jbmono.ttf", 14)
    love.graphics.setFont(state.font)

    state.fsroot = "ftermfs/"
    state.wd = state.fsroot

    local dirs = {
        state.fsroot,
        state.fsroot .. "home",
        state.fsroot .. "tmp",
        state.fsroot .. "appnet",
    }

    for _, dir in ipairs(dirs) do
        if not love.filesystem.getInfo(dir) then
            love.filesystem.createDirectory(dir)
        end
    end

    history.load()

    if commands._helpers and commands._helpers.register_appnet_apps then
        commands._helpers.register_appnet_apps(commands)
    end

    terminal.processcommand("apm rescan")

    local rc_path = state.fsroot .. "home/.ltrc"
    if love.filesystem.getInfo(rc_path) then
        local ok, err = pcall(function()
            local f = love.filesystem.newFile(rc_path)
            f:open("r")
            local contents = f:read()
            f:close()

            if contents and #contents > 0 then
                for line in contents:gmatch("[^\r\n]+") do
                    if line:match("%S") then
                        table.insert(state.term, { prompt = state.wd .. "$ ", text = line })
                        terminal.processcommand(line)
                    end
                end
            end
        end)

        if not ok then
            table.insert(state.term, { prompt = "", text = "⚠ Failed to execute ~/.ltrc: " .. tostring(err) })
        end
    end
end

function love.keypressed(key, sc, isrepeat)
    terminal.keypressed(key)
end

function love.textinput(text)
    terminal.textinput(text)
end

function love.update(dt)
    terminal.update(dt)
end

function love.draw()
    terminal.draw()
end

function love.wheelmoved(x, y)
    if terminal.wheelmoved then
        terminal.wheelmoved(x, y)
    end
end

function love.quit()
    history.save()
end
