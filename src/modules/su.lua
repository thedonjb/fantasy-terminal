local utils = require("src.utils")

return {
    name = "su",
    description = "Switch user session (defaults to root). Usage: su [username]",
    usage = "su [username]",
    exec = function(args, state)
        local target = args[2] or "root"

        if state.current_user == target then
            utils.printt(state, "Already running as '" .. target .. "'.")
            return
        end

        local meta = rawget(state.users, target)
        if not meta then
            utils.printt(state, "Error: user '" .. target .. "' does not exist.")
            return
        end

        if meta.password and meta.password ~= "" then
            local pass = args[3]
            if not pass then
                utils.printt(state, "Password required. Usage: su " .. target .. " <password>")
                return
            end
            if pass ~= meta.password then
                utils.printt(state, "Incorrect password for user '" .. target .. "'.")
                return
            end
        end

        utils.switch_user(state, target)
        utils.printt(state, "Switched to user '" .. target .. "'")
    end
}
