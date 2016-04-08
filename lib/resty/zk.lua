local bit = "require bit"
local setmetatable = setmetatable

local _M = {_VERSION="0.01"}

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
   _ENV = _M
else
   error("both setfenv and _ENV are nil...")
end

-- private function
local function _hello()
end

-- public function
function pp()
end

-- safety set, forbid to add attribute.
local module_mt = {
   __newindex = (
      function (table, key, val)
         error('Attempt to write to undeclared variable "' .. key .. '"')
                end),
}

setmetatable(_M, module_mt)

return _M
