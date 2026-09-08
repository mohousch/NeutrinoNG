#
# MACHINE = MXQ4K
# VENDOR = Allwinner
# OEM = Allwinner
# SOC = Allwinner H3
#

BOXARCH = arm
TARGET_MARCH_CFLAGS := -march=armv7a -mtune=cortex-a7 -mfpu=vfpv4 -mfloat-abi=hard

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
KERNEL_IMAGE = bzImage

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
#ifeq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug))
#	@echo "Using kernel debug"
#	@grep -v "CONFIG_PRINTK" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
#	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
#	@echo "CONFIG_PRINTK=y" >> $(KERNEL_DIR)/.config
#	@echo "CONFIG_PRINTK_TIME=y" >> $(KERNEL_DIR)/.config
#ndif
	@touch $@

