local lfs = love.filesystem
local utils = require("src.utils")
local state = require("src.state")

-- Check if path is inside critical system dirs
local function is_critical_path(path, fsroot)
    path = path:gsub("/+", "/")
    local critical = {
        fsroot,
        fsroot .. "home",
        fsroot .. "tmp",
        fsroot .. "appnet",
    }

    for _, base in ipairs(critical) do
        if path == base or path:match("^" .. base .. "/") then
            return true
        end
    end

    return false
end

-- Recursive removal logic
local function rm_path(path, opts, state)
    local info = lfs.getInfo(path)
    if not info then
        if not opts.force then
            utils.printt(state, "rm: cannot remove '" .. path .. "': No such file or directory")
        end
        return
    end

    if is_critical_path(path, state.fsroot) and not opts.force_critical then
        utils.printt(state, "rm: refusing to remove protected path: " .. path)
        utils.printt(state, "use --force-critical and type 'Y' to confirm")

        state.awaiting_confirmation = function(input)
            if input == "Y" then
                opts.force_critical = true
                rm_path(path, opts, state)
            else
                utils.printt(state, "Aborted.")
            end
            state.awaiting_confirmation = nil
        end

        return
    end

    if info.type == "file" then
        local ok = lfs.remove(path)
        if not ok and not opts.force then
            utils.printt(state, "rm: failed to remove file '" .. path .. "'")
        end
    elseif info.type == "directory" then
        if not opts.recursive then
            utils.printt(state, "rm: cannot remove '" .. path .. "': Is a directory")
            return
        end

        local files = lfs.getDirectoryItems(path)
        for _, f in ipairs(files) do
            rm_path(path .. "/" .. f, opts, state)
        end

        local ok = lfs.remove(path)
        if not ok and not opts.force then
            utils.printt(state, "rm: failed to remove directory '" .. path .. "'")
        end
    end
end

return {
    name = "rm",
    description = "Remove files or directories",
    usage = "rm [-rf] [--force-critical] <target1> [target2...]",
    exec = function(args, state)
        if not args[2] then
            utils.printt(state, "usage: rm [-rf] [--force-critical] <target>")
            return
        end

        local opts = {}
        local paths = {}

        for i = 2, #args do
            local arg = args[i]
            if arg:sub(1, 1) == "-" then
                if arg == "--force-critical" then
                    opts.force_critical = true
                else
                    for j = 2, #arg do
                        local flag = arg:sub(j, j)
                        if flag == "r" then opts.recursive = true
                        elseif flag == "f" then opts.force = true
                        else
                            utils.printt(state, "rm: invalid option -- '" .. flag .. "'")
                            return
                        end
                    end
                end
            else
                table.insert(paths, arg)
            end
        end

        if #paths == 0 then
            utils.printt(state, "rm: missing operand")
            return
        end

        for _, p in ipairs(paths) do
            local fullpath = state.wd .. p
            rm_path(fullpath, opts, state)
        end
    end
}
