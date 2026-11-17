include $(TOPDIR)/rules.mk

PKG_NAME:=ups-monitor
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/ups-monitor
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Modern UPS monitoring web interface
  URL:=https://github.com/ospfx/ups-monitor
endef

define Package/ups-monitor/description
  Modern web-based UPS monitoring interface built with Vue 3.
  Provides real-time monitoring of UPS status, battery, and power metrics.
  Requires a running NUT server (nut-server) with upsc available.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/ups-monitor/install
	$(INSTALL_DIR) $(1)/www/ups
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(CP) ./dist/* $(1)/www/ups/
	$(INSTALL_BIN) ./files/ups-api.sh $(1)/www/cgi-bin/ups-api.sh
endef

define Package/ups-monitor/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
echo "UPS Monitor installed."
echo "Access at: http://<router-ip>/ups/"
exit 0
endef

$(eval $(call BuildPackage,ups-monitor))
