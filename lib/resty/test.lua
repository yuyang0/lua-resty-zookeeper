require "struct"
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
