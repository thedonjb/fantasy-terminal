local utils   = require("src.utils")
local state   = require("src.state")
local history = require("src.history")

local MIN_KB = 16
local MAX_KB = 10240

return {
    name = "sethist",
    description = "Set or show history size limit in KB",
    usage = "sethist [kilobytes]",
    exec = function(args, state)
        if not args[2] then
            utils.printt(state, "Current history limit: " .. (state.history_limit_kb or 256) .. " KB")
            utils.printt(state, "Allowed range: " .. MIN_KB .. "–" .. MAX_KB .. " KB")
            return
        end

        local kb = tonumber(args[2])
        if not kb then
            utils.printt(state, "Usage: sethist <kilobytes>")
            return
        end

        if kb < MIN_KB then kb = MIN_KB end
        if kb > MAX_KB then kb = MAX_KB end

        state.history_limit_kb = kb
        history.save()
        utils.printt(state, "History limit set to " .. kb .. " KB (clamped between " .. MIN_KB .. " and " .. MAX_KB .. ")")
    end
}
