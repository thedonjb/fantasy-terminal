manifest = {
    name = "roll",
    version = "1.0.0",
    description = "Rolls dice in NdM format (e.g., 2d6 for two six-sided dice)."
}

function exec(args, state)
    local input = args[2] or "1d6"
    local n, m = string.match(input, "(%d+)[dD](%d+)")
    n, m = tonumber(n), tonumber(m)

    if not n or not m or n < 1 or m < 1 then
        fterm.print("Usage: roll NdM (e.g., roll 2d6)")
        return
    end

    local results = {}
    local total = 0
    for i = 1, n do
        local roll = math.random(1, m)
        table.insert(results, roll)
        total = total + roll
    end

    if n == 1 then
        fterm.print("You rolled a " .. results[1] .. " (d" .. m .. ")")
    else
        fterm.print("You rolled: " .. table.concat(results, ", ") .. " (total = " .. total .. ")")
    end
end
