local utils = require "src.utils"

local state = {
    term = { "Welcome to Don's fantasy-terminal!", "Type 'help' for more helpful information." },
    command_lines = { "" },
    interm = true,
    wd = "/",
    tinc = "█",
    font = nil,
    scale = 1.0,
    cursor = { line = 1, col = 0 },
    commands = {},
    history_limit_kb = 256,
    fsroot = "ftermfs/",
    current_user = "root",
    mode = nil,
    callback = nil,
    buffer = ""
}

state.auth = { mode = nil, callback = nil, buffer = "" }

state.histories = setmetatable({
    root = { index = 0, cmds = {} },
    guest = { index = 0, cmds = {} }
}, {
    __index = function(t, user)
        local newhist = { index = 0, cmds = {} }
        rawset(t, user, newhist)
        return newhist
    end
})

state.users = setmetatable({
    root = { password = "changeme" },
    guest = { password = nil }
}, {
    __index = function(_, _) return nil end
})

-- Base template for environments
local base_env = {
    SHELL = "fantasy-terminal",
    TERM  = "fterm",
    PATH  = "ftermfs/bin:ftermfs/usr/bin"
}

state.envs = setmetatable({
    root = (function()
        local env = utils.clone(base_env)
        env.USER = "root"
        env.HOME = state.fsroot .. "home/root/"
        env.PWD  = env.HOME
        env.PATH = env.PATH .. ":" .. env.HOME .. "bin"
        return env
    end)(),
    guest = (function()
        local env = utils.clone(base_env)
        env.USER = "guest"
        env.HOME = state.fsroot .. "home/guest/"
        env.PWD  = env.HOME
        env.PATH = env.PATH .. ":" .. env.HOME .. "bin"
        return env
    end)()
}, {
    __index = function(t, user)
        local env = utils.clone(base_env)
        local home = state.fsroot .. "home/" .. user .. "/"
        env.USER = user
        env.HOME = home
        env.PWD  = home
        env.PATH = env.PATH .. ":" .. home .. "bin"
        rawset(t, user, env)
        return env
    end
})

setmetatable(state, {
    __index = function(t, k)
        if k == "vars" then
            return t.envs[t.current_user]
        end
    end
})

state.home = state.envs[state.current_user].HOME
state.wd = state.home

return state
