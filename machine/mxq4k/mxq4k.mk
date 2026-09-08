#
# MACHINE = MXQ4K
# VENDOR = Allwinner
# OEM = Allwinner
# SOC = Allwinner H3
#

BOXARCH = arm
TARGET_MARCH_CFLAGS := -march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard

MACHINE_OPTS =
MACHINE_DEPS =

#
# kernel
#
KERNEL_VER = 6.1.91
KERNEL_SRC = linux-$(KERNEL_VER).tar.xz
KERNEL_URL = https://cdn.kernel.org/pub/linux/kernel/v6.x
KERNEL_CONFIG = defconfig
KERNEL_DIR = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_IMAGE = zImage

KERNEL_PATCHES =

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=$(BOXARCH) oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=$(BOXARCH) CROSS_COMPILE=$(TARGET)- $(KERNEL_IMAGE) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=$(BOXARCH) CROSS_COMPILE=$(TARGET)- DEPMOD=depmod INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/arch/$(BOXARCH)/boot/$(KERNEL_IMAGE) $(TARGET_DIR)/boot/
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
driver: $(D)/driver
$(D)/driver:


