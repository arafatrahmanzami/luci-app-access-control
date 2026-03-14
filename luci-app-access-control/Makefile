include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Internet Access Control
LUCI_NAME:=luci-app-access-control
PKG_VERSION:=0.4.3
PKG_RELEASE:=1

define Package/luci-app-access-control/postinst
#!/bin/sh
/etc/init.d/inetac enable
/etc/init.d/inetac start
exit 0
endef

define Package/luci-app-access-control/prerm
#!/bin/sh
/etc/init.d/inetac stop
/etc/init.d/inetac disable
/usr/sbin/inetac_cleanup.lua
exit 0
endef

include $(INCLUDE_DIR)/luci.mk
