local CONFIG_FILE_RULES = "firewall"
local CONFIG_FILE_AC = "access_control"
local Days = {'mon','tue','wed','thu','fri','sat','sun'}
local Days1 = translate('MTWTFSS')

local function time_elapsed(tend)
    local now = math.floor(os.time() / 60)
    return now > math.floor(tonumber(tend) / 60)
end

local ma = Map(CONFIG_FILE_AC, translate("Internet Access Control"),
    translate("Access Control allows you to manage Internet access for specific local hosts."))
local mr
if CONFIG_FILE_AC == CONFIG_FILE_RULES then
    mr = ma
else
    mr = Map(CONFIG_FILE_RULES)
end

function mr.on_after_commit(self)
    os.execute("/etc/init.d/inetac restart >/dev/null 2>/dev/null")
end

-- General Section
local s_gen = ma:section(NamedSection, "general", "access_control", translate("General settings"))
local o_global_enable = s_gen:option(Flag, "enabled", translate("Enabled"))
o_global_enable.rmempty = false

local o_ticket = s_gen:option(Value, "ticket", translate("Ticket time [min]"))
o_ticket.datatype = "uinteger"
o_ticket.default = 60

-- Rule Section
local s_rule = mr:section(TypedSection, "rule", translate("Client Rules"))
s_rule.addremove = true
s_rule.anonymous = true
s_rule.template = "cbi/tblsection"
s_rule.defaults.ac_suspend = nil
s_rule.defaults.enabled = "0"
s_rule.defaults.src = "*"
s_rule.defaults.dest = "wan"
s_rule.defaults.target = "REJECT"
s_rule.defaults.proto = "0"
s_rule.defaults.extra = "--kerneltz"
s_rule.filter = function(self, section)
    return self.map:get(section, "ac_enabled") ~= nil
end

local o = s_rule:option(Flag, "ac_enabled", translate("Enabled"))
o.default = '1'
o.rmempty = false

function o.write(self, section, value)
    wd_write(self, section)
    local key = o_global_enable:cbid(o_global_enable.section.section)
    local enable = (o_global_enable.map:formvalue(key) == '1') and (value == '1')

    if not enable then
        self.map:del(section, "ac_suspend")
    else
        local ac_susp = self.map:get(section, "ac_suspend")
        if ac_susp and time_elapsed(ac_susp) then
            self.map:del(section, "ac_suspend")
            ac_susp = nil
        end
        if ac_susp then enable = false end
    end

    self.map:set(section, "enabled", enable and '1' or '0')
    return Flag.write(self, section, value)
end

s_rule:option(Value, "name", translate("Description"))
o = s_rule:option(Value, "src_mac", translate("MAC address"))
o.rmempty = false
o.datatype = "macaddr"
luci.sys.net.mac_hints(function(mac, name) o:value(mac, "%s (%s)" %{mac, name}) end)

local function validate_time(self, value)
    local hh, mm = string.match(value, "^(%d?%d):(%d%d)$")
    hh, mm = tonumber(hh), tonumber(mm)
    if hh and mm and hh <= 23 and mm <= 59 then return value end
    return nil, translate("Time value must be HH:MM or empty")
end

o = s_rule:option(Value, "start_time", translate("Start time"))
o.rmempty = true
o.validate = validate_time
o.size = 5
o = s_rule:option(Value, "stop_time", translate("End time"))
o.rmempty = true
o.validate = validate_time
o.size = 5

-- Days Flags
local function make_day(nday)
    local day = Days[nday]
    local label = Days1:sub(nday, nday)
    if nday == 7 then label = '<font color="red">'..label..'</font>' end
    local o = s_rule:option(Flag, day, label)
    o.rmempty = false
    function o.cfgvalue(self, section)
        local days = self.map:get(section, "weekdays")
        if not days then return '1' end
        return string.find(days, day) and '1' or '0'
    end
    function o.write(self, section, value)
        self.map:del(section, self.option)
    end
end

for i=1,7 do make_day(i) end

function wd_write(self, section)
    local value, cnt = '', 0
    for _, day in ipairs(Days) do
        local key = "cbid."..self.map.config.."."..section.."."..day
        if mr:formvalue(key) then value = value..' '..day; cnt = cnt + 1 end
    end
    if cnt == 7 then value = '' end
    self.map:set(section, "weekdays", value)
end

-- Ticket Button
o = s_rule:option(Button, "_ticket", translate("Ticket"))
o:depends("ac_enabled", "1")
function o.cfgvalue(self, section)
    local ac_susp = self.map:get(section, "ac_suspend")
    if ac_susp then
        if time_elapsed(ac_susp) then
            self.map:del(section, "ac_suspend")
            ac_susp = nil
        else
            local tend = os.date("%H:%M", ac_susp)
            self.inputtitle = tend.."\n"..translate("Cancel")
            self.inputstyle = 'remove'
        end
    end
    if not ac_susp then
        self.inputtitle = translate("Issue")
        self.inputstyle = 'add'
    end
end

function o.write(self, section, value)
    local ac_susp = self.map:get(section, "ac_suspend")
    local t = o_ticket.map:get(o_ticket.section.section, o_ticket.option)
    t = tonumber(t) * 60
    if ac_susp then ac_susp = "" else ac_susp = os.time() + t end
    self.map:set(section, "ac_suspend", ac_susp)
end

if CONFIG_FILE_AC == CONFIG_FILE_RULES then return ma else return ma, mr end
