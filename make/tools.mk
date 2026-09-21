#
# tools-clean
#
tools-clean:
	rm -f $(D)/tools-*
	-$(MAKE) -C $(TOOLS_DIR)/aio-grab-$(BOXARCH) clean
	-$(MAKE) -C $(TOOLS_DIR)/showiframe-$(BOXARCH) clean
ifeq ($(BOXARCH), sh4)
	-$(MAKE) -C $(TOOLS_DIR)/evremote2 clean
	-$(MAKE) -C $(TOOLS_DIR)/fp_control clean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-fup clean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-mup clean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-pad clean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ipbox55 ipbox99 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
	-$(MAKE) -C $(TOOLS_DIR)/ipbox_eeprom clean
endif
	-$(MAKE) -C $(TOOLS_DIR)/stfbcontrol clean
	-$(MAKE) -C $(TOOLS_DIR)/ustslave clean
	-$(MAKE) -C $(TOOLS_DIR)/vfdctl clean
	-$(MAKE) -C $(TOOLS_DIR)/wait4button clean
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo vuduo2 vuduo4k vuduo4kse vuuno4kse vuzero4k vuultimo4k vuuno4k vusolo4k))
	-$(MAKE) -C $(TOOLS_DIR)/turnoff_power clean
endif

#
# tools-distclean
#
tools-distclean:
	rm -f $(D)/tools-*
	-$(MAKE) -C $(TOOLS_DIR)/aio-grab-$(BOXARCH) distclean
	-$(MAKE) -C $(TOOLS_DIR)/showiframe-$(BOXARCH) distclean
ifeq ($(BOXARCH), sh4)
	-$(MAKE) -C $(TOOLS_DIR)/evremote2 distclean
	-$(MAKE) -C $(TOOLS_DIR)/fp_control distclean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-fup distclean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-mup distclean
	-$(MAKE) -C $(TOOLS_DIR)/flashtool-pad distclean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ipbox55 ipbox99 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
	-$(MAKE) -C $(TOOLS_DIR)/ipbox_eeprom distclean
endif
	-$(MAKE) -C $(TOOLS_DIR)/stfbcontrol distclean
	-$(MAKE) -C $(TOOLS_DIR)/ustslave distclean
	-$(MAKE) -C $(TOOLS_DIR)/vfdctl distclean
	-$(MAKE) -C $(TOOLS_DIR)/wait4button distclean
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo vuduo2 vuduo4k vuduo4kse vuuno4kse vuzero4k vuultimo4k vuuno4k vusolo4k))
	-$(MAKE) -C $(TOOLS_DIR)/turnoff_power distclean
endif

#
# aio-grab
#
$(D)/tools-aio-grab: $(D)/bootstrap $(D)/libpng $(D)/libjpeg
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/aio-grab-$(BOXARCH); \
		$(CONFIGURE) CPPFLAGS="$(CPPFLAGS) -I$(DRIVER_DIR)/bpamem" \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
# aio-grab-package
#
aio-grab-ipk: $(D)/bootstrap $(D)/libpng $(D)/libjpeg
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	set -e; cd $(TOOLS_DIR)/aio-grab-$(BOXARCH); \
		$(CONFIGURE) CPPFLAGS="$(CPPFLAGS) -I$(DRIVER_DIR)/bpamem" \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/aio-grab/control
	touch $(BUILD_TMP)/aio-grab/control/control
	echo Package: aio-grab > $(BUILD_TMP)/aio-grab/control/control
	echo Section: applications >> $(BUILD_TMP)/aio-grab/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/aio-grab/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/aio-grab/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/aio-grab/control/control 
	echo Depends:  >> $(BUILD_TMP)/aio-grab/control/control
	pushd $(BUILD_TMP)/aio-grab/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/aio-grab_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/aio-grab
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# evremote2
#
$(D)/tools-evremote2: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/evremote2; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# fp_control
#
$(D)/tools-fp_control: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/fp_control; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# flashtool_mup-box
#
$(D)/tools_flashtool_mup:
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/flashtool_mup; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# hotplug
#
$(D)/tools-hotplug: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/hotplug; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# ipbox_eeprom
#
$(D)/tools-ipbox_eeprom: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/ipbox_eeprom; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
# eplayer4
#
EPLAYER4_CPPFLAGS     = $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
EPLAYER4_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
EPLAYER4_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
EPLAYER4_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
$(D)/tools-eplayer4: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_good \
	$(D)/gst_plugins_bad $(D)/gst_plugins_ugly $(D)/gst_plugins_subsink $(D)/gst_plugins_dvbmediasink
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/eplayer4; \
		$(CONFIGURE) \
			CPPFLAGS="$(EPLAYER4_CPPFLAGS)" \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# libmme_host
#
$(D)/tools-libmme_host: $(D)/bootstrap $(D)/driver
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/libmme_host; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE) DRIVER_TOPDIR=$(DRIVER_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) DRIVER_TOPDIR=$(DRIVER_DIR)
	$(TOUCH)

#
# libmme_image
#
$(D)/tools-libmme_image: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/libmme_image; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE) DRIVER_TOPDIR=$(DRIVER_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) DRIVER_TOPDIR=$(DRIVER_DIR)
	$(TOUCH)

#
# minimon
#
$(D)/tools-minimon: $(D)/bootstrap $(D)/libjpeg_turbo
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/minimon-$(BOXARCH); \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE) KERNEL_DIR=$(KERNEL_DIR) TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR); \
		$(MAKE) install KERNEL_DIR=$(KERNEL_DIR) TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR) DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# satfind
#
$(D)/tools-satfind: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/satfind; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# showiframe
#
$(D)/tools-showiframe: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/showiframe-$(BOXARCH); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
# showiframe-package
#
showiframe-package: $(D)/bootstrap
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	set -e; cd $(TOOLS_DIR)/showiframe-$(BOXARCH); \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/showiframe/control
	touch $(BUILD_TMP)/showiframe/control/control
	echo Package: showiframe > $(BUILD_TMP)/showiframe/control/control
#	echo Version: $(SHOWIFRAME_VER) >> $(BUILD_TMP)/showiframe/control/control
	echo Section: applications >> $(BUILD_TMP)/showiframe/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/showiframe/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/showiframe/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/showiframe/control/control 
	echo Depends:  >> $(BUILD_TMP)/showiframe/control/control
	pushd $(BUILD_TMP)/showiframe/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/showiframe_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/showiframe
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# spf_tool
#
$(D)/tools-spf_tool: $(D)/bootstrap $(D)/libusb
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/spf_tool; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# stfbcontrol
#
$(D)/tools-stfbcontrol: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/stfbcontrol; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# ustslave
#
$(D)/tools-ustslave: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/ustslave; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# vfdctl
#
ifeq ($(BOXTYPE), spark7162)
EXTRA_CPPFLAGS=-DHAVE_SPARK7162_HARDWARE
endif

$(D)/tools-vfdctl: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/vfdctl; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE) CPPFLAGS="$(EXTRA_CPPFLAGS)"; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# wait4button
#
$(D)/tools-wait4button: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/wait4button; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
# turnoff_power
#
$(D)/tools-turnoff_power: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/turnoff_power; \
		$(CONFIGURE) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

