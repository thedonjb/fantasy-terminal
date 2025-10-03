local utils = require("src.utils")

return {
    name = "history",
    description = "Show last commands (bottom to top)",
    usage = "history [count]",
    exec = function(args, state)
        local count = tonumber(args[2]) or 10
        local total = #state.history
        local last = math.min(count, total)

        for i = last, 1, -1 do
            local cmd = state.history[i]
            utils.printt(state, string.format("%4d  %s", total - i + 1, cmd))
        end
    end
}
