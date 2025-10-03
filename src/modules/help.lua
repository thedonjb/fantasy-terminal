local utils = require("src.utils")

return {
    name = "help",
    description = "Show help for built-in and installed commands",
    usage = "help [command]",
    exec = function(args, state, commands)
        local target = args[2]

        local function print_cmd_help(cmd)
            if not cmd.name then return end
            utils.printt(state, ("[%s] - %s"):format(cmd.name, cmd.description or ""))
            if cmd.usage then
                utils.printt(state, "Usage: " .. cmd.usage)
            end
        end

        if target then
            local cmd = commands[target]
            if type(cmd) == "table" and cmd.name then
                print_cmd_help(cmd)
                return
            end

            utils.printt(state, "No such command or package: " .. target)
            return
        end

        utils.printt(state, "Available commands:")
        for name, cmd in pairs(commands) do
            if type(cmd) == "table" and cmd.name then
                utils.printt(state, (" - %-16s %s"):format(name, cmd.description or ""))
            end
        end

        utils.printt(state, "\nType 'help <command>' for more info.")
    end
}
