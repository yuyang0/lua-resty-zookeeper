local bit = "require bit"
local struct = "require struct"

local setmetatable = setmetatable

local _M = {_VERSION="0.01"}

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
   _ENV = _M
else
   error("both setfenv and _ENV are nil...")
end

-- packet type
local ZOO_NOTIFY_OP       = 0
local ZOO_CREATE_OP       = 1
local ZOO_DELETE_OP       = 2
local ZOO_EXISTS_OP       = 3
local ZOO_GETDATA_OP      = 4
local ZOO_SETDATA_OP      = 5
local ZOO_GETACL_OP       = 6
local ZOO_SETACL_OP       = 7
local ZOO_GETCHILDREN_OP  = 8
local ZOO_SYNC_OP         = 9
local ZOO_PING_OP         = 11
local ZOO_GETCHILDREN2_OP = 12
local ZOO_CHECK_OP        = 13
local ZOO_MULTI_OP        = 14
local ZOO_CREATE2_OP      = 15
local ZOO_RECONFIG_OP     = 16
local ZOO_REMOVE_WATCHES  = 17
local ZOO_CLOSE_OP        = -11
local ZOO_SETAUTH_OP      = 100
local ZOO_SETWATCHES_OP   = 101

-- private function
local function _hello()
end

-- public function
function dump_close_packet()
  local ty = -11
  -- big endian
  return struct.pack(">i", ty)
end

function dump_ping_packet()
  local ty = 11
  return struct.pack(">i", ty)
end

function load_connect_packet(proto_ver, last_zxid_seen, timeout,
                             session_id, passwd, read_only)
  return struct.pack(">ilil", proto_ver, last_zxid_seen, timeout, session_id)
end

function dump_connect_packet()
end

function load_create_packet()
end

function dump_create_packet()
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
