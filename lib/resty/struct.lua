--[[
  * Copyright (c) 2015-2016 Iryont <https://github.com/iryont/lua-struct>
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy
  * of this software and associated documentation files (the "Software"), to deal
  * in the Software without restriction, including without limitation the rights
  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  * copies of the Software, and to permit persons to whom the Software is
  * furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in
  * all copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  * THE SOFTWARE.
]]

local bit = require "bit"
local print = print
local string = string
local table = table
local tostring = tostring
local tonumber = tonumber
local math = math
local error = error
local setmetatable = setmetatable
local gunpack = unpack   -- to avoid conflict

local _M = {}

if setfenv then                 -- for lua5.1 and luajit
  setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
  _ENV = _M
else
  error("both setfenv and _ENV are nil...")
end

local function pack_int(val, numbytes, endianness)
  local bytes = {}
  for j = 1, numbytes do
    table.insert(bytes, string.char(val % (2 ^ 8)))
    val = math.floor(val / (2 ^ 8))
  end

  if not endianness then
    return string.reverse(table.concat(bytes))
  else
    return table.concat(bytes)
  end
end

local function unpack_int(stream, start_idx, numbytes, endianness, signed)
  local val = 0
  for j = 1, numbytes do
    local byte = string.byte(stream:sub(start_idx, start_idx))
    if endianness then
      val = val + byte * (2 ^ ((j - 1) * 8))
    else
      val = val + byte * (2 ^ ((numbytes - j) * 8))
    end
    start_idx = start_idx + 1
  end
  if signed and val >= 2 ^ (numbytes * 8 - 1) then
    val = val - 2 ^ (numbytes * 8)
  end
  return val
end

-- return a table.
function _M.pack_raw(format, ret_tbl, ...)
  -- local ret_tbl = {}
  local vars = {...}
  local endianness = true

  for i = 1, format:len() do
    local opt = format:sub(i, i)

    if opt == '>' then
      endianness = false
    elseif opt == '?' then
      local val = table.remove(vars, 1)
      local byte = string.char(0)
      if val == true then
        byte = string.char(1)
      end
      table.insert(ret_tbl, byte)
    elseif opt:find('[bBhHiIlL]') then
      local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
      local val = tonumber(table.remove(vars, 1))

      local bytes = {}
      for j = 1, n do
        table.insert(bytes, string.char(val % (2 ^ 8)))
        val = math.floor(val / (2 ^ 8))
      end

      if not endianness then
        table.insert(ret_tbl, string.reverse(table.concat(bytes)))
      else
        table.insert(ret_tbl, table.concat(bytes))
      end
    elseif opt:find('[fd]') then
      local val = tonumber(table.remove(vars, 1))
      local sign = 0

      if val < 0 then
        sign = 1
        val = -val
      end

      local mantissa, exponent = math.frexp(val)
      if val == 0 then
        mantissa = 0
        exponent = 0
      else
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, (opt == 'd') and 53 or 24)
        exponent = exponent + ((opt == 'd') and 1022 or 126)
      end

      local bytes = {}
      if opt == 'd' then
        val = mantissa
        for i = 1, 6 do
          table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
          val = math.floor(val / (2 ^ 8))
        end
      else
        table.insert(bytes, string.char(math.floor(mantissa) % (2 ^ 8)))
        val = math.floor(mantissa / (2 ^ 8))
        table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
        val = math.floor(val / (2 ^ 8))
      end

      table.insert(bytes, string.char(math.floor(exponent * ((opt == 'd') and 16 or 128) + val) % (2 ^ 8)))
      val = math.floor((exponent * ((opt == 'd') and 16 or 128) + val) / (2 ^ 8))
      table.insert(bytes, string.char(math.floor(sign * 128 + val) % (2 ^ 8)))
      val = math.floor((sign * 128 + val) / (2 ^ 8))

      if not endianness then
        table.insert(ret_tbl, string.reverse(table.concat(bytes)))
      else
        table.insert(ret_tbl, table.concat(bytes))
      end
    elseif opt == 's' then
      table.insert(ret_tbl, tostring(table.remove(vars, 1)))
      table.insert(ret_tbl, string.char(0))
    elseif opt == 'S' then
      -- same as `s` except:
      -- 1. it will packed length first.
      -- 2. don't append a zero byte to the end.
      local s_arg = tostring(table.remove(vars, 1))
      local len_bytes = pack_int(s_arg:len(), 4, endianness)
      table.insert(ret_tbl, len_bytes)
      table.insert(ret_tbl, s_arg)
    elseif opt == 'c' then
      local n = format:sub(i + 1):match('%d+')
      local length = tonumber(n)

      if length > 0 then
        local str = tostring(table.remove(vars, 1))
        if length - str:len() > 0 then
          str = str .. string.rep(' ', length - str:len())
        end
        table.insert(ret_tbl, str:sub(1, length))
      end
      i = i + n:len()
    end
  end
  return ret_tbl
end

function _M.pack(formt, ...)
  local tbl = {}
  local vars = {...}
  _M.pack_raw(formt, tbl, gunpack(vars))
  return table.concat(tbl)
end

function _M.unpack(format, stream, start_idx)
  start_idx = start_idx or 1
  local vars = {}
  local iterator = start_idx
  local endianness = true

  for i = 1, format:len() do
    local opt = format:sub(i, i)

    if opt == '>' then
      endianness = false
    elseif opt == '?' then
      local byte = string.byte(stream:sub(iterator, iterator))
      if byte == 1 then
        table.insert(vars, true)
      elseif byte == 0 then
        table.insert(vars, false)
      else
        return vars, string.format("get wrong value %d fot bool", byte)
      end
      iterator = iterator + 1
    elseif opt:find('[bBhHiIlL]') then
      local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
      local signed = opt:lower() == opt

      local val = 0
      for j = 1, n do
        local byte = string.byte(stream:sub(iterator, iterator))
        if endianness then
          val = val + byte * (2 ^ ((j - 1) * 8))
        else
          val = val + byte * (2 ^ ((n - j) * 8))
        end
        iterator = iterator + 1
      end

      if signed and val >= 2 ^ (n * 8 - 1) then
        val = val - 2 ^ (n * 8)
      end

      table.insert(vars, val)
    elseif opt:find('[fd]') then
      local n = (opt == 'd') and 8 or 4
      local x = stream:sub(iterator, iterator + n - 1)
      iterator = iterator + n

      if not endianness then
        x = string.reverse(x)
      end

      local sign = 1
      local mantissa = string.byte(x, (opt == 'd') and 7 or 3) % ((opt == 'd') and 16 or 128)
      for i = n - 2, 1, -1 do
        mantissa = mantissa * (2 ^ 8) + string.byte(x, i)
      end

      if string.byte(x, n) > 127 then
        sign = -1
      end

      local exponent = (string.byte(x, n) % 128) * ((opt == 'd') and 16 or 2) + math.floor(string.byte(x, n - 1) / ((opt == 'd') and 16 or 128))
      if exponent == 0 then
        table.insert(vars, 0.0)
      else
        mantissa = (math.ldexp(mantissa, (opt == 'd') and -52 or -23) + 1) * sign
        table.insert(vars, math.ldexp(mantissa, exponent - ((opt == 'd') and 1023 or 127)))
      end
    elseif opt == 's' then
      local bytes = {}
      for j = iterator, stream:len() do
        if stream:sub(j, j) == string.char(0) then
          break
        end

        table.insert(bytes, stream:sub(j, j))
      end

      local str = table.concat(bytes)
      iterator = iterator + str:len() + 1
      table.insert(vars, str)
    elseif opt == 'S' then
      local n = unpack_int(stream, iterator, 4, endianness)
      iterator = iterator + 4
      if n < 0 then
        return vars, string.format("wrong length for string %d", n)
      end
      table.insert(vars, stream:sub(iterator, iterator + tonumber(n) - 1))
      iterator = iterator + tonumber(n)
    elseif opt == 'c' then
      local n = format:sub(i + 1):match('%d+')
      table.insert(vars, stream:sub(iterator, iterator + tonumber(n)))
      iterator = iterator + tonumber(n)
      i = i + n:len()
    end
  end

  start_idx = iterator
  return vars, start_idx, nil
end

function _M.unpack_to_end(format, stream, start_idx)
  start_idx = start_idx or 1
  local vars, _, err = _M.unpack(format, stream, start_idx)
  return vars, err
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
