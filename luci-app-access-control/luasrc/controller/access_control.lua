module("luci.controller.access_control", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/firewall") then
        return
    end
    if not nixio.fs.access("/etc/config/access_control") then
        return
    end

    local page = entry({"admin","network","access_control"},
                       cbi("access_control"),
                       _("Access Control"))
    page.dependent = true
end
