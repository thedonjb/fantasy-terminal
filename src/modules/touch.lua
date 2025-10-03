local utils = require("src.utils")
local lfs = love.filesystem

return {
    name = "touch",
    description = "Create an empty file or update timestamp (not supported)",
    usage = "touch <filename>",
    exec = function(args, state)
        local filename = args[2]

        if not filename then
            utils.printt(state, "usage: touch <filename>")
            return
        end

        local fullpath = state.wd .. filename
        local info = lfs.getInfo(fullpath)

        if info and info.type ~= "file" then
            utils.printt(state, "touch: '" .. filename .. "' is not a file")
            return
        end

        local ok, err = lfs.write(fullpath, info and "" or "")
        if not ok then
            utils.printt(state, "touch: error creating file: " .. (err or "unknown"))
        end
    end
}
