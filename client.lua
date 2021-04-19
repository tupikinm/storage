local http_client = require('http.client'):new()
local json        = require('json')
local config      = require('config')
local headers     = {}
local separator   = [[------------------------]]

--[[
    Print request result status & body to console
]]
local function print_result(r, method)
    print(separator)
    print(method)
    for k, v in pairs(r) do
        if k == 'status' or k == 'body' then
            print(k, v)
        end
    end
end

local address = 'http://'..config.host..':'..config.port..'/kv/'

-- Initial data to insert
local kv = {
    key   = "name",
    value = {
        login = "tupikinm"
    }
}

--[[
    Get item from space by key
]]
local function get_item(id)
    local r = http_client:get(address..id, {})
    print_result(r, 'GET')
end

--[[
    Insert item to space
]]
local r = http_client:post(address, json.encode(kv))
print_result(r, 'POST')

local body
pcall(function() body = json.decode(r.body) end)
if not body then
    print('Parse body error')
    return
end

local id   = body.id
get_item(id)

--[[
    Check if key exists
]]
local r = http_client:post(address, json.encode(kv))
print_result(r, 'POST')

--[[
    Modify initial data
]]
kv.value = {
    login = "mikhailt"
}

--[[
    Put new data to space
]]
r = http_client:put(address..id, json.encode(kv))
print_result(r, 'PUT')

get_item(id)

--[[
    Delete item from space by key
]]
r = http_client:delete(address..id, {})
print_result(r, 'DELETE')

get_item(id)

--[[
    Try to modify item in space by unknown key
]]
r = http_client:put(address..math.random(1000, 9999), json.encode(kv))
print_result(r, 'PUT')

--[[
    Try to delete item from space by unknown key
]]
r = http_client:delete(address..math.random(1000, 9999), {})
print_result(r, 'DELETE')