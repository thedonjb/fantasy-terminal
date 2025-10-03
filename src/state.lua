local state = {
    term = { "Welcome to Don's fantasy-terminal!", "Type 'help' for more helpful information." },
    command_lines = { "" },
    interm = true,
    vars = {},
    wd = "/",
    tinc = "█",
    history = {},
    font = nil,
    scale = 1.0,
    cursor = {
        line = 1,
        col = 0
    },
    commands = {},
    history_limit_kb = 256
}

state.history.index = 0

return state
