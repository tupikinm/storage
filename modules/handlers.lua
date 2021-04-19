local space  = require('modules/space')
local json   = require('json')
local log    = require('log')
local config = require('../config')

HTTP_CODE = {
    OK                = 200,
    BAD_REQUEST       = 400,
    FORBIDDEN         = 403,
    NOT_FOUND         = 404,
    CONFLICT          = 409,
    TOO_MANY_REQUESTS = 429,
}

--[[
    Processing data by request method
]]
local handler_func = {
    POST = function(req, id, key, value)
        local result, id = space:set(key, value)
        if result then
            return "Success", id, HTTP_CODE.OK
        end
        return "Key already exists", id, HTTP_CODE.CONFLICT
    end,

    PUT = function(req, id, key, value)
        local result, item_id = space:update(id, key, value)
        if result then
            return "Success", item_id, HTTP_CODE.OK
        end
        return "Id not found", id, HTTP_CODE.NOT_FOUND
    end,

    GET = function(req, id, key)
        local result, tuple = space:get(id)
        if result then
            return json.encode(tuple), id, HTTP_CODE.OK
        end
        return "Id not found", id, HTTP_CODE.NOT_FOUND
    end,

    DELETE = function(req, id, key)
        local result = space:delete(id)
        if result then
            return "Success", id, HTTP_CODE.OK
        end
        return "Id not found", id, HTTP_CODE.NOT_FOUND
    end,
}

--[[
    Formating output data
]]
function serv_response(req, result, code, id)
    local status = code == HTTP_CODE.OK
    local json = {
        status  = status,
        version = "0.1",
        time    = os.time()
    }
    json[status and "data" or "error"] = result
    if id then
        json.id = id
    end
    local response = req:render({json = json})
          response.headers['x-api-status'] = status
          response.status = code
    return response
end

local time    = os.time()
local counter = 0

local handlers = {
    --[[
        Main handler for all requests

        Count requests per second
        Parse and validate data
    ]]
    main = function(req)
        local req_time = os.time()
        if req_time - time >= 1 then
            time    = req_time
            counter = 0
        else
            counter = counter + 1
            if counter > config.max_request_per_second then
                return serv_response(req, "Too many requests", HTTP_CODE.TOO_MANY_REQUESTS)
            end
        end

        local method = req:method()
        local func = handler_func[method]

        if not func then
            return serv_response(req, "Unknown method", HTTP_CODE.FORBIDDEN)
        end

        local check = space:check()
        if not check then
            return serv_response(req, "Space error", HTTP_CODE.FORBIDDEN)
        end

        local id = nil
        if method ~= "POST" then
            id = tonumber(req:path():split("/")[3])
            if not id then
                return serv_response(req, "Unknown or invalid id, expected integer", HTTP_CODE.BAD_REQUEST)
            end
        end

        local key, value, body = nil, nil, nil
        if method == "POST" or method == "PUT" then
            local ok, err = pcall(function () body = req:json() end)
            if not ok or not body or not body.value or (method == "POST" and not body.key) then
                return serv_response(req, [[Invalid body format, experted json with properties "key" and "value"]], HTTP_CODE.BAD_REQUEST)
            end

            if method == "POST" then
                key = body.key
            end

            value = body.value
            if type(value) ~= 'table' then
                return serv_response(req, "Invalid value format, expected object", HTTP_CODE.BAD_REQUEST)
            end
        end

        log.info('Request method: %s, path: %s, body: %s', method, req:path(), json.encode(body))
        local result, id, code = func(req, id, key, value)
        return serv_response(req, result, code, id)
    end,

    --[[
        Handler for other requests
    ]]
    lost = function(req)
        return serv_response(req, "Not found", HTTP_CODE.NOT_FOUND)
    end
}

return handlers