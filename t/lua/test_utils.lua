package.path = '../../lib/resty/?.lua;' .. package.path

local utils = require "utils"

local hosts = "127.0.0.1:123, 111.222.333.444:321/aa/bb"
local ret, chroot = utils.collect_hosts(hosts)

print(#ret, chroot)

local hosts = "127.0.0.1:123/aa/bb"
local ret, chroot = utils.collect_hosts(hosts)

print(#ret, chroot)

local hosts = "127.0.0.1:123, 444.555.666:234"
local ret, chroot = utils.collect_hosts(hosts)

print(#ret, chroot)
