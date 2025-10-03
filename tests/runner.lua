local state    = require("src.state")
local terminal = require("src.terminal")
local test     = require("tests.test")

test.add("Unknown command shows error", function()
    state.term = {}
    terminal.processcommand("foobar")
    test.assertContains(state.term, "invalid command")
end)

test.add("Login root works", function()
    state.term = {}
    state.current_user = "guest"
    state.home = state.envs.guest.HOME
    state.wd   = state.envs.guest.HOME

    terminal.processcommand("login root changeme")
    test.assertContains(state.term, "Logged in as 'root'")
end)

test.run()
