local handlers = require('modules/handlers')
local config   = require('config')

function create_server()
    local server = require("http.server").new(nil, config.port, {
        display_errors = true,
        --log_requests   = true,
        --log_errors     = true
    })

    local router = require('http.router').new({charset = "utf8"})
          router:use(handlers.main, {path = "/kv",     method = "POST", name = "create"})
          router:use(handlers.main, {path = "/kv/:id", method = "ANY",  name = "process",   after = "create"})
          router:use(handlers.lost, {                  method = "ANY",  name = "not found", after = "process"})
          router:use(handlers.lost, {path = "/*",      method = "ANY",  name = "root",      after = "not found"})

    server:set_router(router)
    server:start()
end

create_server()

return true