manifest = {
    name = "8ball",
    version = "1.0.0",
    description = "Ask the mystical 8-Ball a yes/no question."
}

function exec(args, state)
    local responses = {
        "Yes.",
        "No.",
        "Maybe.",
        "Ask again later.",
        "It is certain.",
        "Very doubtful.",
        "Without a doubt.",
        "Better not tell you now.",
        "Outlook good.",
        "My sources say no.",
        "Yes, definitely.",
        "Don't count on it.",
        "Signs point to yes.",
        "Cannot predict now.",
        "Concentrate and ask again."
    }

    if not args[2] then
        fterm.print("Usage: 8ball [your question]")
        return
    end

    local pick = responses[math.random(#responses)]
    fterm.print("🎱 " .. pick)
end
