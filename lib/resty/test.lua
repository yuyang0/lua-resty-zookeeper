local struct = require "struct"
-- local packed = struct.pack('<LIhBsbfd', 123456789123456789, 123456789, -3200, 255, 'Test message', -1, 1.56789, 1.56789)
-- print(packed)
-- local L, I, h, B, s, b, f, d = struct.unpack('<LIhBsbfd', packed)
-- print(L, I, h, B, s, b, f, d)

local ss = "hello"
packed = struct.pack('?S', false, ss)
print(packed:byte(1, 19))

print(struct.unpack("?S", packed))
print(struct.unpack_to_end("?S", packed))
-- packed = struct.pack('c3', ss)
-- print(packed)

-- packed = struct.pack('>h', 256)
-- print(packed:byte(1, 2))

-- local _Base = {
--   new = function(self, o)
--     o = o or {}
--     -- create object if user does not provide one
--     setmetatable(o, self)
--     self.__index = self
--     return o
--   end,

--   dump = function(self)
--     local stream = {}
--     self:dump_raw(stream)
--     return table.concat(stream)
--   end,

--   -- just a place holder
--   dump_raw = function(self, stream)
--     return stream
--   end,

--   -- just a place holder
--   load = function(self, stream, start_idx)
--     return start_idx, nil
--   end,
-- }

-- local _PathWatchPacket = _Base:new {
--   path = "",
--   watch = false,  -- boolean

--   dump_raw = function(self, stream)
--     return struct.pack_raw('>S?', stream, self.path, self.watch)
--   end,

--   load = function(self, stream, start_idx)
--     start_idx = start_idx or 0
--     local vars, start_idx, err = struct.unpack('>S?', stream, start_idx)
--     if err == nil then
--       self.path, self.watch = unpack(vars)
--     end
--     return start_idx, err
--   end,
-- }

-- local o = _PathWatchPacket:new{path='/aa/bb', watch=true}
-- local packed = o:dump()
-- print(packed:byte(1, 100))

-- local o2 = _PathWatchPacket:new()
-- o2:load(packed, 1)
-- print(o2.path, o2.path:len(), o2.watch)
