package.path = '../../lib/resty/?.lua;' .. package.path

local tutils = require "tutils"
local table_equals = tutils.table_equals
local check_ret = tutils.check_ret

local struct = require "struct"
local utils = require "utils"

local origin_tbl, tbl, packed, err

origin_tbl = {
  123456789123456789, 123456789, -3200, 255, 'Test message', -1,  1.56789
}
packed = struct.pack('<LIhBSbd', unpack(origin_tbl))
tbl, _ = struct.unpack_to_end('<LIhBSbd', packed)

print(unpack(tbl))

check_ret(table_equals(origin_tbl, tbl))

origin_tbl = {
  12345,
  "hello",
  true,
  false,
  "world",
}

packed = struct.pack('>iS??S', unpack(origin_tbl))
-- print(unpack(origin_tbl), #origin_tbl, packed:byte(1, 200))
tbl, err = struct.unpack_to_end('>iS??S', packed)
check_ret(table_equals(origin_tbl, tbl))
