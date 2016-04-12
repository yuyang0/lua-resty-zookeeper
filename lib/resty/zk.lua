local bit = require  "bit"
local error = error
local consts = require "constants"
local proto = require "protocol"
local utils = require "utils"
local conn = require "conn"

local setmetatable = setmetatable

local _M = {_VERSION="0.01"}

if setfenv then                 -- for lua5.1 and luajit
  setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
  _ENV = _M
else
  error("both setfenv and _ENV are nil...")
end

-- data should be shared with requets.
local share_data = {}

Client = {
  new = function(self, hosts_ss, force_create)
    if (not force_create) and share_data.client then
      return share_data.client
    end

    local hosts, chroot = utils.collect_hosts(hosts_ss)
    local o = {
      hosts_ss = hosts_ss,
      hosts = hosts,
      state_listener = {},
    }
    local _connection = conn.Conn:new(o)
    o._connection = _connection

    setmetatable(o, self)
    self.__index = self

    if not share_data.client then
      share_data.client = o
    end
    return o
  end,

  start = function(self, timeout)
    timeout = timeout or 15
  end,

  stop = function(self)
  end,

  sync = function(self, path)
  end,

  create = function(self, path, value, acl, ephemeral, sequence, makepath)
    value = value or ""
  end,

  exists = function(self, path, watch)
  end,

  get = function(self, path, watch)
  end,

  get_children = function(self, path, watch, include_data)
  end,

  get_acls = function(self, path)
  end,

  set_acls = function(self, path, acls, version)
    version =version or -1
  end,

  set = function(self, path, value, version)
    version = version or -1

  end,

  delete = function(self, path, version, recursive)
    version = version or -1
  end,

  reconfig = function(self, joining, leaving, max_members, from_config)
    from_config = from_config or -1
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
