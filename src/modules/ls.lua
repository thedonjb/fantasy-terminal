local utils = require "src.utils"
local lfs = love.filesystem

return {
    name = "ls",
    description = "List directory contents",
    usage = "ls [directory]",
    exec = function(args, state)
        local input = args[2] or "."
        local target

        if input:sub(1, 1) == "/" then
            utils.printt(state, "ls: absolute paths are not allowed in LÖVE filesystem")
            return
        else
            target = state.wd .. input
        end

        if not lfs.getInfo(target, "directory") then
            utils.printt(state, "ls: cannot access '" .. input .. "': No such file or directory")
            return
        end

        local items = lfs.getDirectoryItems(target)
        for _, item in ipairs(items) do
            utils.printt(state, item)
        end
    end
}
