# SPDX-License-Identifier: MIT
# Copyright (C) 2026 ospfx

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ups-monitor
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_MAINTAINER:=ospfx

PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-ups-monitor
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Modern UPS monitoring dashboard for NUT
  URL:=https://github.com/ospfx/ups-monitor
  DEPENDS:=+luci-base +nut-upsc
endef

define Package/luci-app-ups-monitor/description
  A modern, responsive UPS dashboard for OpenWrt/ImmortalWrt.
  Reads live values from a local NUT server through a small CGI
  helper (upsc) and renders them with Vue 3 and ECharts.
  Adds an entry to the LuCI "Services" menu.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./dist/. $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/luci-app-ups-monitor/install
	$(INSTALL_DIR) $(1)/www/ups
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ups-monitor
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(CP) $(PKG_BUILD_DIR)/. $(1)/www/ups/
	$(INSTALL_BIN) ./files/ups-api.sh $(1)/www/cgi-bin/ups-api.sh
	$(INSTALL_DATA) ./files/view/redirect.js $(1)/www/luci-static/resources/view/ups-monitor/redirect.js
	$(INSTALL_DATA) ./files/luci-app-ups-monitor.json $(1)/usr/share/luci/menu.d/luci-app-ups-monitor.json
endef

define Package/luci-app-ups-monitor/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
rm -f /tmp/luci-indexcache /tmp/luci-indexcache.* 2>/dev/null
exit 0
endef

$(eval $(call BuildPackage,luci-app-ups-monitor))
