manifest = {
    name = "fortune",
    version = "2.1.0",
    description = "Classic fortune command with timeless one-liners."
}

function exec(args, state)
    local fortunes = {
        "You will soon embark on a great journey.",
        "The solution is simple… but not easy.",
        "He who laughs last probably made a backup.",
        "A watched program never compiles.",
        "To err is human. To debug, divine.",
        "Success is a typo away.",
        "You will overcome that which you haven’t yet tried.",
        "A clear conscience is usually a sign of a bad memory.",
        "The fortune you seek is in another terminal.",
        "Never test for an error condition you don't know how to handle.",
        "Every exit is an entry somewhere else.",
        "Don't panic.",
        "Any sufficiently advanced bug is indistinguishable from a feature.",
        "There's always one more bug.",
        "Time flies like an arrow. Fruit flies like a banana.",
        "Good judgement comes from experience. Experience comes from bad judgement.",
        "One man's constant is another man's variable.",
        "The best way to predict the future is to invent it.",
        "You will meet a tall, dark segfault.",
        "A user interface is like a joke. If you have to explain it, it's not that good.",
        "You cannot step into the same river twice.",
        "Happiness is a warm pointer.",
        "Real programmers count from 0.",
        "Fortune favors the bold.",
        "There is no place like 127.0.0.1.",
        "Beware of bugs in the above code; I have only proved it correct, not tried it.",
        "The road to wisdom? — Well, it's plain and simple to express: err and err and err again but less and less and less.",
        "It's not a bug. It's an undocumented feature.",
        "Nothing is foolproof to a sufficiently talented fool.",
        "This line intentionally left blank.",
        "Keep it simple.",
        "Don’t comment bad code — rewrite it.",
        "Simplicity is the soul of efficiency.",
        "The best way out is always through.",
        "Sometimes it pays to stay in bed on Monday, rather than spending the rest of the week debugging Monday’s code.",
        "Software is like entropy: it is difficult to grasp, weighs nothing, and obeys the Second Law of Thermodynamics; i.e., it always increases.",
        "Weeks of programming can save you hours of planning.",
        "If it compiles, ship it.",
        "Fast, good, cheap: pick any two.",
        "First, solve the problem. Then, write the code.",
        "Deleted code is debugged code.",
        "You miss 100% of the shots you don't take.",
        "Always code as if the person who ends up maintaining your code is a violent psychopath who knows where you live.",
        "Never attribute to malice that which is adequately explained by stupidity.",
        "Premature optimization is the root of all evil.",
        "Experience is what you get when you didn't get what you wanted.",
        "No one knows what he can do till he tries."
    }

    local name = args[2]
    local pick = fortunes[math.random(#fortunes)]

    if name then
        fterm.print(name .. ", your fortune: " .. pick)
    else
        fterm.print("Your fortune: " .. pick)
    end
end
