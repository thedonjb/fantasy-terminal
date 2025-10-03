local utils = require("src.utils")
local fs    = love.filesystem
local json  = require("dkjson")

local function save_users(state)
    local path = state.fsroot .. "etc/passwd.json"
    local ok, err = pcall(function()
        local encoded = json.encode(state.users, { indent = true })
        fs.write(path, encoded)
    end)
    if not ok then
        utils.printt(state, "⚠ Failed to save users: " .. tostring(err))
    end
end

local function load_users(state)
    local path = state.fsroot .. "etc/passwd.json"
    if fs.getInfo(path) then
        local contents = fs.read(path)
        local data, _, err = json.decode(contents)
        if data then
            for k,v in pairs(data) do
                state.users[k] = v
            end
        else
            utils.printt(state, "⚠ Failed to parse passwd.json: " .. tostring(err))
        end
    end
end

return {
    name = "useradd",
    description = "Add a new user (sudo required). Usage: useradd <username>",
    usage = "useradd <username>",
    exec = function(args, state)
        local user = args[2]

        if not user or user == "" then
            utils.printt(state, "Usage: useradd <username>")
            return
        end
        
        if state.current_user ~= "root" and not (state.users[state.current_user] and state.users[state.current_user].sudo) then
            utils.printt(state, "Permission denied. Only root or sudoers may add users.")
            return
        end
        
        if rawget(state.users, user) then
            utils.printt(state, "User '" .. user .. "' already exists.")
            return
        end
        
        local home = state.fsroot .. "home/" .. user
        if not fs.getInfo(home) then
            fs.createDirectory(home)
        end
        
        state.users[user] = { password = nil, sudo = false }
        save_users(state)

        utils.printt(state, "Created user '" .. user .. "'.")
        utils.printt(state, "Use 'passwd " .. user .. "' to set a password.")
    end,
    
    _helpers = {
        load_users = load_users,
        save_users = save_users
    }
}
