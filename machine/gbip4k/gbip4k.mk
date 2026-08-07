#
# MACHINE = Gigablue IP 4K
# VENDOR = Gigablue
# OEM = Gigablue
# SOC = hisi3798mv200
#

BOXARCH = arm
MACHINE_OPTS = --enable-ci --enable-fkeys --enable-4digits

#
# kernel
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20181224
KERNEL_SRC             = gigablue-linux-$(KERNEL_VER)-$(KERNEL_DATE).tar.gz
KERNEL_URL             = https://source.mynonpublic.com/gigablue/mv200
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_DTB	       = hi3798mv200.dtb
KERNEL_IMAGE           = uImage
KERNEL_FILE	       = kernel.bin

KERNEL_PATCHES  = \
		    0001-remote.patch \
		    HauppaugeWinTV-dualHD.patch \
		    dib7000-linux_4.4.179.patch \
		    dvb-usb-linux_4.4.179.patch \
		    0002-log2-give-up-on-gcc-constant-optimizations.patch \
		    0003-dont-mark-register-as-const.patch \
		    wifi-linux_4.4.183.patch \
		    move-default-dialect-to-SMB3.patch \
		    fix-dvbcore.patch \
		    0005-xbox-one-tuner-4.4.patch \
		    0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		    0007-dvb-mn88472-staging.patch \
		    mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		    fix-multiple-defs-yyloc.patch \
		    fix_highspeed_sdio.patch \
		    extend_modules_space.patch \
		    fix-build-with-binutils-2.41.patch \
		    cfg80211_Add_option_to_report_the_bss_entry_in_connect_result.patch

$(ARCHIVE)/$(KERNEL_SRC):
	$(DOWNLOAD) $(KERNEL_URL)/$(KERNEL_SRC)

$(D)/kernel.do_prepare: $(ARCHIVE)/$(KERNEL_SRC) $(BASE_DIR)/machine/$(BOXTYPE)/patches/$(KERNEL_CONFIG)
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	$(UNTARGZ)/$(KERNEL_SRC)
	set -e; cd $(KERNEL_DIR); \
		for i in $(KERNEL_PATCHES); do \
			echo -e "==> $(TERM_RED)Applying Patch:$(TERM_NORMAL) $$i"; \
			$(APATCH) $(BASE_DIR)/machine/$(BOXTYPE)/patches/$$i; \
		done
	install -m 644 $(BASE_DIR)/machine/$(BOXTYPE)/patches/$(KERNEL_CONFIG) $(KERNEL_DIR)/.config
	cp $(BASE_DIR)/machine/$(BOXTYPE)/patches/initramfs-subdirboot.cpio.gz $(KERNEL_DIR)	
ifeq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug))
	@echo "Using kernel debug"
	@grep -v "CONFIG_PRINTK" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK=y" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK_TIME=y" >> $(KERNEL_DIR)/.config
endif
	@touch $@

$(D)/kernel.do_compile: $(D)/kernel.do_prepare
	set -e; cd $(KERNEL_DIR); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNEL_DTB) uImage modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=depmod INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
		depmod -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/uImage $(TARGET_DIR)/boot/
	cat $(KERNEL_DIR)/arch/arm/boot/uImage $(KERNEL_DIR)/arch/arm/boot/dts/$(KERNEL_DTB) > $(TARGET_DIR)/boot/uImage.dtb
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.4.35
DRIVER_DATE = 20230112
DRIVER_SRC = $(BOXTYPE)-hiko-$(DRIVER_DATE).zip

$(ARCHIVE)/$(DRIVER_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/gigablue/mv200/$(DRIVER_SRC)
	
driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko/* $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	rmdir $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko
	$(MAKE) install-hisiplayer-libs
	$(MAKE) install-hilib
	$(MAKE) install-libreader
	$(MAKE) install-libjpeg
	$(MAKE) install-hihalt
	$(MAKE) install-tntfs
	depmod -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)
	
#
# libgles
#
LIBGLES_DATE = 20180301
LIBGLES_SRC = gbmv200-opengl-$(LIBGLES_DATE).tar.gz

$(ARCHIVE)/$(LIBGLES_SRC):
	$(DOWNLOAD) https://source.mynonpublic.com/gigablue/mv200/$(LIBGLES_SRC)

$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(BUILD_TMP)/hiplay
	tar xzf $(ARCHIVE)/$(LIBGLES_SRC) -C $(BUILD_TMP)/hiplay
	cp -d $(BUILD_TMP)/hiplay/usr/lib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hiplay
	
#
# hilib
#
HILIB_DATE = 20230530
HILIB_SRC = gbmv200-hilib-$(HILIB_DATE).tar.gz

$(ARCHIVE)/$(HILIB_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/gigablue/mv200/$(HILIB_SRC)

$(D)/install-hilib: $(ARCHIVE)/$(HILIB_SRC)
	install -d $(BUILD_TMP)/hilib
	tar xzf $(ARCHIVE)/$(HILIB_SRC) -C $(BUILD_TMP)/hilib
	cp -R $(BUILD_TMP)/hilib/hilib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hilib
	
#
# libreader
#
LIBREADER_DATE = 20221220
LIBREADER_SRC = $(BOXTYPE)-libreader-$(LIBREADER_DATE).tar.gz

$(ARCHIVE)/$(LIBREADER_SRC):
	$(DOWNLOAD) https://source.mynonpublic.com/gigablue/mv200/$(LIBREADER_SRC)

$(D)/install-libreader: $(ARCHIVE)/$(LIBREADER_SRC)
	install -d $(BUILD_TMP)/libreader
	tar xzf $(ARCHIVE)/$(LIBREADER_SRC) -C $(BUILD_TMP)/libreader
	install -m 0755 $(BUILD_TMP)/libreader/libreader $(TARGET_DIR)/usr/bin/libreader
	$(REMOVE)/libreader
	
#
# libjpeg
#
LIBJPEG_SRC = libjpeg.so.62.2.0

$(ARCHIVE)/$(LIBJPEG_SRC):	
	$(DOWNLOAD) https://github.com/oe-alliance/oe-alliance-core/raw/5.3/meta-brands/meta-gigablue/recipes-graphics/files/$(LIBJPEG_SRC)

$(D)/install-libjpeg: $(ARCHIVE)/$(LIBJPEG_SRC)
	cp $(ARCHIVE)/$(LIBJPEG_SRC) $(TARGET_LIB_DIR)
	
#
# hihalt
#
HIHALT_DATE = 20190907
HIHALT_SRC = gbmv200-hihalt-$(HIHALT_DATE).tar.gz

$(ARCHIVE)/$(HIHALT_SRC):
	$(DOWNLOAD) https://source.mynonpublic.com/gigablue/mv200/$(HIHALT_SRC)

$(D)/install-hihalt: $(ARCHIVE)/$(HIHALT_SRC)
	install -d $(BUILD_TMP)/hihalt
	tar xzf $(ARCHIVE)/$(HIHALT_SRC) -C $(BUILD_TMP)/hihalt
	install -m 0755 $(BUILD_TMP)/hihalt/hihalt $(TARGET_DIR)/usr/bin/hihalt
	$(REMOVE)/hihalt
	
#
# tntfs
#
TNTFS_DATE = 20200528
TNTFS_SRC = 3798mv200-tntfs-$(TNTFS_DATE).zip

$(ARCHIVE)/$(TNTFS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/tntfs/$(TNTFS_SRC)

$(D)/install-tntfs: $(ARCHIVE)/$(TNTFS_SRC)
	install -d $(BUILD_TMP)/tntfs
	unzip -o $(ARCHIVE)/$(TNTFS_SRC) -d $(BUILD_TMP)/tntfs
	install -m 0755 $(BUILD_TMP)/tntfs/tntfs.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/tntfs

#
# release
#
release-gbip4k:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/showiframe $(RELEASE_DIR)/bin
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/libreader.sh  $(RELEASE_DIR)/usr/bin/libreader.sh
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/root  $(RELEASE_DIR)/var/spool/cron/crontabs/root
	touch $(RELEASE_DIR)/var/tuxbox/config/.crond
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/suspend  $(RELEASE_DIR)/etc/init.d/suspend
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS $(RELEASE_DIR)/etc/init.d/rcS
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/libreader $(RELEASE_DIR)/etc/init.d/
	cd $(RELEASE_DIR)/etc/rc.d/rc0.d; ln -sf ../../init.d/libreader ./S05libreader
	cd $(RELEASE_DIR)/etc/rc.d/rc6.d; ln -sf ../../init.d/libreader ./S05libreader

#
# image
#
FLASHIMAGE_PREFIX = gigablue/ip4k

IMAGE_ROOTFS_SIZE ?= 524288

FLASH_PARTITONS_DATE = 20201218
FLASH_PARTITONS_SRC = $(BOXTYPE)-partitions-$(FLASH_PARTITONS_DATE).zip

$(ARCHIVE)/$(FLASH_PARTITONS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/gigablue/mv200/$(FLASH_PARTITONS_SRC)
	
-include $(HELPERS_DIR)/hisi3798mv200/hisi3798mv200.mk

image-gbip4k:
	$(MAKE) hisi3798mv200-disk-image-$(BOXTYPE) hisi3798mv200-rootfs-image-$(BOXTYPE)

