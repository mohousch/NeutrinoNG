#
# MACHINE = Zgemma h9
# VENDOR = zgemma
# OEM = Air Digital
# SOC = hisi3798mv200
#

BOXARCH = arm
MACHINE_OPTS = --enable-ci --enable-4digits --enable-fkeys

#
# kernel
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20200508
KERNEL_SRC             = linux-$(KERNEL_VER)-$(KERNEL_DATE)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/zgemma
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_IMAGE           = uImage
KERNEL_FILE            = uImage
KERNEL_DTB             = hi3798mv200.dtb

KERNEL_PATCHES = \
		0001-mmc-switch-1.8V.patch \
		0001-remote.patch \
		HauppaugeWinTV-dualHD.patch \
		dib7000-linux_4.4.179.patch \
		dvb-usb-linux_4.4.179.patch \
		0002-log2-give-up-on-gcc-constant-optimizations.patch \
		0003-dont-mark-register-as-const.patch \
		wifi-linux_4.4.183.patch \
		0004-linux-fix-buffer-size-warning-error.patch \
		modules_mark__inittest__exittest_as__maybe_unused.patch \
		includelinuxmodule_h_copy__init__exit_attrs_to_initcleanup_module.patch \
		Backport_minimal_compiler_attributes_h_to_support_GCC_9.patch \
		0005-xbox-one-tuner-4.4.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		0007-dvb-mn88472-staging.patch \
		mn88472_reset_stream_ID_reg_if_no_PLP_given.patch \
		af9035.patch \
		4.4.35_fix-multiple-defs-yyloc.patch
		
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
	cat $(KERNEL_DIR)/arch/arm/boot/uImage $(KERNEL_DIR)/arch/arm/boot/dts/$(KERNEL_DTB) > $(TARGET_DIR)/boot/zImage.dtb
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.4.35
DRIVER_DATE = 20201118
DRIVER_SRC = $(BOXTYPE)-drivers-$(DRIVER_VER)-$(DRIVER_DATE).zip

HICHIPSET = 3798mv200
PLAYERLIB_DATE = 20200625
PLAYERLIB_SRC = zgemma-libs-$(HICHIPSET)-$(PLAYERLIB_DATE).zip

TNTFS_DATE = 20200528
TNTFS_SRC = $(HICHIPSET)-tntfs-$(TNTFS_DATE).zip

LIBMALI_DATE = 20211026
LIBMALI_SRC = zgemma-mali-$(HICHIPSET)-$(LIBMALI_DATE).zip

MALI_MODULE_VER = DX910-SW-99002-r7p0-00rel0
MALI_MODULE_SRC = $(MALI_MODULE_VER).tgz
MALI_MODULE_PATCH = 0001-hi3798mv200-support.patch

WIFI_DIR = RTL8192EU-master
WIFI_SRC = master.zip
WIFI = RTL8192EU.zip

#LIBGLES_HEADERS = hd-v3ddriver-headers.tar.gz

$(ARCHIVE)/$(DRIVER_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(DRIVER_SRC)

$(ARCHIVE)/$(PLAYERLIB_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(PLAYERLIB_SRC)

$(ARCHIVE)/$(LIBMALI_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(LIBMALI_SRC)

$(ARCHIVE)/$(LIBGLES_HEADERS):
	$(DOWNLOAD) http://downloads.mutant-digital.net/v3ddriver/$(LIBGLES_HEADERS)

$(ARCHIVE)/$(TNTFS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/tntfs/$(TNTFS_SRC)

$(ARCHIVE)/$(WIFI_SRC):
	$(DOWNLOAD) https://github.com/zukon/RTL8192EU/archive/refs/heads/$(WIFI_SRC) -O $(ARCHIVE)/$(WIFI)

$(ARCHIVE)/$(MALI_MODULE_SRC):
	$(DOWNLOAD) https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-utgard-gpu/$(MALI_MODULE_SRC);name=driver

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(MAKE) install-tntfs
	$(MAKE) install-wifi
	$(MAKE) mali-gpu-modul
	install -m 0755 $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/turnoff_power $(TARGET_DIR)/bin
	ls -I turnoff_power $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	$(MAKE) install-hisiplayer-libs
	$(MAKE) install-libmali
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)

$(D)/install-v3ddriver: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(TARGET_LIB_DIR)
	unzip -o $(ARCHIVE)/$(LIBGLES_SRC) -d $(TARGET_LIB_DIR)
	#patchelf --set-soname libv3ddriver.so $(TARGET_LIB_DIR)/libv3ddriver.so
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libEGL.so.1.4
	ln -sf libEGL.so.1.4 $(TARGET_LIB_DIR)/libEGL.so.1
	ln -sf libEGL.so.1 $(TARGET_LIB_DIR)/libEGL.so
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libGLESv1_CM.so.1.1
	ln -sf libGLESv1_CM.so.1.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so.1
	ln -sf libGLESv1_CM.so.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libGLESv2.so.2.0
	ln -sf libGLESv2.so.2.0 $(TARGET_LIB_DIR)/libGLESv2.so.2
	ln -sf libGLESv2.so.2 $(TARGET_LIB_DIR)/libGLESv2.so
	ln -sf libv3ddriver.so $(TARGET_LIB_DIR)/libgbm.so.1
	ln -sf libgbm.so.1 $(TARGET_LIB_DIR)/libgbm.so

$(D)/install-v3ddriver-header: $(ARCHIVE)/$(LIBGLES_HEADERS)
	install -d $(TARGET_INCLUDE_DIR)
	unzip -o $(PATCHES)/$(LIBGLES_HEADERS) -d $(TARGET_INCLUDE_DIR)
	install -d $(TARGET_LIB_DIR)/pkgconfig
	cp $(PATCHES)/glesv2.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv2.pc
	cp $(PATCHES)/glesv1_cm.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv1_cm.pc
	cp $(PATCHES)/egl.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/egl.pc

$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(PLAYERLIB_SRC)
	install -d $(BUILD_TMP)/hiplay
	unzip -o $(ARCHIVE)/$(PLAYERLIB_SRC) -d $(BUILD_TMP)/hiplay
	install -d $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/hisilicon/* $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/ffmpeg/* $(TARGET_LIB_DIR)/hisilicon
#	install -m 0755 $(BUILD_TMP)/hiplay/glibc/* $(TARGET_LIB_DIR)/hisilicon
	ln -sf /lib/ld-linux-armhf.so.3 $(TARGET_LIB_DIR)/hisilicon/ld-linux.so
	$(REMOVE)/hiplay

$(D)/install-tntfs: $(ARCHIVE)/$(TNTFS_SRC)
	install -d $(BUILD_TMP)/tntfs
	unzip -o $(ARCHIVE)/$(TNTFS_SRC) -d $(BUILD_TMP)/tntfs
	install -m 0755 $(BUILD_TMP)/tntfs/tntfs.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/tntfs

$(D)/install-libmali: $(ARCHIVE)/$(LIBMALI_SRC)
	install -d $(BUILD_TMP)/libmali
	unzip -o $(ARCHIVE)/$(LIBMALI_SRC) -d $(BUILD_TMP)/libmali
	install -d $(TARGET_LIB_DIR)/hisilicon
	install -d $(TARGET_DIR)/etc/udev/rules.d
	echo 'KERNEL=="mali0", MODE="0660", GROUP="video"' > $(BUILD_TMP)/libmali/50-mali.rules
	install -m 0644 $(BUILD_TMP)/libmali/50-mali.rules  $(TARGET_DIR)/etc/udev/rules.d/50-mali.rules
	install -m 0755 $(BUILD_TMP)/libmali/libMali.so $(TARGET_LIB_DIR)/hisilicon
	ln -sf /usr/lib/hisilicon/libMali.so $(TARGET_LIB_DIR)/hisilicon/libmali.so
	ln -sf /usr/lib/hisilicon/libMali.so $(TARGET_LIB_DIR)/hisilicon/libEGL.so.1.4
	ln -sf /usr/lib/hisilicon/libEGL.so.1.4 $(TARGET_LIB_DIR)/hisilicon/libEGL.so.1
	ln -sf /usr/lib/hisilicon/libEGL.so.1 $(TARGET_LIB_DIR)/hisilicon/libEGL.so
	ln -sf /usr/lib/hisilicon/libMali.so $(TARGET_LIB_DIR)/hisilicon/libGLESv1_CM.so.1.1
	ln -sf /usr/lib/hisilicon/libGLESv1_CM.so.1.1 $(TARGET_LIB_DIR)/hisilicon/libGLESv1_CM.so.1
	ln -sf /usr/lib/hisilicon/libGLESv1_CM.so.1 $(TARGET_LIB_DIR)/hisilicon/libGLESv1_CM.so
	ln -sf /usr/lib/hisilicon/libMali.so $(TARGET_LIB_DIR)/hisilicon/libGLESv2.so.2.0
	ln -sf /usr/lib/hisilicon/libGLESv2.so.2.0 $(TARGET_LIB_DIR)/hisilicon/libGLESv2.so.2
	ln -sf /usr/lib/hisilicon/libGLESv2.so.2 $(TARGET_LIB_DIR)/hisilicon/libGLESv2.so
	ln -sf /usr/lib/hisilicon/libMali.so $(TARGET_LIB_DIR)/hisilicon/libgbm.so.1
	ln -sf /usr/lib/hisilicon/libgbm.so.1 $(TARGET_LIB_DIR)/hisilicon/libgbm.so
	$(REMOVE)/libmali

$(D)/install-wifi: $(D)/bootstrap $(D)/kernel $(ARCHIVE)/$(WIFI_SRC)
	$(START_BUILD)
	$(REMOVE)/$(WIFI_DIR)
	unzip -o $(ARCHIVE)/$(WIFI) -d $(BUILD_TMP)
	echo $(KERNEL_DIR)
	$(CHDIR)/$(WIFI_DIR); \
		$(MAKE) ARCH=arm CROSS_COMPILE=$(TARGET)- KVER=$(DRIVER_VER) KSRC=$(KERNEL_DIR); \
		install -m 644 8192eu.ko $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(REMOVE)/$(WIFI_DIR)
	$(TOUCH)

$(D)/mali-gpu-modul: $(ARCHIVE)/$(MALI_MODULE_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	$(REMOVE)/$(MALI_MODULE_VER)
	$(UNTAR)/$(MALI_MODULE_SRC)
	$(CHDIR)/$(MALI_MODULE_VER); \
		$(call apply_patches, $(MALI_MODULE_PATCH)); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y ; \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y \
		DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	$(REMOVE)/$(MALI_MODULE_VER)
	$(TOUCH)

#
# release
#
release-h9:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS $(RELEASE_DIR)/etc/init.d/rcS
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	
#
# image
#
FLASH_PREFIX = $(BOXTYPE)

HICHIPSET = 3798mv200
BOOTARGS_DATE = 20200916
BOOTARGS_SRC = zgemma-bootargs-$(HICHIPSET)-$(BOOTARGS_DATE).zip

FASTBOOT_DATE = 20200916
FASTBOOT_SRC = zgemma-fastboot-$(HICHIPSET)-$(FASTBOOT_DATE).zip

PARAM_DATE = 20190530
PARAM_SRC = zgemma-param-$(HICHIPSET)-$(PARAM_DATE).zip

$(ARCHIVE)/$(BOOTARGS_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(BOOTARGS_SRC)

$(ARCHIVE)/$(FASTBOOT_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(FASTBOOT_SRC)

$(ARCHIVE)/$(PARAM_SRC):
	$(DOWNLOAD) http://source.mynonpublic.com/zgemma/$(PARAM_SRC)

-include $(HELPERS_DIR)/zgemma/zgemma.mk
	
image-h9:
	$(MAKE) zgemma-ubi-image-h9

