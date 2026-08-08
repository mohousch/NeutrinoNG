#
# gfuture-disk-image
#
# general
FLASH_IMAGE_NAME = disk
FLASH_BOOT_IMAGE = boot.img
FLASH_IMAGE_LINK = $(FLASH_IMAGE_NAME).ext4
FLASH_IMAGE_ROOTFS_SIZE = 294912

# emmc image
EMMC_IMAGE_SIZE = 3817472
EMMC_IMAGE = $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).img

# partition sizes
BLOCK_SIZE = 512
BLOCK_SECTOR = 2
IMAGE_ROOTFS_ALIGNMENT = 1024
BOOT_PARTITION_SIZE = 3072
KERNEL_PARTITION_SIZE = 8192
ROOTFS_PARTITION_SIZE = 1048576
SWAP_PARTITION_SIZE = 262144

# calc the offsets
KERNEL_PARTITION_OFFSET = $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
ROOTFS_PARTITION_OFFSET = $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

SECOND_KERNEL_PARTITION_OFFSET = $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE))
THIRD_KERNEL_PARTITION_OFFSET = $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
FOURTH_KERNEL_PARTITION_OFFSET = $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

# FIXME:
SWAP_PARTITION_OFFSET = $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
MULTI_ROOTFS_PARTITION_OFFSET = $(shell expr $(SWAP_PARTITION_OFFSET_NL) \+ $(SWAP_PARTITION_SIZE))
STORAGE_PARTITION_OFFSET = $(shell expr $(MULTI_ROOTFS_PARTITION_OFFSET) \+ $(MULTI_ROOTFS_PARTITION_SIZE))

gfuture-disk-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# splash
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra protek4k))
	cp $(SKEL_ROOT)/boot/lcdsplash.bmp $(IMAGE_BUILD_DIR)/
endif
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) seek=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	mkfs.ext4 -F -i 4096 $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) -d $(RELEASE_DIR)/..
	fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) count=0 seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR))
	parted -s $(EMMC_IMAGE) mklabel gpt
	parted -s $(EMMC_IMAGE) unit KiB mkpart boot fat16 $(IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart linuxkernel $(KERNEL_PARTITION_OFFSET) $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart linuxrootfs ext4 $(ROOTFS_PARTITION_OFFSET) $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart linuxkernel2 $(SECOND_KERNEL_PARTITION_OFFSET) $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart linuxkernel3 $(THIRD_KERNEL_PARTITION_OFFSET) $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart linuxkernel4 $(FOURTH_KERNEL_PARTITION_OFFSET) $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swap linux-swap $(SWAP_PARTITION_OFFSET) $(shell expr $(SWAP_PARTITION_OFFSET) \+ $(SWAP_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart userdata ext4 $(MULTI_ROOTFS_PARTITION_OFFSET) $(shell expr $(MULTI_ROOTFS_PARTITION_OFFSET) \+ $(MULTI_ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart storage ext4 $(STORAGE_PARTITION_OFFSET) 100%
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) bs=$(BLOCK_SIZE) count=$(shell expr $(BOOT_PARTITION_SIZE) \* $(BLOCK_SECTOR))
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE)
ifeq ($(BOXTYPE),$(filter $(BOXTYPE),e4hdultra protek4k))
	echo "boot emmcflash0.linuxkernel 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rootsubdir=linuxrootfs1 kernel=/dev/mmcblk0p2 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.linuxkernel 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rootsubdir=linuxrootfs1 kernel=/dev/mmcblk0p2 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.linuxkernel2 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs2 kernel=/dev/mmcblk0p4 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.linuxkernel3 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs3 kernel=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.linuxkernel4 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs4 kernel=/dev/mmcblk0p6 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_4
else
	echo "boot emmcflash0.linuxkernel 'root=/dev/mmcblk0p3 rootsubdir=linuxrootfs1 kernel=/dev/mmcblk0p2 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.linuxkernel 'root=/dev/mmcblk0p3 rootsubdir=linuxrootfs1 kernel=/dev/mmcblk0p2 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.linuxkernel2 'root=/dev/mmcblk0p8 rootsubdir=linuxrootfs2 kernel=/dev/mmcblk0p4 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.linuxkernel3 'root=/dev/mmcblk0p8 rootsubdir=linuxrootfs3 kernel=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.linuxkernel4 'root=/dev/mmcblk0p8 rootsubdir=linuxrootfs4 kernel=/dev/mmcblk0p6 rw rootwait $(BOXTYPE)_4.boxmode=1'" > $(IMAGE_BUILD_DIR)/STARTUP_4
endif
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_4 ::
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51 bre2ze4k h7))
	echo "boot emmcflash0.linuxkernel 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p3 rootsubdir=linuxrootfs1 kernel=/dev/mmcblk0p2 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1_BOXMODE_12
	echo "boot emmcflash0.linuxkernel2 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs2 kernel=/dev/mmcblk0p4 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2_BOXMODE_12
	echo "boot emmcflash0.linuxkernel3 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs3 kernel=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3_BOXMODE_12
	echo "boot emmcflash0.linuxkernel4 'brcm_cma=520M@248M brcm_cma=192M@768M root=/dev/mmcblk0p8 rootsubdir=linuxrootfs4 kernel=/dev/mmcblk0p6 rw rootwait $(BOXTYPE)_4.boxmode=12'" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4_BOXMODE_12
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1_BOXMODE_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2_BOXMODE_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3_BOXMODE_12 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4_BOXMODE_12 ::
endif	
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra protek4k))
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/lcdsplash.bmp ::
endif
	# merge all parts
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* $(BLOCK_SECTOR))
	# FIXME: dtb ???
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51 bre2ze4k h7))
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage.dtb of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(KERNEL_PARTITION_OFFSET) \* $(BLOCK_SECTOR))
else
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(KERNEL_PARTITION_OFFSET) \* $(BLOCK_SECTOR))
endif
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) $(ROOTFS_PARTITION_SIZE)k
	dd if=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(ROOTFS_PARTITION_OFFSET) \* $(BLOCK_SECTOR)) count=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR))
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
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51 bre2ze4k h7))
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
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_multi.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

