local utils = require("src.utils")

return {
    name = "sudoers",
    usage = "sudoers [list|add <user>|del <user>]",
    description = "Manage sudo privileges (root only).",
    exec = function(args, state)
        if state.current_user ~= "root" then
            utils.printt(state, "sudoers: permission denied (root only)")
            return
        end

        local action = args[2]

        if not action or action == "list" then
            utils.printt(state, "Sudo-enabled users:")
            local found = false
            for user, meta in pairs(state.users) do
                if meta.sudo then
                    utils.printt(state, "  " .. user)
                    found = true
                end
            end
            if not found then
                utils.printt(state, "  (none)")
            end
            return
        end

        if action == "add" then
            local target = args[3]
            if not target then
                utils.printt(state, "Usage: sudoers add <user>")
                return
            end
            local meta = state.users[target]
            if not meta then
                utils.printt(state, "sudoers: no such user: " .. target)
                return
            end
            if meta.sudo then
                utils.printt(state, target .. " is already in sudoers.")
                return
            end
            meta.sudo = true
            utils.printt(state, "Added '" .. target .. "' to sudoers.")
            return
        end

        if action == "del" then
            local target = args[3]
            if not target then
                utils.printt(state, "Usage: sudoers del <user>")
                return
            end
            local meta = state.users[target]
            if not meta then
                utils.printt(state, "sudoers: no such user: " .. target)
                return
            end
            if not meta.sudo then
                utils.printt(state, target .. " is not in sudoers.")
                return
            end
            meta.sudo = false
            meta.sudo_authenticated = false
            utils.printt(state, "Removed '" .. target .. "' from sudoers.")
            return
        end

        utils.printt(state, "Usage: sudoers [list|add <user>|del <user>]")
    end
}
