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
-- local function _hello()
-- end


Id = {
  scheme = ""
  id = ""
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack('>SS', self.scheme, self.id)
  end

  dump_raw = function(self, stream)
    return struct.pack_raw('>SS', stream, self.scheme, self.id)
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>SS', stream, start_idx)
    if err == nil then
      self.scheme, self.id = unpack(vars)
    end
    return start_idx, err
  end
}

ACL = {
  perms = ""
  id = nil     -- Id object
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    local stream = {}
    self:dump_raw(stream)
    return table.concat(stream)
  end

  dump_raw = function(self, stream)
    struct.pack_raw('>S', stream, self.perms)
    self.id:dump_raw(stream)
    return stream
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>SS', stream, start_idx)
    if err == nil then
      self.scheme, self.id = unpack(vars)
    end
    return start_idx, err
  end
}

Stat = {
  czxid = 0          --long:  created zxid
  mzxid = 0          --long:  last modified zxid
  ctime = 0          --long: created
  mtime = 0          --long: last modified
  version = 0        --int:  version
  cversion = 0       --int:  child version
  aversion = 0       --int:  acl version
  ephemeralOwner = 0 --long: owner id if ephemeral, 0 otw
  dataLength = 0     --int: length of the data in the node
  numChildren = 0    --int: number of children of this node
  pzxid = 0          --long: last modified children

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack('>lllliiiliil', self.czxid, self.mzxid, self.ctime,
                       self.mtime, self.version, self.cversion, self.aversion,
                       self.ephemeralOwner, self.dataLength, self.numChildren,
                       self.pzxid)
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>lllliiiliil', stream, start_idx)
    if err == nil then
      self.czxid, self.mzxid, self.ctime, self.mtime, self.version, self.cversion, self.aversion, self.ephemeralOwner, self.dataLength, self.numChildren, self.pzxid = unpack(vars)
    end
    return start_idx, err
  end
}

ConnectReq = {
  proto_ver = 0        -- int
  last_zxid_seen = 0   -- long
  timeout = 0          -- int
  session_id = 0       -- long
  passwd = ""          -- string
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">ililS", self.proto_ver, self.last_zxid_seen,
                       self.timeout, self.session_id, self.passwd)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>ililS', stream, start_idx)
    if err == nil then
      self.proto_ver, self.last_zxid_seen, self.timeout, self.session_id, self.passwd = unpack(vars)
    end
  end
}

ReqHeader = {
  xid = 0    -- int
  ty = 0     -- int
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack('>ii', self.xid, self.ty)
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>ii', stream, start_idx)
    if err == nil then
      self.xid, self.ty = unpack(vars)
    end
    return start_idx, err
  end
}

MultiHeader = {
  ty = 0     -- int
  done = true    -- boolean
  err = 0     -- int
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack('>i?i', self.ty, self.done, self.err)
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>i?i', stream, start_idx)
    if err == nil then
      self.ty, self.done, self.err = unpack(vars)
    end
    return start_idx, err
  end
}

AuthPacket = {
  ty = 0      -- int
  scheme = ""
  auth = ""

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">iSS", self.ty, self.scheme, self.auth)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSi', stream, start_idx)
    if err == nil then
      self.ty, self.scheme, self.auth = unpack(vars)
    end
    return start_idx, err
  end
}

ReplyHeader = {
  xid = 0     -- int
  zxid = 0    -- long
  err = 0     -- int
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack('>ili', self.xid, self.zxid, self.err)
  end

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>ili', stream, start_idx)
    if err == nil then
      self.xid, self.zxid, self.err = unpack(vars)
    end
    return start_idx, err
  end
}

GetDataReq = {
  path = ""
  watch = false  -- boolean

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">S?", self.path, self.version)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S?', stream, start_idx)
    if err == nil then
      self.path, self.version = unpack(vars)
    end
    return start_idx, err
  end
}

SetDataReq = {
  path = ""
  data = ""
  version = 0  -- int

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">SSi", self.path, self.data, self.version)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSi', stream, start_idx)
    if err == nil then
      self.path, self.data, self.version = unpack(vars)
    end
    return start_idx, err
  end
}

ReconfigReq = {
  joining = ""
  leaving = ""
  new_members = ""
  config_id = 0  -- long

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">SSSl", self.joining, self.leaving, self.new_members, self.config_id)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSSl', stream, start_idx)
    if err == nil then
      self.joining, self.leaving, self.new_members, self.config_id = unpack(vars)
    end
    return start_idx, err
  end
}

CreateReq = {
  path = ""
  data = ""
  acl = nil
  flags = 0    -- int

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">ililS", self.proto_ver, self.last_zxid_seen,
                       self.timeout, self.session_id, self.passwd)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>ililS', stream, start_idx)
    if err == nil then
      self.proto_ver, self.last_zxid_seen, self.timeout, self.session_id, self.passwd = unpack(vars)
    end
    return start_idx, err
  end
}

DeleteReq = {
  path = ""
  version = 1   -- int

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">Si", self.path, self.version)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>Si', stream, start_idx)
    if err == nil then
      self.path, self.version = unpack(vars)
    end
    return start_idx, err
  end
}

ExistsReq = GetDataReq
GetChildrenReq = GetDataReq
GetChildren2Req = GetChildrenReq

CheckVersionReq = {
  path = ""
  version = 0 -- int

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">Si", self.path, self.version)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>Si', stream, start_idx)
    if err == nil then
      self.path, self.version = unpack(vars)
    end
    return start_idx, err
  end
}

SyncReq = {
  path = ""

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">S", self.path)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.path = unpack(vars)
    end
    return start_idx, err
  end
}

GetACL = {
  path = ""

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">S", self.path)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.path = unpack(vars)
    end
    return start_idx, err
  end
}

-- TODO
SetACL = {
  path = ""
  acls = {}
  version = 0

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">S", self.path)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.path = unpack(vars)
    end
    return start_idx, err
  end
}

WatchEvent = {
  ty = 0   --int
  state = 0 --int
  path = ""

  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end

  dump = function(self)
    return struct.pack(">iiS", self.ty, self.state, self.path)
  end

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.ty, self.state, self.path = unpack(vars)
    end
    return start_idx, err
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
