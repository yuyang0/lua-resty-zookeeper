local string = string
local table = table
local print = print
local setmetatable = setmetatable

local _M = {}

if setfenv then                 -- for lua5.1 and luajit
  setfenv(1, _M)
elseif _ENV then                -- for lua5.2 or newer
  _ENV = _M
else
  error("both setfenv and _ENV are nil...")
end

function collect_hosts(hosts)
  local i, j, host_ports, chroot
  i, j, host_ports, chroot = string.find(hosts, "([%w:., ]+)([/%w]*)")
  i = 0
  local result = {}
  for host, port in string.gfind(hosts, "([%w.]+):(%d+)[, ]*") do
    table.insert(result, {host, port})
  end
  return result, chroot
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
