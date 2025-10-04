local utils = require("src.utils")
local fs    = love.filesystem
local state = require("src.state")

local apm   = {
    name = "apm",
    description = "App Package Manager",
    usage = "apm [install|remove|list|rescan|info] [args]"
}

------------------------------------------------------------
-- Package Validation
------------------------------------------------------------
local function validate_package(path)
    local f = io.open(path, "r")
    if not f then return false, "File unreadable" end
    local code = f:read("*a")
    f:close()

    local chunk, err = loadstring(code)
    if not chunk then return false, "Bad Lua syntax: " .. err end

    local env = {}
    setfenv(chunk, env)
    local ok, runtimeErr = pcall(chunk)
    if not ok then return false, "Runtime error: " .. runtimeErr end

    if type(env.manifest) ~= "table" then
        return false, "Missing manifest table"
    end
    if type(env.exec) ~= "function" then
        return false, "Missing exec() function"
    end
    if not env.manifest.name or not env.manifest.version then
        return false, "Manifest missing required fields"
    end

    return true, env.manifest, code
end

------------------------------------------------------------
-- Install Package
------------------------------------------------------------
local function validate_package(path)
    if not path then return false, "No path given" end
    local f, err = io.open(path, "r")
    if not f then return false, "File unreadable: " .. tostring(err) end
    local code = f:read("*a") or ""
    f:close()

    if code == "" then
        return false, "Empty file"
    end

    local chunk, loadErr = loadstring(code)
    if not chunk then return false, "Bad Lua syntax: " .. loadErr end

    local env = {}
    setfenv(chunk, env)
    local ok, runtimeErr = pcall(chunk)
    if not ok then return false, "Runtime error: " .. runtimeErr end

    if type(env.manifest) ~= "table" then
        return false, "Missing manifest table"
    end
    if type(env.exec) ~= "function" then
        return false, "Missing exec() function"
    end
    if not env.manifest.name or not env.manifest.version then
        return false, "Manifest missing required fields"
    end

    return true, env.manifest, code
end

local function install_package(file)
    if not file then
        utils.printt(state, "No file selected or provided.")
        return
    end
    if not file:match("%.fpkg%.lua$") then
        utils.printt(state, "Invalid format. Only *.fpkg.lua allowed.")
        return
    end

    local valid, meta, code = validate_package(file)
    if not valid or not code then
        utils.printt(state, "Install failed: " .. tostring(meta))
        return
    end

    local dest = state.fsroot .. "appnet/" .. meta.name .. ".fpkg.lua"
    fs.write(dest, code) -- now guaranteed `code` is a string
    utils.printt(state, "Installed package: " .. meta.name .. " v" .. meta.version)
end

------------------------------------------------------------
-- Command Dispatcher
------------------------------------------------------------
function apm.exec(args, state)
    local action = args[2]

    if action == "list" then
        local pkgs = fs.getDirectoryItems(state.fsroot .. "appnet")
        utils.printt(state, "Installed packages:")
        for _, file in ipairs(pkgs) do
            if file:match("%.fpkg%.lua$") then
                utils.printt(state, "- " .. file)
            end
        end
    elseif action == "install" then
        local pkg = args[3]
        if not pkg then
            --- @diagnostic disable-next-line: undefined-field
            if type(love.window.showFileDialog) == 'function' then
                love.window.showFileDialog(
                    "openFile",
                    false, -- allowMultipleSelections
                    function(paths)
                        if not paths or #paths == 0 then
                            utils.printt(state, "No file selected.")
                            return
                        end
                        install_package(paths[1])
                    end,
                    { { "Lua Package", "*.fpkg.lua" } },
                    love.filesystem.getSaveDirectory()
                )
            else
                -- Fallback for LÖVE 11.x
                local targetDir = love.filesystem.getSaveDirectory() .. "/" .. state.fsroot .. "appnet"
                love.system.openURL("file://" .. targetDir)
                utils.printt(state,
                    "File picker not available in LÖVE 11.x.\n" ..
                    "Opened appnet folder in your file manager.\n" ..
                    "Drop your .fpkg.lua files there, then run 'apm rescan'.")
            end
        else
            install_package(pkg)
        end
    elseif action == "remove" then
        local pkgname = args[3]
        if not pkgname then
            utils.printt(state, "Usage: apm remove <name>")
            return
        end
        local path = state.fsroot .. "appnet/" .. pkgname .. ".fpkg.lua"
        if fs.getInfo(path) then
            fs.remove(path)
            utils.printt(state, "Removed: " .. pkgname)
        else
            utils.printt(state, "Package not found: " .. pkgname)
        end
    elseif action == "rescan" then
        utils.printt(state, "Rescanning packages...")
        local pkgs = fs.getDirectoryItems(state.fsroot .. "appnet")
        for _, file in ipairs(pkgs) do
            if file:match("%.fpkg%.lua$") then
                local path = state.fsroot .. "appnet/" .. file
                local fullpath = love.filesystem.getSaveDirectory() .. "/" .. path
                local valid, meta = validate_package(fullpath)
                if valid then
                    utils.register_command(state.commands, meta.name, path)
                    utils.printt(state, "Loaded: " .. meta.name .. " v" .. meta.version)
                else
                    utils.printt(state, "Skipped " .. file .. ": " .. meta)
                end
            end
        end
    elseif action == "info" then
        local pkgname = args[3]
        if not pkgname then
            utils.printt(state, "Usage: apm info <name>")
            return
        end
        local path = state.fsroot .. "appnet/" .. pkgname .. ".fpkg.lua"
        local valid, meta = validate_package(love.filesystem.getSaveDirectory() .. "/" .. path)
        if valid then
            utils.printt(state, "Name: " .. meta.name)
            utils.printt(state, "Version: " .. meta.version)
            utils.printt(state, "Description: " .. (meta.description or ""))
        else
            utils.printt(state, "Invalid package: " .. meta)
        end
    else
        utils.printt(state, apm.usage)
    end
end

return apm
