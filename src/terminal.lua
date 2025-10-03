local utils         = require "src.utils"
local commands      = require "src.commands"
local state         = require "src.state"
local editor        = require "src.app.editor"
local history       = require "src.history"

local terminal      = {}
state.scroll_offset = 0

local function getPrompt()
    local wd = state.wd
    if state.home and wd:sub(1, #state.home) == state.home then
        wd = "~" .. wd:sub(#state.home + 1)
        if wd == "~" then wd = "~" end
    end
    return state.current_user .. "@" .. wd .. "$ "
end

------------------------------------------------------------
-- Cursor Handling
------------------------------------------------------------
local function clampCursor()
    local idx = state.cursor.line
    if idx < 1 then idx = 1 end
    if idx > #state.command_lines then idx = #state.command_lines end
    state.cursor.line = idx

    local line = state.command_lines[idx] or ""
    if state.cursor.col > #line then
        state.cursor.col = #line
    end
    if state.cursor.col < 0 then
        state.cursor.col = 0
    end
end

------------------------------------------------------------
-- Variable Expansion (+ ~ expansion for home)
------------------------------------------------------------
local function expand_vars(str)
    -- expand ~ to current user's home
    if state.home then
        str = str:gsub("(^|[%s])~", function(prefix)
            return prefix .. state.home
        end)
    end

    -- replace $VARS
    str = str:gsub("%$(%w+)", function(var)
        return state.vars[var] or ""
    end)

    return str
end

------------------------------------------------------------
-- Expand globs (e.g. *.txt, ?.lua)
------------------------------------------------------------
local function expand_globs(args)
    local expanded = {}
    for _, arg in ipairs(args) do
        if arg:find("[%*%?]") then
            -- convert glob to Lua pattern
            local pattern = "^" .. arg
                :gsub("%%", "%%%%")
                :gsub("%.", "%%.")
                :gsub("%*", ".*")
                :gsub("%?", ".") .. "$"

            local matches = {}
            for _, f in ipairs(love.filesystem.getDirectoryItems(state.wd)) do
                if f:match(pattern) then
                    table.insert(matches, f)
                end
            end

            if #matches > 0 then
                for _, m in ipairs(matches) do
                    table.insert(expanded, m)
                end
            else
                table.insert(expanded, arg) -- no match, keep literal
            end
        else
            table.insert(expanded, arg)
        end
    end
    return expanded
end

------------------------------------------------------------
-- Command Processing
------------------------------------------------------------
function terminal.processcommand(input)
    for sub in input:gmatch("[^;]+") do
        local args = utils.split(expand_vars(sub), " ")
        args = expand_globs(args)

        local cmdname = args[1]
        if not cmdname or cmdname == "" then
            utils.printt(state, "invalid command: ")
        else
            local executed = false

            local cmd = commands[cmdname]
            if cmd then
                cmd.exec(args, state, commands)
                executed = true
            else
                for dir in state.vars.PATH:gmatch("[^:]+") do
                    local candidate = dir .. "/" .. cmdname .. ".lua"
                    if love.filesystem.getInfo(candidate, "file") then
                        local chunk, err = love.filesystem.load(candidate)
                        if not chunk then
                            utils.printt(state, "exec: error loading " .. candidate .. ": " .. tostring(err))
                        else
                            local ok, res = pcall(chunk)
                            if not ok then
                                utils.printt(state, "exec: error running " .. candidate .. ": " .. tostring(res))
                            elseif type(res) == "table" and res.exec then
                                res.exec(args, state, commands)
                            else
                                utils.printt(state, "exec: " .. candidate .. " is not a valid command module")
                            end
                        end
                        executed = true
                        break
                    end
                end
            end

            if not executed then
                utils.printt(state, "invalid command: " .. cmdname)
            end
        end
    end
end

------------------------------------------------------------
-- Input Handling
------------------------------------------------------------
function terminal.keypressed(key)
    if key == "escape" then love.event.quit() end
    if state.interm then
        if key == "return" then
            -- 🔒 Password entry mode
            if state.auth.mode == "password" then
                local password = state.auth.buffer
                local cb = state.auth.callback
                state.auth.buffer = ""
                state.auth.mode = nil
                state.auth.callback = nil

                if cb then cb(password) end
                return
            end

            -- 🔤 Multi-line mode (Shift+Enter)
            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                table.insert(state.command_lines, "")
            else
                local full_command = table.concat(state.command_lines, " ")

                -- echo into terminal
                table.insert(state.term, { prompt = getPrompt(), text = full_command })

                -- save into user history
                local h = state.histories[state.current_user]
                h.cmds = h.cmds or {} -- ensure cmds table exists
                table.insert(h.cmds, 1, full_command)
                h.index = 0

                -- persist history (needs updated history.lua for per-user!)
                history.save()

                -- run the command
                terminal.processcommand(full_command)

                -- reset input line
                state.command_lines = { "" }
                state.cursor.line = 1
                state.cursor.col = 0

                -- force scroll
                state.auto_scroll = true
            end
        elseif key == "backspace" then
            local idx = state.cursor.line
            local col = state.cursor.col
            local line = state.command_lines[idx]
            if col > 0 then
                state.command_lines[idx] = line:sub(1, col - 1) .. line:sub(col + 1)
                state.cursor.col = col - 1
            elseif idx > 1 then
                local prev = table.remove(state.command_lines, idx)
                idx = idx - 1
                state.cursor.line = idx
                state.cursor.col = #state.command_lines[idx]
                state.command_lines[idx] = state.command_lines[idx] .. prev
            end
            clampCursor()
            state.auto_scroll = true
        elseif key == "up" then
            local h = state.histories[state.current_user]
            h.cmds = h.cmds or {}
            if #h.cmds > 0 and h.index < #h.cmds then
                h.index = h.index + 1
                local hist = h.cmds[h.index]
                state.command_lines = { hist or "" }
                state.cursor.line = 1
                state.cursor.col = #state.command_lines[1]
            end
        elseif key == "down" then
            local h = state.histories[state.current_user]
            h.cmds = h.cmds or {}
            if #h.cmds > 0 and h.index < #h.cmds then
                if h.index > 1 then
                    h.index = h.index - 1
                    state.command_lines = { h.cmds[h.index] or "" }
                elseif h.index == 1 then
                    h.index = 0
                    state.command_lines = { "" }
                end
                state.cursor.line = 1
                state.cursor.col = #state.command_lines[1]
            end
        elseif key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            local clip = love.system.getClipboardText()
            if clip and #clip > 0 then
                local idx = state.cursor.line
                local col = state.cursor.col
                local line = state.command_lines[idx]
                state.command_lines[idx] = line:sub(1, col) .. clip .. line:sub(col + 1)
                state.cursor.col = col + #clip
            end
            clampCursor()
            state.auto_scroll = true
        elseif key == "u" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            state.command_lines = { "" }
            state.cursor.line = 1
            state.cursor.col = 0
        elseif key == "k" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            state.command_lines = { "" }
            state.cursor.line = 1
            state.cursor.col = 0
        elseif key == "left" then
            if state.cursor.col > 0 then
                state.cursor.col = state.cursor.col - 1
            elseif state.cursor.line > 1 then
                state.cursor.line = state.cursor.line - 1
                state.cursor.col = #state.command_lines[state.cursor.line]
            end
        elseif key == "right" then
            local line = state.command_lines[state.cursor.line]
            if state.cursor.col < #line then
                state.cursor.col = state.cursor.col + 1
            elseif state.cursor.line < #state.command_lines then
                state.cursor.line = state.cursor.line + 1
                state.cursor.col = 0
            end
        elseif key == "pageup" then
            local lineHeight = state.font:getHeight()
            local screenHeight = love.graphics.getHeight()
            state.scroll_offset = state.scroll_offset - (screenHeight / 2)
            state.auto_scroll = false
        elseif key == "pagedown" then
            local lineHeight = state.font:getHeight()
            local screenHeight = love.graphics.getHeight()
            state.scroll_offset = state.scroll_offset + (screenHeight / 2)
            local totalHeight = (#state.term + #state.command_lines) * lineHeight
            local maxScroll = math.max(0, totalHeight - (screenHeight - 16))
            if state.scroll_offset >= maxScroll then
                state.scroll_offset = maxScroll
                state.auto_scroll = true
            end
        elseif key == "home" then
            state.scroll_offset = 0
            state.auto_scroll = false
        elseif key == "end" then
            local lineHeight = state.font:getHeight()
            local screenHeight = love.graphics.getHeight()
            local totalHeight = (#state.term + #state.command_lines) * lineHeight
            local maxScroll = math.max(0, totalHeight - (screenHeight - 16))
            state.scroll_offset = maxScroll
            state.auto_scroll = true
        end
        clampCursor()
    else
        editor.keypressed(key)
    end
end

function terminal.textinput(text)
    if state.auth.mode == "password" then
        if #text == 1 then
            state.auth.buffer = state.auth.buffer .. text
        end
        return
    end

    if not state.interm then
        editor.textinput(text)
    else
        if #text == 1 then
            local idx = state.cursor.line
            local col = state.cursor.col
            local line = state.command_lines[idx]
            state.command_lines[idx] = line:sub(1, col) .. text .. line:sub(col + 1)
            state.cursor.col = col + 1
            clampCursor()
            state.auto_scroll = true
        end
    end
end

------------------------------------------------------------
-- Update & Draw
------------------------------------------------------------
function terminal.update(dt)
    if not state.interm and not editor.active then
        state.interm = true
    end

    state.tinc = (love.timer.getTime() * 1.5) % 2 > 1 and "█" or ""
end

------------------------------------------------------------
-- Terminal Draw with Scroll
------------------------------------------------------------
function terminal.draw()
    if state.interm then
        local paddingX = 8
        local paddingY = 8
        local lineHeight = state.font:getHeight()
        local screenHeight = love.graphics.getHeight()
        local content = {}

        for _, line in ipairs(state.term) do
            table.insert(content, line)
        end

        -- 🔒 If in password mode, show "Password: ****"
        if state.auth.mode == "password" then
            local mask = string.rep("*", #state.auth.buffer)
            table.insert(content, { prompt = "Password: ", text = mask })
        else
            table.insert(content, { prompt = getPrompt(), text = state.command_lines[1] or "" })
            for i = 2, #state.command_lines do
                table.insert(content, { prompt = "", text = state.command_lines[i] })
            end
        end

        local totalHeight = #content * lineHeight
        local maxScroll   = math.max(0, totalHeight - (screenHeight - 2 * paddingY))

        if state.auto_scroll ~= false then
            state.scroll_offset = maxScroll
        end
        state.scroll_offset = math.max(0, math.min(state.scroll_offset, maxScroll))

        -- 4. Draw all lines
        local y = paddingY - state.scroll_offset
        for _, line in ipairs(content) do
            if type(line) == "table" then
                love.graphics.print(line.prompt, paddingX, y)
                love.graphics.print(line.text, paddingX + state.font:getWidth(line.prompt), y)
            else
                love.graphics.print(line, paddingX, y)
            end
            y = y + lineHeight
        end

        -- 5. Draw cursor
        local cursor_line_index = state.cursor.line
        local cursor_y = paddingY + (#state.term + cursor_line_index - 1) * lineHeight - state.scroll_offset
        local promptWidth = (cursor_line_index == 1) and state.font:getWidth(getPrompt()) or 0
        local cursor_text = state.command_lines[cursor_line_index]:sub(1, state.cursor.col)
        local cursor_x = paddingX + promptWidth + state.font:getWidth(cursor_text)
        love.graphics.print(state.tinc, cursor_x, cursor_y)

        -- 6. Draw scrollbar
        if maxScroll > 0 then
            local barWidth = 8
            local barX = love.graphics.getWidth() - barWidth - 2
            local barHeight = (screenHeight / totalHeight) * (screenHeight - 2 * paddingY)
            local barY = (state.scroll_offset / maxScroll) * ((screenHeight - 2 * paddingY) - barHeight) + paddingY
            love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
        end
    else
        editor.draw()
    end
end

------------------------------------------------------------
-- Scroll Handling
------------------------------------------------------------
function terminal.wheelmoved(x, y)
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        state.scale = state.scale + y * 0.1
        state.scale = math.max(0.5, math.min(state.scale, 3.0))
        local baseSize = 14
        local newSize = math.max(8, math.floor(baseSize * state.scale))
        state.font = love.graphics.newFont("src/assets/jbmono.ttf", newSize)
        love.graphics.setFont(state.font)
    else
        local lineHeight = state.font:getHeight()
        state.scroll_offset = state.scroll_offset - y * lineHeight * 3
        state.auto_scroll = false
    end
end

return terminal
