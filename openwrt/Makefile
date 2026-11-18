# SPDX-License-Identifier: MIT
# Copyright (C) 2026 ospfx

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ups-monitor
PKG_VERSION:=1.4.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_MAINTAINER:=ospfx

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-ups-monitor
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Modern UPS monitoring dashboard for NUT
  URL:=https://github.com/ospfx/ups-monitor
  DEPENDS:=+luci-base +nut-upsc
  PKGARCH:=all
endef

define Package/luci-app-ups-monitor/description
  A modern, responsive UPS dashboard for OpenWrt/ImmortalWrt.
  Runs inside LuCI ("Services -> UPS Monitor") and reads live values
  from the local NUT server through a session-protected JSON endpoint
  backed by upsc.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/dist
	$(CP) ./dist/. $(PKG_BUILD_DIR)/dist/
endef

define Build/Compile
endef

define Package/luci-app-ups-monitor/install
	$(INSTALL_DIR) $(1)/www/ups
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ups-monitor
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/ucode/luci/controller
	$(INSTALL_DIR) $(1)/usr/share/ups-monitor
	$(INSTALL_DIR) $(1)/usr/lib/nut
	$(CP) $(PKG_BUILD_DIR)/dist/. $(1)/www/ups/
	$(INSTALL_DATA) ./files/view/dashboard.js $(1)/www/luci-static/resources/view/ups-monitor/dashboard.js
	$(INSTALL_DATA) ./files/controller/ups_monitor.uc $(1)/usr/share/ucode/luci/controller/ups_monitor.uc
	$(INSTALL_DATA) ./files/luci-app-ups-monitor.json $(1)/usr/share/luci/menu.d/luci-app-ups-monitor.json
	$(INSTALL_DATA) ./files/etc/config/nut_server $(1)/usr/share/ups-monitor/nut_server.default
	$(INSTALL_BIN) ./files/usr/lib/nut/uci-to-nut.sh $(1)/usr/lib/nut/uci-to-nut.sh
endef

define Package/luci-app-ups-monitor/postinst
#!/bin/sh
case "$${IPKG_INSTROOT}" in
	""|"/")
		# Clear LuCI cache
		rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*.json 2>/dev/null
		
		# Install default UCI config if not exists
		[ -f /etc/config/nut_server ] || cp /usr/share/ups-monitor/nut_server.default /etc/config/nut_server
		
		# Commit UCI and generate NUT config
		uci commit nut_server 2>/dev/null
		/usr/lib/nut/uci-to-nut.sh 2>/dev/null || true
		
		# Ensure usbhid module is loaded
		grep -q "^usbhid" /etc/modules 2>/dev/null || echo "usbhid" >> /etc/modules
		modprobe usbhid 2>/dev/null || true
		
		# Create hotplug script for USB UPS devices
		cat > /etc/hotplug.d/usb/20-nut-ups <<'HOTPLUG_EOF'
#!/bin/sh
# Automatically set permissions for USB UPS devices

[ "$ACTION" = "add" ] || exit 0

# Common UPS USB IDs - add more as needed
case "$PRODUCT" in
	665/5161/*|51d/2/*)  # INNO TECH, APC
		sleep 1
		for dev in /dev/hidraw*; do
			[ -e "$dev" ] && {
				chgrp nut "$dev" 2>/dev/null
				chmod 660 "$dev" 2>/dev/null
			}
		done
		;;
esac
HOTPLUG_EOF
		chmod +x /etc/hotplug.d/usb/20-nut-ups
		;;
esac
exit 0
endef

$(eval $(call BuildPackage,luci-app-ups-monitor))
