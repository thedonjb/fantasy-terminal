local utils         = require "src.utils"
local commands      = require "src.commands"
local state         = require "src.state"
local editor        = require "src.app.editor"
local history       = require "src.history"

local terminal      = {}
state.scroll_offset = 0

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
-- Variable Expansion
------------------------------------------------------------
local function expand_vars(str)
    return str:gsub("%$(%w+)", function(var)
        return state.vars[var] or ""
    end)
end

------------------------------------------------------------
-- Command Processing
------------------------------------------------------------
function terminal.processcommand(input)
    for sub in input:gmatch("[^;]+") do
        local args = utils.split(expand_vars(sub), " ")
        local cmd = commands[args[1]]

        if cmd then
            cmd.exec(args, state, commands)
        else
            local appname = args[1]
            if appname and appname ~= "" then
                utils.printt(state, "invalid command: " .. appname)
            else
                utils.printt(state, "invalid command: ")
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
            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                table.insert(state.command_lines, "")
            else
                local full_command = table.concat(state.command_lines, " ")
                table.insert(state.term, { prompt = state.wd .. "$ ", text = full_command })
                table.insert(state.history, 1, full_command)
                history.save()
                terminal.processcommand(full_command)
                state.history.index = 0
                state.command_lines = { "" }
                state.cursor.line = 1
                state.cursor.col = 0

                -- 🔥 force scroll to bottom
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
            if #state.history > 0 then
                if state.history.index < #state.history then
                    state.history.index = state.history.index + 1
                    local hist = state.history[state.history.index]
                    state.command_lines = { hist or "" }
                    state.cursor.line = 1
                    state.cursor.col = #state.command_lines[1]
                end
            end
        elseif key == "down" then
            if #state.history > 0 then
                if state.history.index > 1 then
                    state.history.index = state.history.index - 1
                    local hist = state.history[state.history.index]
                    state.command_lines = { hist or "" }
                    state.cursor.line = 1
                    state.cursor.col = #state.command_lines[1]
                elseif state.history.index == 1 then
                    -- reset to fresh blank line
                    state.history.index = 0
                    state.command_lines = { "" }
                    state.cursor.line = 1
                    state.cursor.col = 0
                end
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

        -- 1. Add history
        for _, line in ipairs(state.term) do
            table.insert(content, line)
        end

        -- 2. Add current command lines
        table.insert(content, { prompt = state.wd .. "$ ", text = state.command_lines[1] or "" })
        for i = 2, #state.command_lines do
            table.insert(content, { prompt = "", text = state.command_lines[i] })
        end

        -- 3. Scroll math
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
        local promptWidth = (cursor_line_index == 1) and state.font:getWidth(state.wd .. "$ ") or 0
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
