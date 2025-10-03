local utils = require("src.utils")

return {
    name = "passwd",
    description = "Change a user's password",
    usage = "passwd [username] [newpassword]",
    exec = function(args, state)
        local target = args[2]
        local newpass = args[3]
        
        if not target then
            target = state.current_user
        end

        local meta = rawget(state.users, target)
        if not meta then
            utils.printt(state, "No such user: '" .. target .. "'")
            return
        end

        if target ~= state.current_user and state.current_user ~= "root" then
            utils.printt(state, "Permission denied. Only root may change other users’ passwords.")
            return
        end

        if not newpass then
            state.auth.mode = "password"
            state.auth.buffer = ""
            state.auth.callback = function(pass)
                meta.password = pass
                utils.printt(state, "Password updated for '" .. target .. "'.")
                if target == "root" and pass == "changeme" then
                    utils.printt(state, "⚠ WARNING: root still has default password 'changeme'.")
                end
            end
            utils.printt(state, "Enter new password for '" .. target .. "':")
            return
        end

        -- non-interactive mode
        meta.password = newpass
        utils.printt(state, "Password updated for '" .. target .. "'.")
        if target == "root" and newpass == "changeme" then
            utils.printt(state, "⚠ WARNING: root still has default password 'changeme'.")
        end
    end
}
