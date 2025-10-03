local utils = require("src.utils")

return {
    name = "pwd",
    description = "Print the current working directory",
    usage = "pwd",
    exec = function(_, state)
        utils.printt(state, state.wd)
    end
}
