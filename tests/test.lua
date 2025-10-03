local state    = require("src.state")
local terminal = require("src.terminal")

---@class TestCase
---@field name string Test name
---@field fn fun() The test function to run

---@class TestFramework
---@field tests TestCase[] List of registered tests
local test = {
    tests = {}
}

---Assert that the terminal buffer contains text
---@param term (string|{prompt?:string,text?:string})[] # The terminal buffer
---@param expected string # Text to look for
---@param msg? string # Custom error message
function test.assertContains(term, expected, msg)
    local found = false
    for _, line in ipairs(term) do
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

---Assert equality between two values
---@param a any
---@param b any
---@param msg? string
function test.assertEquals(a, b, msg)
    if a ~= b then
        error(msg or ("Expected " .. tostring(a) .. " == " .. tostring(b)))
    end
end

---Register a new test case
---@param name string
---@param fn fun()
function test.add(name, fn)
    table.insert(test.tests, { name = name, fn = fn })
end

---Run all registered tests and quit Love2D
function test.run()
    for _, t in ipairs(test.tests) do
        local ok, err = pcall(t.fn)
        if ok then
            print("[PASS] " .. t.name)
        else
            print("[FAIL] " .. t.name .. ": " .. tostring(err))
        end
    end
    love.event.quit()
end

return test
