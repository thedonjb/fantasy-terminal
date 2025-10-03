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

local function get_history_path(user)
    return state.fsroot .. "home/" .. user .. "/.history"
end

function history.load(user)
    user = user or state.current_user
    local path = get_history_path(user)
    if fs.getInfo(path) then
        local data = fs.read(path)
        local lines = {}
        for line in data:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        state.histories[user] = { index = 0, lines = lines }
    else
        state.histories[user] = { index = 0, lines = {} }
    end
end

function history.save(user)
    user = user or state.current_user
    local hist = state.histories[user]
    if not hist or not hist.lines then return end
    local out = table.concat(hist.lines, "\n")
    fs.write(get_history_path(user), out)
end

return history
