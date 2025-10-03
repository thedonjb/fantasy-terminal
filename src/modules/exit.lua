return {
    name = "exit",
    description = "Exit the terminal.",
    usage = "exit",
    exec = function(args, state)
        love.event.quit()
    end
}