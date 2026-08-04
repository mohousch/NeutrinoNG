#
# MACHINE = Gigablue Trio 4K (Pro)
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
DRIVER_DATE = 20230224
DRIVER_SRC = gbtrio4k-$(DRIVER_DATE).zip

$(ARCHIVE)/$(DRIVER_SRC):
#	$(DOWNLOAD) http://source.mynonpublic.com/gigablue/mv200/$(DRIVER_SRC)
	
driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	#unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	#mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko/* $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	#rmdir $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/hiko
	depmod -ae -b $(TARGET_DIR) -r $(KERNEL_VER)
	$(TOUCH)
	
#
# release
#
release-gbtrio4k:

#
# image
#
image-gbtrio4k:

