local utils = require("src.utils")

return {
    name = "whoami",
    description = "Print the current user",
    usage = "whoami",
    exec = function(_, state)
        utils.printt(state, state.vars.USER or "guest")
    end
}
