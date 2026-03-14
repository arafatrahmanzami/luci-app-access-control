m = Map("firewall", translate("Internet Access Control"))

s = m:section(TypedSection, "rule", translate("Access Rules"))
s.addremove = true
s.anonymous = false

mac = s:option(Value, "src_mac", translate("MAC Address"))
mac.datatype = "macaddr"

enabled = s:option(Flag, "ac_enabled", translate("Enable Rule"))
enabled.default = enabled.enabled

start = s:option(Value, "start_time", translate("Start Time (HH:MM)"))
start.placeholder = "08:00"

stop = s:option(Value, "stop_time", translate("Stop Time (HH:MM)"))
stop.placeholder = "22:00"

days = s:option(Value, "days", translate("Days (1-7)"))
days.placeholder = "1 2 3 4 5"

return m
