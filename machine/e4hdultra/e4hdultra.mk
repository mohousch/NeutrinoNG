#
# MACHINE = Axas E4HD Ultra
# VENDOR = Axas
# OEM = Ceryon
# CPU = bcm7252s
#

BOXARCH = arm
MACHINE_OPTS = --enable-ci --enable-tftlcd --enable-4k --enable-cec

#
# kernel
#
KERNEL_VER             = 4.10.12
KERNEL_DATE            = 20180424
KERNEL_SRC             = linux-$(KERNEL_VER)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/gfutures
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_IMAGE           = zImage
KERNEL_FILE	       = kernel.bin

KERNEL_PATCHES = \
		TBS-fixes-for-4.10-kernel.patch \
		0001-Support-TBS-USB-drivers-for-4.6-kernel.patch \
		0001-TBS-fixes-for-4.6-kernel.patch \
		0001-STV-Add-PLS-support.patch \
		0001-STV-Add-SNR-Signal-report-parameters.patch \
		blindscan2.patch \
		dvbs2x.patch \
		0001-stv090x-optimized-TS-sync-control.patch \
		reserve_dvb_adapter_0.patch \
		blacklist_mmc0.patch \
		export_pmpoweroffprepare.patch \
		fix-multiple-defs-yyloc.patch \
		v3-1-3-media-si2157-Add-support-for-Si2141-A10.patch \
		v3-2-3-media-si2168-add-support-for-Si2168-D60.patch \
		v3-3-3-media-dvbsky-MyGica-T230C-support.patch \
		v3-3-4-media-dvbsky-MyGica-T230C-support.patch \
		v3-3-5-media-dvbsky-MyGica-T230C-support.patch \
		0002-cp1emu-do-not-use-bools-for-arithmetic.patch \
		move-default-dialect-to-SMB3.patch \
		add-more-devices-rtl8xxxu.patch \
		0005-xbox-one-tuner-4.10.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch

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
ifeq ($(LAYOUT), multiboot)
	sed -i -e 's#CONFIG_INITRAMFS_SOURCE=""#CONFIG_INITRAMFS_SOURCE="initramfs-subdirboot.cpio.gz"\nCONFIG_INITRAMFS_ROOT_UID=0\nCONFIG_INITRAMFS_ROOT_GID=0#g' $(KERNEL_DIR)/.config
	cp $(BASE_DIR)/machine/$(BOXTYPE)/patches/initramfs-subdirboot.cpio.gz $(KERNEL_DIR)
endif
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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- zImage modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/zImage $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)
	
#
# driver
#
DRIVER_DATE = 20191101
DRIVER_VER = 4.10.12-$(DRIVER_DATE)
DRIVER_SRC = e4hd-drivers-$(DRIVER_VER).zip
DRIVER_URL = http://source.mynonpublic.com/ceryon

$(ARCHIVE)/$(DRIVER_SRC):
	$(DOWNLOAD) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver	
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(DEPMOD) -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)
	
#
# release
#
release-e4hdultra:
	cp -pa $(TARGET_DIR)/lib/modules/$(KERNEL_VER) $(RELEASE_DIR)/lib/modules
	install -m 0755 $(SKEL_ROOT)/etc/init.d/mmcblk-by-name $(RELEASE_DIR)/etc/init.d/mmcblk-by-name
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS $(RELEASE_DIR)/etc/init.d/rcS
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
ifeq ($(LAYOUT), multiboot)
	sed -i -e 's#/dev/mmcblk0p10#/dev/mmcblk0p7#g' $(RELEASE_DIR)/etc/fstab
	sed -i -e 's#/dev/mmcblk0p11#/dev/mmcblk0p9#g' $(RELEASE_DIR)/etc/fstab
endif

#
# image
#
FLASHIMAGE_PREFIX = e4hd

ifeq ($(LAYOUT), multiboot)
-include $(HELPERS_DIR)/gfuture/gfuture_multiboot.mk
else
-include $(HELPERS_DIR)/gfuture/gfuture_multi.mk
endif

image-e4hdultra:
	$(MAKE) gfuture-disk-image-$(BOXTYPE) gfuture-rootfs-image-$(BOXTYPE)

