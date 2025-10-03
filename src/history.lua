local fs    = love.filesystem
local state = require("src.state")

local history = {}

local function trim()
    local limit_bytes = (state.history_limit_kb or 256) * 1024
    local total = 0
    local trimmed = {}

    for _, line in ipairs(state.history) do
        total = total + #line
        table.insert(trimmed, line)
        if total > limit_bytes then
            break
        end
    end

    state.history = trimmed
    state.history.index = 0
end

function history.load()
    if fs.getInfo("history.txt") then
        local data = fs.read("history.txt")
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        state.history = lines
        state.history.index = 0
        trim()
    end
end

function history.save()
    trim()
    local out = table.concat(state.history, "\n")
    fs.write("history.txt", out)
end

return history
