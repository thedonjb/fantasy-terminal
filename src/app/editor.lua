-- Essential nano-like in-game editor

local parser = require("src.env.parser")
local editor = {}

editor.active = false
editor.filename = ""
editor.lines = {}
editor.cursor = { line = 1, col = 1 }
editor.scroll = 0
editor.message = ""
editor.messageTime = 0
editor.clipboard = {}
editor.dirty = false

editor.mode = "normal" -- can be "normal" or "prompt"
editor.prompt = { text = "", type = nil }

editor.showCompletions = false
editor.completions = {}
editor.completionIndex = 1

if not parser._built then
    parser.build()
    parser._built = true
end

-- CONFIG
local margin = 2
local helpbarHeight = 2
local statusHeight = 1
local fg, bg = { 1, 1, 1 }, { 0.1, 0.1, 0.1 }
local hl = { 0.2, 0.2, 0.4 }

local function setMessage(msg)
    editor.message = msg
    editor.messageTime = love.timer.getTime()
end

function editor.open(filename)
    editor.allCompletions = parser.getCompletions("")

    editor.active = true
    editor.filename = filename
    editor.lines = {}
    editor.cursor = { line = 1, col = 1 }
    editor.scroll = 0
    editor.dirty = false
    editor.mode = "normal"

    if love.filesystem.getInfo(filename) then
        local content = love.filesystem.read(filename)
        for line in content:gmatch("([^\n]*)\n?") do
            table.insert(editor.lines, line)
        end
    else
        editor.lines[1] = ""
    end
end

function editor.save()
    local content = table.concat(editor.lines, "\n")
    love.filesystem.write(editor.filename, content)
    editor.dirty = false
    setMessage("Wrote " .. #editor.lines .. " lines")
end

function editor.exit()
    if editor.dirty then
        setMessage("Unsaved changes! Press ^X again to force quit.")
        editor.dirty = false -- soft reset for double press
    else
        editor.active = false
    end
end

local function deleteChar()
    local line = editor.lines[editor.cursor.line] or ""
    if editor.cursor.col > 1 then
        local idx = editor.cursor.col - 1
        editor.lines[editor.cursor.line] =
            line:sub(1, idx - 1) .. line:sub(idx + 1)
        editor.cursor.col = idx
    elseif editor.cursor.line > 1 then
        -- merge with previous line
        local prev = editor.lines[editor.cursor.line - 1]
        editor.cursor.col = #prev + 1
        editor.lines[editor.cursor.line - 1] = prev .. line
        table.remove(editor.lines, editor.cursor.line)
        editor.cursor.line = editor.cursor.line - 1
    end
    editor.dirty = true
end

function editor.keypressed(key)
    local ctrl = love.keyboard.isDown("lctrl", "rctrl")

    -- Handle completions navigation

    if editor.showCompletions and #editor.completions > 0 then
        local line = editor.lines[editor.cursor.line] or ""
        if key == "down" then
            editor.completionIndex = editor.completionIndex % #editor.completions + 1
            return
        elseif key == "up" then
            editor.completionIndex = (editor.completionIndex - 2) % #editor.completions + 1
            return
        elseif key == "return" or key == "tab" then
            local choice = editor.completions[editor.completionIndex]
            if type(choice) == "table" then
                choice = choice.name
            end

            local line = editor.lines[editor.cursor.line]
            local before = line:sub(1, editor.cursor.col - 1)
            local after = line:sub(editor.cursor.col)

            -- find the current word before the cursor
            local prefixStart, prefix = before:find("([%w_]+)$")
            if prefixStart then
                -- replace prefix with the chosen completion
                local newBefore = before:sub(1, prefixStart - 1) .. choice
                editor.lines[editor.cursor.line] = newBefore .. after
                editor.cursor.col = #newBefore + 1
            else
                -- fallback: just insert choice
                editor.lines[editor.cursor.line] = before .. choice .. after
                editor.cursor.col = editor.cursor.col + #choice
            end

            editor.showCompletions = false
            return
        elseif key == "escape" then
            editor.showCompletions = false
            return
        elseif key == "backspace" then
            deleteChar()

            -- 🔑 Re-run completion logic after backspace
            local before = editor.lines[editor.cursor.line]:sub(1, editor.cursor.col - 1)
            local word = before:match("([%w_%.]+)$")
            if word then
                local prefix, partial = word:match("^(.-)%.([%w_]*)$")
                if prefix then
                    editor.completions = parser.getCompletions(prefix .. ".")
                    if partial ~= "" then
                        local filtered = {}
                        for _, c in ipairs(editor.completions) do
                            if c.name:find("^" .. partial) then
                                table.insert(filtered, c)
                            end
                        end
                        editor.completions = filtered
                    end
                else
                    editor.completions = {}
                    for _, c in ipairs(parser.getCompletions("")) do
                        if c.name:find("^" .. word) then
                            table.insert(editor.completions, c)
                        end
                    end
                end
                editor.showCompletions = #editor.completions > 0
                editor.completionIndex = 1
            else
                editor.showCompletions = false
            end
        end
    end

    if editor.mode == "prompt" then
        if key == "return" then
            if editor.prompt.type == "goto" then
                local line = tonumber(editor.prompt.text)
                if line then
                    editor.cursor.line = math.max(1, math.min(line, #editor.lines))
                    editor.cursor.col = 1
                end
            elseif editor.prompt.type == "search" then
                local search = editor.prompt.text:lower()
                for i = editor.cursor.line, #editor.lines do
                    if editor.lines[i]:lower():find(search, 1, true) then
                        editor.cursor.line = i
                        editor.cursor.col = 1
                        break
                    end
                end
            end
            editor.mode = "normal"
            editor.prompt.text = ""
            editor.prompt.type = nil
            return
        elseif key == "backspace" then
            editor.prompt.text = editor.prompt.text:sub(1, -2)
            return
        end
    end

    if ctrl then
        if key == "x" then
            editor.exit()
        elseif key == "o" then
            editor.save()
        elseif key == "k" then
            editor.clipboard = { editor.lines[editor.cursor.line] }
            table.remove(editor.lines, editor.cursor.line)
            if #editor.lines == 0 then editor.lines[1] = "" end
            editor.cursor.line = math.min(editor.cursor.line, #editor.lines)
            editor.cursor.col = 1
            editor.dirty = true
        elseif key == "u" then
            table.insert(editor.lines, editor.cursor.line + 1, editor.clipboard[1] or "")
            editor.cursor.line = editor.cursor.line + 1
            editor.cursor.col = 1
            editor.dirty = true
        elseif key == "y" then
            editor.cursor.line = math.max(1, editor.cursor.line - 20)
        elseif key == "v" then
            editor.cursor.line = math.min(#editor.lines, editor.cursor.line + 20)
        elseif key == "a" then
            editor.cursor.col = 1
        elseif key == "e" then
            editor.cursor.col = #editor.lines[editor.cursor.line] + 1
        elseif key == "_" then
            editor.mode = "prompt"
            editor.prompt = { text = "", type = "goto" }
        elseif key == "w" or key == "f" then
            editor.mode = "prompt"
            editor.prompt = { text = "", type = "search" }
        elseif key == "c" then
            setMessage("Line: " .. editor.cursor.line .. ", Col: " .. editor.cursor.col)
        end
        return
    end

    local line = editor.lines[editor.cursor.line]
    if key == "return" then
        local before = line:sub(1, editor.cursor.col - 1)
        local after = line:sub(editor.cursor.col)
        editor.lines[editor.cursor.line] = before
        table.insert(editor.lines, editor.cursor.line + 1, after)
        editor.cursor.line = editor.cursor.line + 1
        editor.cursor.col = 1
        editor.dirty = true
    elseif key == "backspace" then
        deleteChar()
    elseif key == "left" then
        if editor.cursor.col > 1 then
            editor.cursor.col = editor.cursor.col - 1
        elseif editor.cursor.line > 1 then
            editor.cursor.line = editor.cursor.line - 1
            editor.cursor.col = #editor.lines[editor.cursor.line] + 1
        end
    elseif key == "right" then
        if editor.cursor.col <= #line then
            editor.cursor.col = editor.cursor.col + 1
        elseif editor.cursor.line < #editor.lines then
            editor.cursor.line = editor.cursor.line + 1
            editor.cursor.col = 1
        end
    elseif key == "up" then
        if editor.cursor.line > 1 then
            editor.cursor.line = editor.cursor.line - 1
            editor.cursor.col = math.min(editor.cursor.col, #editor.lines[editor.cursor.line] + 1)
        end
    elseif key == "down" then
        if editor.cursor.line < #editor.lines then
            editor.cursor.line = editor.cursor.line + 1
            editor.cursor.col = math.min(editor.cursor.col, #editor.lines[editor.cursor.line] + 1)
        end
    end
end

function editor.textinput(text)
    if editor.mode == "prompt" then
        editor.prompt.text = editor.prompt.text .. text
        return
    end

    local line = editor.lines[editor.cursor.line]
    editor.lines[editor.cursor.line] =
        line:sub(1, editor.cursor.col - 1) .. text .. line:sub(editor.cursor.col)
    editor.cursor.col = editor.cursor.col + #text
    editor.dirty = true

    local before = editor.lines[editor.cursor.line]:sub(1, editor.cursor.col - 1)
    local word = before:match("([%w_%.]+)$")

    if word then
        local prefix, partial = word:match("^(.-)%.([%w_]*)$")
        if prefix then
            -- completing object members (e.g. fterm., state., etc.)
            editor.completions = parser.getCompletions(prefix .. ".")
            if partial ~= "" then
                local filtered = {}
                for _, c in ipairs(editor.completions) do
                    if c.name:find("^" .. partial) then
                        table.insert(filtered, c)
                    end
                end
                editor.completions = filtered
            end
        else
            -- completing globals (fterm, state, etc.)
            editor.completions = {}
            for _, c in ipairs(parser.getCompletions("")) do
                if c.name:find("^" .. word) then
                    table.insert(editor.completions, c)
                end
            end
        end

        if #editor.completions > 0 then
            editor.showCompletions = true
            editor.completionIndex = 1
        else
            editor.showCompletions = false
        end
    else
        editor.showCompletions = false
    end
end

function editor.draw()
    love.graphics.clear(bg)
    love.graphics.setColor(fg)
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight()
    local winH = love.graphics.getHeight()
    local usableLines = math.floor((winH / lineHeight) - helpbarHeight - statusHeight)

    local first = math.max(1, editor.cursor.line - math.floor(usableLines / 2))
    local last = math.min(#editor.lines, first + usableLines - 1)

    for i = first, last do
        if i == editor.cursor.line then
            love.graphics.setColor(hl)
            love.graphics.rectangle("fill", 0, (i - first) * lineHeight, love.graphics.getWidth(), lineHeight)
            love.graphics.setColor(fg)
        end
        love.graphics.print(editor.lines[i], margin, (i - first) * lineHeight)
    end

    local cx = margin + font:getWidth(editor.lines[editor.cursor.line]:sub(1, editor.cursor.col - 1))
    local cy = (editor.cursor.line - first) * lineHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, 2, lineHeight)

    -- IntelliSense popup
    if editor.showCompletions and #editor.completions > 0 then
        local popupX = cx + 10
        local popupY = cy + font:getHeight()

        -- Build label strings from completion objects
        local labels = {}
        local maxw = 0
        for _, c in ipairs(editor.completions) do
            local label = c.name
            if c.type then label = label .. " : " .. c.type end
            if c.desc then label = label .. " — " .. c.desc end
            table.insert(labels, label)
            maxw = math.max(maxw, font:getWidth(label))
        end

        local boxH = math.min(5, #labels) * font:getHeight()

        -- Flip upward if bottom would overflow
        if popupY + boxH + 4 > winH then
            popupY = cy - boxH - 4
        end

        -- Background box
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", popupX, popupY, maxw + 8, boxH + 4)

        -- Draw completions
        for i, label in ipairs(labels) do
            local itemY = popupY + (i - 1) * font:getHeight()
            if i == editor.completionIndex then
                love.graphics.setColor(0.4, 0.4, 0.6, 1)
                love.graphics.rectangle("fill", popupX, itemY, maxw + 8, font:getHeight())
            end
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(label, popupX + 4, itemY)
        end
    end

    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", 0, winH - (helpbarHeight + statusHeight) * lineHeight, love.graphics.getWidth(),
        statusHeight * lineHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("File: " .. editor.filename .. (editor.dirty and " (modified)" or ""), margin,
        winH - (helpbarHeight + statusHeight) * lineHeight)

    local help1 = "^G Help  ^O Save  ^X Exit  ^K Cut  ^U Paste  ^W Find  ^_ Goto  ^C Pos"
    love.graphics.setColor(0, 0.5, 0)
    love.graphics.rectangle("fill", 0, winH - helpbarHeight * lineHeight, love.graphics.getWidth(),
        helpbarHeight * lineHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(help1, margin, winH - (helpbarHeight - 1) * lineHeight)

    if editor.message ~= "" and (love.timer.getTime() - editor.messageTime < 3) then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(editor.message, love.graphics.getWidth() / 2 - font:getWidth(editor.message) / 2,
            winH - (helpbarHeight + statusHeight) * lineHeight)
    end

    if editor.mode == "prompt" then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 0, winH - lineHeight, love.graphics.getWidth(), lineHeight)
        love.graphics.setColor(1, 1, 1)
        local label = editor.prompt.type == "goto" and "Goto line: " or "Search: "
        love.graphics.print(label .. editor.prompt.text, margin, winH - lineHeight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return editor
