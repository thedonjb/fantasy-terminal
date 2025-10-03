local utils = require("src.utils")
local lfs = love.filesystem

return {
    name = "mkdir",
    description = "Create a new directory",
    usage = "mkdir <directory>",
    exec = function(args, state)
        local dir = args[2]

        if not dir then
            utils.printt(state, "usage: mkdir <directory>")
            return
        end

        local path = state.wd .. dir
        if lfs.getInfo(path) then
            utils.printt(state, "mkdir: cannot create directory '" .. dir .. "': File exists")
            return
        end

        local success = lfs.createDirectory(path)
        if not success then
            utils.printt(state, "mkdir: failed to create directory '" .. dir .. "'")
        end
    end
}
