local utils = require("src.utils")

return {
    name = "env",
    description = "List all environment variables",
    usage = "env",
    exec = function(_, state)
        for k, v in pairs(state.vars) do
            utils.printt(state, k .. "=" .. v)
        end
    end
}
