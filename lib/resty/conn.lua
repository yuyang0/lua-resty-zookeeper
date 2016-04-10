local bit = require  "bit"
local consts = require "constants"
local proto = require "protocol"

local setmetatable = setmetatable

local _M = {_VERSION="0.01"}

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
   _ENV = _M
else
   error("both setfenv and _ENV are nil...")
end

Conn = {
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  _read_header = function(self)
  end
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
