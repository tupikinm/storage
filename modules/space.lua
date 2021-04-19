--[[
    Space module
    Implements space methods
]]

local json = require('json')

local space = {
    _space = nil,
    _seq   = nil,

    --[[
        Create space, set space format, create index by key
    ]]
    init = function(self)
        box.cfg {
           listen = 3301,
           log    = 'logs/box.log'
        }

        if box.schema.key_value then
            box.schema.key_value:drop()
        end

        local space = box.schema.space.create('key_value', {
            engine        = "memtx",
            field_count   = 3,
            if_not_exists = true
        })
        space:format({
            {name = 'id',    type = 'integer'},
            {name = 'key',   type = 'str', is_nullable = false},
            {name = 'value', type = 'map'}
        })
        space:create_index('primary', {
            parts         = {'id'},
            sequence      = true,
            if_not_exists = true
        })
        space:create_index('secondary', {
            type          = 'TREE',
            parts         = {'key'},
            if_not_exists = true
        })

        self._space = space
        self._seq   = box.sequence.key_value_seq
    end,

    --[[
        Check if id already exists
    ]]
    _exist_id = function(self, id)
        local tuple = self._space.index.primary:select{id}
        return next(tuple), tuple
    end,

    --[[
        Check if key already exists
    ]]
    _exist_key = function(self, key)
        local tuple = self._space.index.secondary:select{key}
        return next(tuple), tuple
    end,

    --[[
        Create tuple in space
    ]]
    set = function(self, key, value)
        local exist, tuple = self:_exist_key(key)
        if exist then
            return false, tuple[1][1]
        end

        self._space:insert{box.null, key, value}
        local id  = self._seq:current()
        return true, id
    end,

    --[[
        Get tuple from space by key
    ]]
    get = function(self, id)
        local exist, tuple = self:_exist_id(id)
        if not exist then
            return false
        end

        return true, {key = tuple[1][2], value = tuple[1][3]}
    end,

    --[[
        Update tuple in space by key
    ]]
    update = function(self, id, key, value)
        local exist_id, tuple = self:_exist_id(id)
        if not exist_id then
            return false
        end

        local key = tuple[1][2]
        self._space:put{id, key, value}
        return true, id
    end,

    --[[
        Delete tuple from space by key
    ]]
    delete = function(self, id, key)
        local exist = self:_exist_id(id)
        if not exist then
            return false
        end

        self._space.index.primary:delete{id}
        return true, id
    end,

    --[[
        Check if space was created successfully
    ]]
    check = function(self)
        local space = self._space
        if not space then
            return false
        end
        return true
    end
}

space:init()
return space