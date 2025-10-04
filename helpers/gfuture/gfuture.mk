#
# gfuture-disk-image
#
# general
GFUTURE_FLASH_IMAGE_NAME = disk
GFUTURE_FLASH_BOOT_IMAGE = boot.img
GFUTURE_FLASH_IMAGE_LINK = $(GFUTURE_FLASH_IMAGE_NAME).ext4
GFUTURE_FLASH_IMAGE_ROOTFS_SIZE = 294912

# emmc image
GFUTURE_EMMC_IMAGE_SIZE = 3817472
GFUTURE_EMMC_IMAGE = $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_NAME).img

# partition sizes
GFUTURE_BLOCK_SIZE = 512
GFUTURE_BLOCK_SECTOR = 2
GFUTURE_IMAGE_ROOTFS_ALIGNMENT = 1024
GFUTURE_BOOT_PARTITION_SIZE = 3072
GFUTURE_KERNEL_PARTITION_SIZE = 8192
GFUTURE_SWAP_PARTITION_SIZE = 262144
GFUTURE_ROOTFS_PARTITION_SIZE = 768000

# calc the offsets
GFUTURE_KERNEL_PARTITION_OFFSET = $(shell expr $(GFUTURE_IMAGE_ROOTFS_ALIGNMENT) \+ $(GFUTURE_BOOT_PARTITION_SIZE))
GFUTURE_ROOTFS_PARTITION_OFFSET = $(shell expr $(GFUTURE_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))

GFUTURE_SECOND_KERNEL_PARTITION_OFFSET = $(shell expr $(GFUTURE_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
GFUTURE_SECOND_ROOTFS_PARTITION_OFFSET = $(shell expr $(GFUTURE_SECOND_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))

GFUTURE_THIRD_KERNEL_PARTITION_OFFSET = $(shell expr $(GFUTURE_SECOND_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
GFUTURE_THIRD_ROOTFS_PARTITION_OFFSET = $(shell expr $(GFUTURE_THIRD_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))

GFUTURE_FOURTH_KERNEL_PARTITION_OFFSET = $(shell expr $(GFUTURE_THIRD_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
GFUTURE_FOURTH_ROOTFS_PARTITION_OFFSET = $(shell expr $(GFUTURE_FOURTH_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))

GFUTURE_SWAP_PARTITION_OFFSET = $(shell expr $(GFUTURE_FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
GFUTURE_STORAGE_PARTITION_OFFSET = $(shell expr $(GFUTURE_SWAP_PARTITION_OFFSET) \+ $(GFUTURE_SWAP_PARTITION_SIZE))

gfuture-disk-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# splash
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra))
	cp $(SKEL_ROOT)/boot/lcdsplash.bmp $(IMAGE_BUILD_DIR)/
endif
	# kernel
	cp $(TARGET_DIR)/boot/zImage* $(IMAGE_BUILD_DIR)/ #???
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_LINK) seek=$(shell expr $(GFUTURE_FLASH_IMAGE_ROOTFS_SIZE) \* $(GFUTURE_BLOCK_SECTOR)) count=0 bs=$(GFUTURE_BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_LINK) -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(GFUTURE_EMMC_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) count=0 seek=$(shell expr $(GFUTURE_EMMC_IMAGE_SIZE) \* $(GFUTURE_BLOCK_SECTOR))
	parted -s $(GFUTURE_EMMC_IMAGE) mklabel gpt
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart boot fat16 $(GFUTURE_IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(GFUTURE_IMAGE_ROOTFS_ALIGNMENT) \+ $(GFUTURE_BOOT_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart kernel1 $(GFUTURE_KERNEL_PARTITION_OFFSET) $(shell expr $(GFUTURE_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart rootfs1 ext4 $(GFUTURE_ROOTFS_PARTITION_OFFSET) $(shell expr $(GFUTURE_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart kernel2 $(GFUTURE_SECOND_KERNEL_PARTITION_OFFSET) $(shell expr $(GFUTURE_SECOND_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart rootfs2 ext4 $(GFUTURE_SECOND_ROOTFS_PARTITION_OFFSET) $(shell expr $(GFUTURE_SECOND_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart kernel3 $(GFUTURE_THIRD_KERNEL_PARTITION_OFFSET) $(shell expr $(GFUTURE_THIRD_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart rootfs3 ext4 $(GFUTURE_THIRD_ROOTFS_PARTITION_OFFSET) $(shell expr $(GFUTURE_THIRD_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart kernel4 $(GFUTURE_FOURTH_KERNEL_PARTITION_OFFSET) $(shell expr $(GFUTURE_FOURTH_KERNEL_PARTITION_OFFSET) \+ $(GFUTURE_KERNEL_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart rootfs4 ext4 $(GFUTURE_FOURTH_ROOTFS_PARTITION_OFFSET) $(shell expr $(GFUTURE_FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(GFUTURE_ROOTFS_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart swap linux-swap $(GFUTURE_SWAP_PARTITION_OFFSET) $(shell expr $(GFUTURE_SWAP_PARTITION_OFFSET) \+ $(GFUTURE_SWAP_PARTITION_SIZE))
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB mkpart storage ext4 $(GFUTURE_STORAGE_PARTITION_OFFSET) 100%
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) count=$(shell expr $(GFUTURE_BOOT_PARTITION_SIZE) \* $(GFUTURE_BLOCK_SECTOR))
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE)
	#
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra protek4k))
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait 8100s_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait 8100s_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.kernel2 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p5 rw rootwait 8100s_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.kernel3 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p7 rw rootwait 8100s_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.kernel4 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p9 rw rootwait 8100s_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_4
else
	echo "boot emmcflash0.kernel1 'root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.kernel1 'root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.kernel2 'root=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.kernel3 'root=/dev/mmcblk0p7 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.kernel4 'root=/dev/mmcblk0p9 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_4
endif
	#
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_4 ::
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra))
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/lcdsplash.bmp ::
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51 bre2ze4k h7))
	echo "boot emmcflash0.kernel1 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_1_12
	echo "boot emmcflash0.kernel2 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_2_12
	echo "boot emmcflash0.kernel3 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p7 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_3_12
	echo "boot emmcflash0.kernel4 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p9 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_4_12
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_1_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_2_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_3_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_4_12 ::
endif
	#
	parted -s $(GFUTURE_EMMC_IMAGE) unit KiB print
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_BOOT_IMAGE) of=$(GFUTURE_EMMC_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) seek=$(shell expr $(GFUTURE_IMAGE_ROOTFS_ALIGNMENT) \* $(GFUTURE_BLOCK_SECTOR))
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra protek4k))
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage of=$(GFUTURE_EMMC_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) seek=$(shell expr $(GFUTURE_KERNEL_PARTITION_OFFSET) \* $(GFUTURE_BLOCK_SECTOR))
else
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage.dtb of=$(GFUTURE_EMMC_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) seek=$(shell expr $(GFUTURE_KERNEL_PARTITION_OFFSET) \* $(GFUTURE_BLOCK_SECTOR))
endif
	$(HOST_DIR)/bin/resize2fs $(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_LINK) $(GFUTURE_ROOTFS_PARTITION_SIZE)k
	# Truncate on purpose
	dd if=$(IMAGE_BUILD_DIR)/$(GFUTURE_FLASH_IMAGE_LINK) of=$(GFUTURE_EMMC_IMAGE) bs=$(GFUTURE_BLOCK_SIZE) seek=$(shell expr $(GFUTURE_ROOTFS_PARTITION_OFFSET) \* $(GFUTURE_BLOCK_SECTOR)) count=$(shell expr $(GFUTURE_FLASH_IMAGE_ROOTFS_SIZE) \* $(GFUTURE_BLOCK_SECTOR))
	mv $(IMAGE_BUILD_DIR)/disk.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip $(FLASHIMAGE_PREFIX)/disk.img $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# gfuture-rootfs-image
#
gfuture-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
ifneq ($(KERNEL_DTB_VER),)
	cp $(TARGET_DIR)/boot/zImage.dtb $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
else
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
endif
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

