local http = require("socket.http")
local utils = require("src.utils")

return {
    name = "curl",
    description = "Fetch and display the contents of a URL.",
    usage = "curl <url>",
    exec = function(args, state)
        local url = args[2]
        if not url then
            utils.printt(state, "usage: curl <url>")
            return
        end

        utils.printt(state, "Fetching " .. url .. "...")

        local response, status = http.request(url)
        if status ~= 200 or not response then
            utils.printt(state, "curl: failed to fetch (" .. tostring(status) .. ")")
            return
        end

        for line in response:gmatch("[^\r\n]+") do
            utils.printt(state, line)
        end
    end
}
