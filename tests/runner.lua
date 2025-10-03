local state    = require("src.state")
local terminal = require("src.terminal")

local tests = {}
local function assertContains(term, expected, msg)
    local found = false
    for _, line in ipairs(state.term) do
        if type(line) == "table" and line.text and line.text:find(expected, 1, true) then
            found = true
            break
        elseif type(line) == "string" and line:find(expected, 1, true) then
            found = true
            break
        end
    end
    if not found then
        error(msg or ("Expected output containing: " .. expected))
    end
end

table.insert(tests, {
    name = "Unknown command shows error",
    fn = function()
        state.term = {}
        terminal.processcommand("foobar")
        assertContains(state.term, "invalid command")
    end
})

table.insert(tests, {
    name = "Login root works",
    fn = function()
        state.term = {}
        state.current_user = "guest"
        state.home = state.envs.guest.HOME
        state.wd   = state.envs.guest.HOME

        terminal.processcommand("login root changeme")
        assertContains(state.term, "Logged in as 'root'")
    end
})

for _, test in ipairs(tests) do
    local ok, err = pcall(test.fn)
    if ok then
        print("[PASS] " .. test.name)
    else
        print("[FAIL] " .. test.name .. ": " .. tostring(err))
    end
end

love.event.quit()
