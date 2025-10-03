-- src/modules/cd.lua
local utils = require "src.utils"
local lfs = love.filesystem

return {
    name = "cd",
    usage = "cd [dir]",
    description = "Change the current working directory.",
    exec = function(args, state)
        local pathArg = args[2]

        if not pathArg or pathArg == "~" then
            state.wd = state.fsroot .. "home/"
            return
        end

        local function normalize(path)
            local parts = {}
            for part in string.gmatch(path, "[^/]+") do
                if part == ".." then
                    if #parts > 0 then table.remove(parts) end
                elseif part ~= "." and part ~= "" then
                    table.insert(parts, part)
                end
            end
            return table.concat(parts, "/")
        end

        local newPath = normalize(state.wd .. "/" .. pathArg)

        if not newPath:match("^" .. state.fsroot) then
            utils.printt(state, "cd: access denied")
            return
        end

        local info = lfs.getInfo(newPath)
        if not info then
            utils.printt(state, "cd: no such file or directory: " .. pathArg)
        elseif info.type ~= "directory" then
            utils.printt(state, "cd: not a directory: " .. pathArg)
        else
            state.wd = newPath:match(".*/$") and newPath or (newPath .. "/")
        end
    end
}
