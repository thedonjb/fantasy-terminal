local utils = require("src.utils")

return {
    name = "cat",
    description = "Print the contents of a file",
    usage = "cat <filename>",
    exec = function(args, state)
        if not args[2] then
            utils.printt(state, "usage: cat <filename>")
            return
        end

        local path = state.wd .. args[2]
        local info = love.filesystem.getInfo(path)

        if not info or info.type ~= "file" then
            utils.printt(state, "cat: file not found")
            return
        end

        local contents, err = love.filesystem.read(path)
        if not contents then
            utils.printt(state, "cat: error reading file: " .. (err or "unknown"))
            return
        end

        for line in contents:gmatch("[^\r\n]+") do
            utils.printt(state, line)
        end
    end
}
