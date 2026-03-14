#!/usr/bin/lua
require "uci"

local x = uci.cursor()
local commit = false

x:foreach("firewall","rule",function(s)
    if s.ac_enabled ~= nil then
        x:delete("firewall", s[".name"])
        commit = true
    end
end)

if commit then x:commit("firewall") end
