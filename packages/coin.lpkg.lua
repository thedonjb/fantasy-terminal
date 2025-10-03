manifest = {
    name = "coin",
    version = "1.0.0",
    description = "Flip a coin — heads or tails."
}

function exec(args, state)
    local result = (math.random(2) == 1) and "Heads" or "Tails"
    local name = args[2]

    if name then
        fterm.print(name .. ", the coin lands on: " .. result)
    else
        fterm.print("The coin lands on: " .. result)
    end
end
