local editor = require "src.app.editor"
local utils = require "src.utils"

return {
    name = "edit",
    description = "Open a file in the built‑in editor.",
    usage = "edit <filename>",
    exec = function(args, state)
        local filename = args[2]
        if not filename then
            utils.printt(state, "usage: edit <filename>")
            return
        end

        state.interm = false
        editor.open(state.wd .. filename)
    end
}
