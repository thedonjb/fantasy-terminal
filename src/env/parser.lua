-- 📁 src/env/parser.lua
-- Static completion database for Fantasy Terminal API

local parser = {}

local db = {
    globals = {}, -- top-level symbols
    members = {}  -- nested tree
}

db.members["fterm"] = {
    { name = "print", kind = "function", type = "fun(msg:string)", desc = "Print to terminal" },
    { name = "state", kind = "table", type = "State", desc = "Global session state", children = {
        { name = "wd", kind = "field", type = "string", desc = "Working directory" },
        { name = "vars", kind = "field", type = "table", desc = "Environment variables" }
    }},
    { name = "fs", kind = "module", desc = "Filesystem API", children = {
        { name = "read", kind = "function", type = "fun(path:string):string" },
        { name = "write", kind = "function", type = "fun(path:string, data:string)" }
    }}
}

function parser.build()
    -- no-op now, static DB
end

function parser.getCompletions(prefix)
    -- no prefix? return globals
    if prefix == "" then
        local results = {}
        for k, v in pairs(db.members) do
            table.insert(results, { name = k, kind = "table", children = v })
        end
        return results
    end

    local parts = {}
    for part in prefix:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    -- start at root
    local current = db.members[parts[1]]
    if not current then return {} end

    -- walk down each part
    for i = 2, #parts do
        local nextNode = nil
        for _, entry in ipairs(current) do
            if entry.name == parts[i] then
                nextNode = entry.children
                break
            end
        end
        current = nextNode
        if not current then break end
    end

    -- return completions at current level
    local results = {}
    for _, entry in ipairs(current or {}) do
        table.insert(results, entry)
    end
    return results
end

parser.db = db
return parser
