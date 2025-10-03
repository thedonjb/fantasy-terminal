local utils   = require("src.utils")
local fs      = love.filesystem
local state   = require("src.state")

-- Commands live in state
local commands = state.commands

------------------------------------------------------------
-- Register built-in modules
------------------------------------------------------------
local function register_builtin_modules(commands_table)
    local base = "src/modules"
    if not fs.getInfo(base) then
        print("[commands] No built-in modules found")
        return
    end

    for _, file in ipairs(fs.getDirectoryItems(base)) do
        if file:sub(-4) == ".lua" then
            local name = file:sub(1, -5)
            local ok, mod = pcall(require, base:gsub("/", ".") .. "." .. name)
            if ok and type(mod) == "table" then
                commands_table[mod.name or name] = mod
                print("[commands] Registered built-in:", mod.name or name)
            else
                print("[commands] Failed to load:", name, mod)
            end
        end
    end
end

------------------------------------------------------------
-- Bootstrapping
------------------------------------------------------------
register_builtin_modules(commands)

-- Expose helpers (in case you want dynamic reloading later)
commands._helpers = {
    register_builtin = register_builtin_modules
}

return commands
