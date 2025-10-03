local utils = require("src.utils")

return {
    name = "echo",
    description = "Print text to the terminal",
    usage = "echo [text...]",
    exec = function(args, state)
        local text = table.concat(args, " ", 2)
        utils.printt(state, text)
    end
}
