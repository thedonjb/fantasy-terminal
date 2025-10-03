local test_mode = false
for _, a in ipairs(arg) do
    if a == "--test" then
        test_mode = true
        break
    end
end

if test_mode then
    require("tests.runner")
else
    require("src.init")
end
