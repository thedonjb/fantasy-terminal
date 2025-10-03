local utils = require("src.utils")

return {
    name = "set",
    description = "Set or view environment variables",
    usage = "set [key] [value]",
    exec = function(args, state)
        if args[2] and args[3] then
            state.vars[args[2]] = args[3]
            utils.printt(state, args[2] .. "=" .. args[3])
        else
            for k, v in pairs(state.vars) do
                utils.printt(state, k .. "=" .. v)
            end
        end
    end
}
