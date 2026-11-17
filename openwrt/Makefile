# SPDX-License-Identifier: MIT
# Copyright (C) 2026 ospfx

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ups-monitor
PKG_VERSION:=1.2.0
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
	$(CP) $(PKG_BUILD_DIR)/dist/. $(1)/www/ups/
	$(INSTALL_DATA) ./files/view/dashboard.js $(1)/www/luci-static/resources/view/ups-monitor/dashboard.js
	$(INSTALL_DATA) ./files/controller/ups_monitor.uc $(1)/usr/share/ucode/luci/controller/ups_monitor.uc
	$(INSTALL_DATA) ./files/luci-app-ups-monitor.json $(1)/usr/share/luci/menu.d/luci-app-ups-monitor.json
endef

define Package/luci-app-ups-monitor/postinst
#!/bin/sh
case "$${IPKG_INSTROOT}" in
	""|"/")
		rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*.json 2>/dev/null
		;;
esac
exit 0
endef

$(eval $(call BuildPackage,luci-app-ups-monitor))
