-- src/commands/sudo.lua
local utils = require("src.utils")

return {
    name = "sudo",
    description = "Execute a command as root",
    usage = "sudo <command> [args...]",
    exec = function(args, state, commands)
        if not args[2] then
            utils.printt(state, "Usage: sudo <command> [args...]")
            return
        end

        if state.current_user == "root" then
            table.remove(args, 1)
            local cmd = commands[args[1]]
            if cmd then
                cmd.exec(args, state, commands)
            else
                utils.printt(state, "sudo: " .. (args[1] or "") .. ": command not found")
            end
            return
        end

        local meta = state.users[state.current_user]
        if not (meta and meta.sudo) then
            utils.printt(state, "Permission denied: user '" .. state.current_user .. "' is not a sudoer.")
            return
        end

        -- require password only once per session
        if not meta.sudo_authenticated then
            local pass = args[2]
            if not pass then
                utils.printt(state, "Password required: sudo <command> (supply password as second arg on first use)")
                return
            end
            if pass ~= meta.password then
                utils.printt(state, "Sorry, try again.")
                return
            end
            meta.sudo_authenticated = true
            utils.printt(state, "User '" .. state.current_user .. "' authenticated for sudo.")
            -- drop password arg before executing
            table.remove(args, 2)
        end

        -- elevate to root
        local saved_user   = state.current_user
        local saved_home   = state.home
        local saved_wd     = state.wd

        state.current_user = "root"
        state.home         = state.envs.root.HOME
        state.wd           = state.envs.root.HOME

        table.remove(args, 1) -- remove "sudo"
        local cmd = commands[args[1]]
        if cmd then
            cmd.exec(args, state, commands)
        else
            utils.printt(state, "sudo: " .. (args[1] or "") .. ": command not found")
        end

        -- restore user
        state.current_user = saved_user
        state.home         = saved_home
        state.wd           = saved_wd
    end
}
