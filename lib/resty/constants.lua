local bit = require "bit"
local lshift = bit.lshift
local setmetatable = setmetatable

local _M = {}

if setfenv then                 -- for lua5.1 and luajit
   setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
   _ENV = _M
else
   error("both setfenv and _ENV are nil...")
end

-- zookeeper state
ZOO_EXPIRED_SESSION_STATE = -112
ZOO_AUTH_FAILED_STATE = -113
ZOO_CONNECTING_STATE = 1
ZOO_ASSOCIATING_STATE = 2
ZOO_CONNECTED_STATE = 3
ZOO_READONLY_STATE = 5
ZOO_NOTCONNECTED_STATE = 999

-- packet type
ZOO_NOTIFY_OP       = 0
ZOO_CREATE_OP       = 1
ZOO_DELETE_OP       = 2
ZOO_EXISTS_OP       = 3
ZOO_GETDATA_OP      = 4
ZOO_SETDATA_OP      = 5
ZOO_GETACL_OP       = 6
ZOO_SETACL_OP       = 7
ZOO_GETCHILDREN_OP  = 8
ZOO_SYNC_OP         = 9
ZOO_PING_OP         = 11
ZOO_GETCHILDREN2_OP = 12
ZOO_CHECK_OP        = 13
ZOO_MULTI_OP        = 14
ZOO_CREATE2_OP      = 15
ZOO_RECONFIG_OP     = 16
ZOO_REMOVE_WATCHES  = 17
ZOO_CLOSE_OP        = -11
ZOO_SETAUTH_OP      = 100
ZOO_SETWATCHES_OP   = 101

-- watch event type
ZOO_CREATED_EVENT = 1
ZOO_DELETED_EVENT = 2
ZOO_CHANGED_EVENT = 3
ZOO_CHILD_EVENT = 4
ZOO_SESSION_EVENT = -1
ZOO_NOTWATCHING_EVENT = -2

-- predefined xid's values recognized as special by the server
WATCHER_EVENT_XID = -1
PING_XID = -2
AUTH_XID = -4
SET_WATCHES_XID = -8

-- ACL
ZOO_PERM_READ = lshift(1, 0)
ZOO_PERM_WRITE = lshift(1, 1)
ZOO_PERM_CREATE = lshift(1, 2)
ZOO_PERM_DELETE = lshift(1, 3)
ZOO_PERM_ADMIN = lshift(1, 4)
ZOO_PERM_ALL = bit.tobit(0x1f)

-- @name Interest Consts
-- These constants are used to express interest in an event and to
-- indicate to zookeeper which events have occurred. They can
-- be ORed together to express multiple interests. These flags are
-- used in the interest and event parameters of
-- \ref zookeeper_interest and \ref zookeeper_process.
ZOOKEEPER_WRITE = lshift(1, 0)
ZOOKEEPER_READ = lshift(1, 1)

-- @name Create Flags
-- These flags are used by zoo_create to affect node create. They may
-- be ORed together to combine effects.
ZOO_EPHEMERAL = lshift(1, 0)
ZOO_SEQUENCE = lshift(1, 1)

-- safety set, forbid to add attribute.
local module_mt = {
   __newindex = (
      function (table, key, val)
         error('Attempt to write to undeclared variable "' .. key .. '"')
                end),
}

setmetatable(_M, module_mt)

return _M
