return {
    name = "clear",
    description = "Clear the terminal output",
    usage = "clear",
    exec = function(_, state)
        state.term = {}
    end
}
