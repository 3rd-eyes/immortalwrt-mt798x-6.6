include $(TOPDIR)/rules.mk

PKG_NAME:=bandsteering
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/bandsteering
  SECTION:=MTK Properties
  CATEGORY:=MTK Properties
  TITLE:=Band Steering Daemon
  SUBMENU:=Applications
  DEPENDS:=+@KERNEL_DEVMEM
endef

define Package/bandsteering/description
  Band Steering Daemon for managing Wi-Fi client connections.
endef

define Build/Configure
endef

define Package/bandsteering/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/steering_daemon $(1)/sbin
endef


$(eval $(call BuildPackage,bandsteering))

