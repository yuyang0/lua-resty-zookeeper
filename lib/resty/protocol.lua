local bit = require "bit"
local struct = require "struct"
local consts = require "constants"

local setmetatable = setmetatable

local _M = {}

if setfenv then                 -- for lua5.1 and luajit
  setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
  _ENV = _M
else
  error("both setfenv and _ENV are nil...")
end

local _Base = {
  new = function(self, o)
    o = o or {}
    -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,

  dump = function(self)
    local stream = {}
    self:dump_raw(stream)
    return table.concat(stream)
  end,

  -- just a place holder
  dump_raw = function(self, stream)
    return stream
  end,

  -- just a place holder
  load = function(self, stream, start_idx)
    return start_idx, nil
  end,
}

local _PathWatchPacket = _Base:new {
  path = "",
  watch = false,  -- boolean

  dump_raw = function(self, stream)
    return struct.pack_raw('>S?', stream, self.path, self.watch)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S?', stream, start_idx)
    if err == nil then
      self.path, self.watch = unpack(vars)
    end
    return start_idx, err
  end,
}

local _PathVersionPacket = _Base:new {
  path = "",
  version = 0,  -- int

  dump_raw = function(self, stream)
    return struct.pack_raw('>Si', stream, self.path, self.version)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>Si', stream, start_idx)
    if err == nil then
      self.path, self.version = unpack(vars)
    end
    return start_idx, err
  end,
}

local _PathPacket = _Base:new {
  path = "",

  dump_raw = function(self, stream)
    return struct.pack_raw('>S', stream, self.path)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.path = unpack(vars)
    end
    return start_idx, err
  end,
}


Id = _Base:new {
  scheme = "",
  id = "",

  dump_raw = function(self, stream)
    return struct.pack_raw('>SS', stream, self.scheme, self.id)
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>SS', stream, start_idx)
    if err == nil then
      self.scheme, self.id = unpack(vars)
    end
    return start_idx, err
  end,
}

ACL = _Base:new {
  perms = "",
  id = nil,     -- Id object

  dump_raw = function(self, stream)
    struct.pack_raw('>S', stream, self.perms)
    self.id:dump_raw(stream)
    return stream
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>SS', stream, start_idx)
    if err == nil then
      self.scheme, self.id = unpack(vars)
    end
    return start_idx, err
  end,
}

Stat = _Base:new{
  czxid = 0,          --long:  created zxid
  mzxid = 0,          --long:  last modified zxid
  ctime = 0,          --long: created
  mtime = 0,          --long: last modified
  version = 0,        --int:  version
  cversion = 0,       --int:  child version
  aversion = 0,       --int:  acl version
  ephemeralOwner = 0, --long: owner id if ephemeral, 0 otw
  dataLength = 0,     --int: length of the data in the node
  numChildren = 0,    --int: number of children of this node
  pzxid = 0,          --long: last modified children

  dump_raw = function(self, stream)
    return struct.pack_raw('>lllliiiliil', stream, self.czxid, self.mzxid,
                           self.ctime, self.mtime, self.version, self.cversion,
                           self.aversion, self.ephemeralOwner, self.dataLength,
                           self.numChildren, self.pzxid)
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>lllliiiliil', stream, start_idx)
    if err == nil then
      self.czxid, self.mzxid, self.ctime, self.mtime, self.version, self.cversion, self.aversion, self.ephemeralOwner, self.dataLength, self.numChildren, self.pzxid = unpack(vars)
    end
    return start_idx, err
  end,
}

PingReq = _Base:new{type = consts.ZOO_PING_OP}
CloseReq = _Base:new{type = consts.ZOO_CLOSE_OP}

ConnectReq = _Base:new {
  proto_ver = 0,        -- int
  last_zxid_seen = 0,   -- long
  timeout = 0,          -- int
  session_id = 0,       -- long
  passwd = "",          -- buffer

  dump_raw = function(self, stream)
    return struct.pack_raw(">ililS", stream, self.proto_ver, self.last_zxid_seen,
                       self.timeout, self.session_id, self.passwd)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>ililS', stream, start_idx)
    if err == nil then
      self.proto_ver, self.last_zxid_seen, self.timeout, self.session_id, self.passwd = unpack(vars)
    end
  end,
}

ConnectResp = _Base:new {
  proto_ver = 0,        -- int
  timeout = 0,          -- int
  session_id = 0,       -- long
  passwd = "",          -- buffer

  dump_raw = function(self, stream)
    return struct.pack_raw(">iilS", stream, self.proto_ver,
                           self.timeout, self.session_id, self.passwd)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>iilS', stream, start_idx)
    if err == nil then
      self.proto_ver, self.timeout, self.session_id, self.passwd = unpack(vars)
    end
  end,
}

ReqHeader = _Base:new {
  xid = 0,    -- int
  type = 0,     -- int

  dump_raw = function(self, stream)
    return struct.pack_raw('>ii', stream, self.xid, self.type)
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>ii', stream, start_idx)
    if err == nil then
      self.xid, self.type = unpack(vars)
    end
    return start_idx, err
  end,
}

MultiHeader = _Base:new {
  type = 0,     -- int
  done = true,    -- boolean
  err = 0,     -- int

  dump_raw = function(self, stream)
    return struct.pack_raw('>i?i', stream, self.type, self.done, self.err)
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>i?i', stream, start_idx)
    if err == nil then
      self.type, self.done, self.err = unpack(vars)
    end
    return start_idx, err
  end,
}

AuthPacket = _Base:new {
  type = consts.ZOO_SETAUTH_OP,    -- int
  scheme = "",
  auth = "",   -- buffer

  dump_raw = function(self, stream)
    return struct.pack_raw(">iSS", stream, self.type, self.scheme, self.auth)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSi', stream, start_idx)
    if err == nil then
      self.type, self.scheme, self.auth = unpack(vars)
    end
    return start_idx, err
  end,
}

ReplyHeader = _Base:new {
  xid = 0,     -- int
  zxid = 0,    -- long
  err = 0,     -- int

  dump_raw = function(self, stream)
    return struct.pack_raw('>ili', stream, self.xid, self.zxid, self.err)
  end,

  load = function(self, stream, start_idx)
    local vars, start_idx, err = struct.unpack('>ili', stream, start_idx)
    if err == nil then
      self.xid, self.zxid, self.err = unpack(vars)
    end
    return start_idx, err
  end,
}

GetDataReq = _PathWatchPacket:new{type = consts.ZOO_GETDATA_OP}

SetDataReq = _Base:new {
  type = consts.ZOO_SETDATA_OP,
  path = "",
  data = "",    -- buffer
  version = 0,  -- int

  dump_raw = function(self, stream)
    return struct.pack_raw(">SSi", stream, self.path, self.data, self.version)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSi', stream, start_idx)
    if err == nil then
      self.path, self.data, self.version = unpack(vars)
    end
    return start_idx, err
  end,
}

ReconfigReq = _Base:new {
  type = consts.ZOO_RECONFIG_OP,
  joining = "",
  leaving = "",
  new_members = "",
  config_id = 0,  -- long

  dump_raw = function(self, stream)
    return struct.pack_raw(">SSSl", stream, self.joining, self.leaving,
                           self.new_members, self.config_id)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSSl', stream, start_idx)
    if err == nil then
      self.joining, self.leaving, self.new_members, self.config_id = unpack(vars)
    end
    return start_idx, err
  end,
}

CreateReq = _Base:new {
  type = consts.ZOO_CREATE_OP,
  path = "",
  data = "",    -- buffer
  acls = {},    -- list of ACL
  flags = 0,    -- int

  dump_raw = function(self, stream)
    struct.pack_raw(">SSi", stream, self.path, self.data, #self.acls)
    for _, acl in pairs(self.acls) do
      acl:dump_raw(stream)
    end
    struct.pack_raw(">i", stream, self.flags)
    return stream
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>SSi', stream, start_idx)
    local num_acls = 0
    local acls = {}

    if err != nil then
      return start_idx, err
    end

    self.path, self.data, num_acls = unpack(vars)
    for i = 1, num_acls do
      local acl = ACL:new()
      start_idx, err = acl.load(stream, start_idx)
      if err != nil then
        return start_idx, err
      end
      table.insert(acls, acl)
    end
    self.acls = acls
    vars, start_idx, err = struct.unpack('>i', stream, start_idx)
    if err == nil then
      self.flags = unpack(vars)
    end
    return start_idx, err
  end,
}

DeleteReq = _PathVersionPacket:new{type = consts.ZOO_DELETE_OP}

GetChildrenReq = _PathWatchPacket:new{type = consts.ZOO_GETCHILDREN_OP}
GetChildren2Req = _PathWatchPacket:new{type = consts.ZOO_GETCHILDREN2_OP}

CheckVersionReq = _PathVersionPacket:new{type = consts.ZOO_CHECK_OP}
GetMaxChildrenReq = _PathPacket

SyncReq = _PathPacket:new{type = consts.ZOO_SYNC_OP}
SyncResp = _PathPacket

GetACL = _PathPacket:new{type = consts.ZOO_GETACL_OP}

-- TODO
SetACL = _Base:new {
  type = consts.ZOO_SETACL_OP,
  path = "",
  acls = {},   -- list of ACL object
  version = 0, -- int

  dump_raw = function(self, stream)
    struct.pack_raw(">Si", stream, self.path, #self.acls)
    for _, acl in pairs(self.acls) do
      acl:dump_raw(stream)
    end
    struct.pack_raw(">i", stream, self.version)
    return stream
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>Si', stream, start_idx)
    local num_acls = 0
    local acls = {}

    if err != nil then
      return start_idx, err
    end

    self.path, num_acls = unpack(vars)
    for i = 1, num_acls do
      local acl = ACL:new()
      start_idx, err = acl.load(stream, start_idx)
      if err != nil then
        return start_idx, err
      end
      table.insert(acls, acl)
    end
    self.acls = acls
    vars, start_idx, err = struct.unpack('>i', stream, start_idx)
    if err == nil then
      self.version = unpack(vars)
    end
    return start_idx, err
  end,
}

WatchEvent = _Base:new {
  type = 0,   --int
  state = 0, --int
  path = "",

  dump_raw = function(self, stream)
    return struct.pack_raw(">iiS", stream, self.type, self.state, self.path)
  end,

  load = function(self, stream, start_idx)
    start_idx = start_idx or 0
    local vars, start_idx, err = struct.unpack('>S', stream, start_idx)
    if err == nil then
      self.type, self.state, self.path = unpack(vars)
    end
    return start_idx, err
  end,
}

ExistsReq = _PathWatchPacket:new{type = consts.ZOO_EXISTS_OP}

function serialize(o, zxid)
  if o.type == consts.ZOO_PING_OP then
    zxid = consts.PING_XID
  elseif o.type == consts.ZOO_AUTH_OP then
    zxid = consts.AUTH_XID
  end
  local stream = {}
  if zxid then
    struct.pack_raw('>i', stream, zxid)
  end
  if o.type then
    struct.pack_raw('>i', stream, zxid)
  end
  o:dump_raw(stream)
  local bytes = table.concat(stream)
  local lenbytes = struct.pack(bytes:len())
  return lenbytes .. bytes
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
