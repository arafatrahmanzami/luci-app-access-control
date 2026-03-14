module("luci.controller.access_control", package.seeall)

function index()

    entry({"admin","network","access_control"},
        cbi("access_control"),
        _("Access Control"),
        90)

end
