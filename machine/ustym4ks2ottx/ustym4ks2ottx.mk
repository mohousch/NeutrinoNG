#
# MACHINE = Ustym 4k s2 ottx
# VENDOR = Uclan
# OEM = Uclan
# SOC = hisi3798mv300
#

BOXARCH = arm
MACHINE_OPTS = --enable-ci --enable-4digits --enable-fkeys --enable-4k

#
# kernel
#
KERNEL_VER             = 4.4.176
KERNEL_DATE            = 20221203
KERNEL_SRC             = uclan-linux-$(KERNEL_VER)-$(KERNEL_DATE).tar.gz
KERNEL_URL             = http://source.mynonpublic.com/uclan
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_IMAGE           = uImage
KERNEL_FILE            = kernel.bin
KERNEL_DTB             = hi3798mv200.dtb

KERNEL_PATCHES = \
		HauppaugeWinTV-dualHD.patch \
		move-default-dialect-to-SMB3.patch \
		0005-xbox-one-tuner-4.4.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		0007-dvb-mn88472-staging.patch \
		mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		af9035.patch \
		fix-multiple-defs-yyloc.patch
		
$(ARCHIVE)/$(KERNEL_SRC):
	$(DOWNLOAD) $(KERNEL_URL)/$(KERNEL_SRC)

$(D)/kernel.do_prepare: $(ARCHIVE)/$(KERNEL_SRC) $(BASE_DIR)/machine/$(BOXTYPE)/patches/$(KERNEL_CONFIG)
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	$(UNTAR)/$(KERNEL_SRC)
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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
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
DRIVER_VER     = $(KERNEL_VER)
DRIVER_DATE    = 20230616
HILIB_DATE     = 20221203
LIBGLES_DATE   = 20221203
LIBREADER_DATE = 20230217
HIHALT_DATE    = 20230217
TNTFS_DATE     = 20230217

HICHIPSET = 3798mv300
SOC_FAMILY = hisi3798mv300

DRIVER_SRC = $(BOXTYPE)-hiko-$(DRIVER_DATE).zip

HILIB_SRC = $(BOXTYPE)-hilib-$(HILIB_DATE).tar.gz

LIBGLES_SRC = $(SOC_FAMILY)-opengl-$(LIBGLES_DATE).tar.gz

LIBREADER_SRC = $(BOXTYPE)-libreader-$(LIBREADER_DATE).tar.gz

HIHALT_SRC = $(SOC_FAMILY)-hihalt-$(HIHALT_DATE).tar.gz

TNTFS_SRC = $(HICHIPSET)-tntfs-$(TNTFS_DATE).zip

LIBJPEG_SRC = libjpeg.so.8.2.2

$(ARCHIVE)/$(DRIVER_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(DRIVER_SRC)

$(ARCHIVE)/$(HILIB_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(HILIB_SRC)

$(ARCHIVE)/$(LIBGLES_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(LIBGLES_SRC)

$(ARCHIVE)/$(LIBREADER_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(LIBREADER_SRC)

$(ARCHIVE)/$(HIHALT_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(HIHALT_SRC)

$(ARCHIVE)/$(TNTFS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/tntfs/$(TNTFS_SRC)

$(ARCHIVE)/$(LIBJPEG_SRC):	
	$(DOWNLOAD) https://github.com/oe-alliance/oe-alliance-core/raw/5.3/meta-brands/meta-uclan/recipes-graphics/files/$(LIBJPEG_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko/* $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	rmdir $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko
	$(MAKE) install-tntfs
	$(MAKE) install-hisiplayer-libs
	$(MAKE) install-hilib
	$(MAKE) install-libjpeg
	$(MAKE) install-hihalt
	$(MAKE) install-libreader
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)

$(D)/install-hilib: $(ARCHIVE)/$(HILIB_SRC)
	install -d $(BUILD_TMP)/hilib
	tar xzf $(ARCHIVE)/$(HILIB_SRC) -C $(BUILD_TMP)/hilib
	cp -R $(BUILD_TMP)/hilib/hilib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hilib

$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(BUILD_TMP)/hiplay
	tar xzf $(ARCHIVE)/$(LIBGLES_SRC) -C $(BUILD_TMP)/hiplay
	cp -d $(BUILD_TMP)/hiplay/usr/lib/* $(TARGET_LIB_DIR)
	$(REMOVE)/hiplay

$(D)/install-libreader: $(ARCHIVE)/$(LIBREADER_SRC)
	install -d $(BUILD_TMP)/libreader
	tar xzf $(ARCHIVE)/$(LIBREADER_SRC) -C $(BUILD_TMP)/libreader
	install -m 0755 $(BUILD_TMP)/libreader/libreader $(TARGET_DIR)/usr/bin/libreader
	$(REMOVE)/libreader

$(D)/install-tntfs: $(ARCHIVE)/$(TNTFS_SRC)
	install -d $(BUILD_TMP)/tntfs
	unzip -o $(ARCHIVE)/$(TNTFS_SRC) -d $(BUILD_TMP)/tntfs
	install -m 0755 $(BUILD_TMP)/tntfs/tntfs.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/tntfs

$(D)/install-hihalt: $(ARCHIVE)/$(HIHALT_SRC)
	install -d $(BUILD_TMP)/hihalt
	tar xzf $(ARCHIVE)/$(HIHALT_SRC) -C $(BUILD_TMP)/hihalt
	install -m 0755 $(BUILD_TMP)/hihalt/hihalt $(TARGET_DIR)/usr/bin/hihalt
	$(REMOVE)/hihalt

$(D)/install-libjpeg: $(ARCHIVE)/$(LIBJPEG_SRC)
	cp $(ARCHIVE)/$(LIBJPEG_SRC) $(TARGET_LIB_DIR)
	cd $(TARGET_LIB_DIR); ln -sf $(LIBJPEG_SRC) ./libjpeg.so.8

#
# release
#
release-ustym4ks2ottx:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/showiframe $(RELEASE_DIR)/bin
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/libreader.sh  $(RELEASE_DIR)/usr/bin/libreader.sh
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/root  $(RELEASE_DIR)/var/spool/cron/crontabs/root
	touch $(RELEASE_DIR)/var/tuxbox/config/.crond
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/suspend  $(RELEASE_DIR)/etc/init.d/suspend
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/libreader $(RELEASE_DIR)/etc/init.d/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS $(RELEASE_DIR)/etc/init.d/rcS
	cd $(RELEASE_DIR)/etc/rc.d/rc0.d; ln -sf ../../init.d/libreader ./S05libreader
	cd $(RELEASE_DIR)/etc/rc.d/rc6.d; ln -sf ../../init.d/libreader ./S05libreader
	
#
# image
#
FLASHIMAGE_PREFIX = $(BOXTYPE)

FLASH_PARTITONS_DATE = 20230217
FLASH_PARTITONS_SRC = $(BOXTYPE)-partitions-$(FLASH_PARTITONS_DATE).zip

$(ARCHIVE)/$(FLASH_PARTITONS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/uclan/$(FLASH_PARTITONS_SRC)

-include $(HELPERS_DIR)/octagon/octagon.mk

image-ustym4ks2ottx:
	$(MAKE) octagon-disk-image-$(BOXTYPE) octagon-rootfs-image-$(BOXTYPE)

