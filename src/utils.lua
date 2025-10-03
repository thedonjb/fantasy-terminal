local utils = {}

function utils.split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function utils.clone(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = utils.clone(v)
    end
    return copy
end

function utils.printt(state, text)
    for _, line in ipairs(utils.split(text, "\n")) do
        table.insert(state.term, line)
    end
end

function utils.switch_user(state, user, home)
    -- ensure terminal buffer always exists
    state.term          = state.term or {}

    state.current_user  = user
    state.home          = home or (state.fsroot .. "home/" .. user .. "/")
    state.wd            = state.home

    -- force env/history creation
    local _             = state.envs[user]
    local h             = state.histories[user]

    -- reset per-session input
    state.command_lines = { "" }
    state.cursor.line   = 1
    state.cursor.col    = 0
    h.index             = 0

    -- refresh vars
    state.vars.USER     = user
    state.vars.HOME     = state.home
    state.vars.PWD      = state.wd
end

function utils.register_command(commands_table, name, path)
    -- full system path using save directory
    local fullpath = love.filesystem.getSaveDirectory() .. "/" .. path
    local f = io.open(fullpath, "r")
    if not f then
        return false, "Could not open file: " .. fullpath
    end

    local code = f:read("*a")
    f:close()

    local chunk, err = loadstring(code)
    if not chunk then
        return false, "Failed to load chunk: " .. tostring(err)
    end

    local command = {
        name = name,
        description = "AppNet-installed command",
        usage = name .. " [args]",
        exec = function(args, state)
            local env = {
                args = args,
                fterm = {
                    print = function(msg) utils.printt(state, msg) end,
                    clear = function() state.term = {} end,
                    state = state,
                    fs = love.filesystem,
                },
                ipairs = ipairs,
                pairs = pairs,
                type = type,
                tostring = tostring,
                tonumber = tonumber,
                string = string,
                table = table,
                math = math,
                os = { clock = os.clock, difftime = os.difftime, time = os.time },
                print = function(msg) utils.printt(state, tostring(msg)) end
            }

            setmetatable(env, { __index = _G })
            setfenv(chunk, env)

            local ok, runtime_err = pcall(chunk)
            if not ok then
                utils.printt(state, "App crashed: " .. tostring(runtime_err))
                return
            end

            if type(env.exec) == "function" then
                local success, err = pcall(env.exec, args, state)
                if not success then
                    utils.printt(state, "App error: " .. tostring(err))
                end
            else
                utils.printt(state, "No exec() found in package.")
            end
        end
    }

    commands_table[name] = command
    return true
end

function utils.rmdir(path)
    local items = love.filesystem.getDirectoryItems(path)
    for _, item in ipairs(items) do
        local sub = path .. "/" .. item
        local subinfo = love.filesystem.getInfo(sub)
        if subinfo.type == "file" then
            love.filesystem.remove(sub)
        elseif subinfo.type == "directory" then
            utils.rmdir(sub)
        end
    end
    love.filesystem.remove(path)
end

return utils
