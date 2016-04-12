local bit = require  "bit"
local consts = require "constants"
local proto = require "protocol"
local ngx = ngx

local setmetatable = setmetatable

local _M = {}

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
   _ENV = _M
else
   error("both setfenv and _ENV are nil...")
end

Conn = {
  new = function(self, host, port)
    local sock = ngx.socket.tcp()

    local ok, err = sock:connect(host, port)
    if not ok then
      return nil
    end
    local o = {
      sock = sock,
      host =  host,
      port = port,
    }
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,

  _write = function(self, msg, timeout)
    self.sock:send(msg)
  end,

  _read = function(self, length, timeout)
    local data, err, partial = self.sock:receive(length)
    return data, err
  end,

  _read_header = function(self, timeout)
    local b, err = self:_read(4, timeout)
    if err != nil then
      return nil, "", 0, err
    end
    local vars, err = struct.unpack_to_end(">i", b, 0)
    if err != nil then
      return nil, "", 0, err
    end
    local length = unpack(vars)
    b, err = self:_read(length, timeout)
    if err != nil then
      return nil, "", 0, err
    end
    local header = proto.ReplyHeader:new()
    local start_idx, err = header:load(b, 0)
    if err != nil then
      return nil, "", 0, err
    end
    return header, b, start_idx, nil
  end,
}

-- safety set, forbid to add attribute.
local module_mt = {
   __newindex = (
      function (table, key, val)
         error('Attempt to write to undeclared variable "' .. key .. '"')
                end),
}

setmetatable(_M, module_mt)

return _M
