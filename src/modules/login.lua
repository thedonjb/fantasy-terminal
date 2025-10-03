local utils = require("src.utils")
local fs    = love.filesystem

return {
    name = "login",
    description = "Switch user session (only existing users). Usage: login <username> [password]",
    usage = "login <username> [password]",
    exec = function(args, state)
        local user = args[2]
        local pass = args[3]

        if not user or user == "" then
            utils.printt(state, "Usage: login <username> [password]")
            return
        end

        if user == state.current_user then
            utils.printt(state, "Already logged in as '" .. user .. "'.")
            return
        end

        local meta = rawget(state.users, user)
        if not meta then
            utils.printt(state, "No such user: '" .. user .. "'")
            return
        end

        if meta.password and meta.password ~= "" then
            if not pass then
                utils.printt(state, "Password required for user '" .. user .. "'.")
                return
            end
            if pass ~= meta.password then
                utils.printt(state, "Incorrect password for user '" .. user .. "'.")
                return
            end
        end

        local user_home = state.fsroot .. "home/" .. user .. "/"
        if not fs.getInfo(user_home) then
            utils.printt(state, "Home directory missing for user '" .. user .. "'.")
            return
        end

        utils.switch_user(state, user, user_home)
        utils.printt(state, "Logged in as '" .. user .. "'")

        if user == "root" and meta.password == "changeme" then
            utils.printt(state,
                "⚠ WARNING: root still has the default password 'changeme'. Use 'passwd root <newpassword>' to change it.")
        end
    end
}
