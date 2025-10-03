local utils = require("src.utils")

return {
    name = "unset",
    description = "Unset (remove) an environment variable",
    usage = "unset <key>",
    exec = function(args, state)
        local key = args[2]
        if not key then
            utils.printt(state, "usage: unset <key>")
            return
        end

        if state.vars[key] then
            state.vars[key] = nil
            utils.printt(state, "unset: " .. key)
        else
            utils.printt(state, "unset: variable not found: " .. key)
        end
    end
}
