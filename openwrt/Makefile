include $(TOPDIR)/rules.mk

PKG_NAME:=ups-monitor
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/ups-monitor
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Modern UPS monitoring web interface
  DEPENDS:=+nut +nut-upsc
  PKGARCH:=all
endef

define Package/ups-monitor/description
  Modern web-based UPS monitoring interface built with Vue 3.
  Provides real-time monitoring of UPS status, battery, and power metrics.
endef

define Build/Compile
	# Frontend is pre-built, no compilation needed
endef

define Package/ups-monitor/install
	$(INSTALL_DIR) $(1)/www/ups
	$(INSTALL_DIR) $(1)/www/cgi-bin
	
	# Install frontend files
	$(CP) $(PKG_BUILD_DIR)/dist/* $(1)/www/ups/
	
	# Install CGI backend
	$(INSTALL_BIN) ./files/ups-api.sh $(1)/www/cgi-bin/ups-api.sh
endef

define Package/ups-monitor/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "UPS Monitor installed successfully!"
	echo "Access at: http://your-router-ip/ups/"
fi
exit 0
endef

$(eval $(call BuildPackage,ups-monitor))
