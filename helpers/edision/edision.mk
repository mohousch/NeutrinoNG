#
# edision-disk-image
#
IMAGE_NAME = emmc
IMAGE_LINK = $(IMAGE_NAME).ext4

# emmc image
EMMC_IMAGE = $(IMAGE_BUILD_DIR)/$(IMAGE_NAME).img
EMMC_IMAGE_SIZE = 7634944

# partition offsets/sizes
BLOCK_SIZE	       = 1
BLOCK_SECTOR	       = 1024
IMAGE_ROOTFS_ALIGNMENT = 1024
BOOT_PARTITION_SIZE    = 3072
KERNEL_PARTITION_SIZE  = 8192
ROOTFS_PARTITION_SIZE  = 1767424

KERNEL1_PARTITION_OFFSET = $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) + $(BOOT_PARTITION_SIZE))
ROOTFS1_PARTITION_OFFSET = $(shell expr $(KERNEL1_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))

KERNEL2_PARTITION_OFFSET = $(shell expr $(ROOTFS1_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
ROOTFS2_PARTITION_OFFSET = $(shell expr $(KERNEL2_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))

KERNEL3_PARTITION_OFFSET = $(shell expr $(ROOTFS2_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
ROOTFS3_PARTITION_OFFSET = $(shell expr $(KERNEL3_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))

KERNEL4_PARTITION_OFFSET = $(shell expr $(ROOTFS3_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
ROOTFS4_PARTITION_OFFSET = $(shell expr $(KERNEL4_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))

SWAP_PARTITION_OFFSET = $(shell expr $(ROOTFS4_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))

edision-disk-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(IMAGE_LINK) seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F -m0 $(IMAGE_BUILD_DIR)/$(IMAGE_LINK) -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pfD $(IMAGE_BUILD_DIR)/$(IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) count=0 seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR))
	parted -s $(EMMC_IMAGE) mklabel gpt
	parted -s $(EMMC_IMAGE) unit KiB mkpart boot fat16 $(IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) + $(BOOT_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) set 1 boot on
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel1 $(KERNEL1_PARTITION_OFFSET) $(shell expr $(KERNEL1_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs1 ext4 $(ROOTFS1_PARTITION_OFFSET) $(shell expr $(ROOTFS1_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel2 $(KERNEL2_PARTITION_OFFSET) $(shell expr $(KERNEL2_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs2 ext4 $(ROOTFS2_PARTITION_OFFSET) $(shell expr $(ROOTFS2_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel3 $(KERNEL3_PARTITION_OFFSET) $(shell expr $(KERNEL3_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs3 ext4 $(ROOTFS3_PARTITION_OFFSET) $(shell expr $(ROOTFS3_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel4 $(KERNEL4_PARTITION_OFFSET) $(shell expr $(KERNEL4_PARTITION_OFFSET) + $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs4 ext4 $(ROOTFS4_PARTITION_OFFSET) $(shell expr $(ROOTFS4_PARTITION_OFFSET) + $(ROOTFS_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swap linux-swap $(SWAP_PARTITION_OFFSET) 100%
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/boot.img bs=1024 count=$(BOOT_PARTITION_SIZE)
	mkfs.msdos -n boot -S 512 $(IMAGE_BUILD_DIR)/boot.img
	echo "setenv STARTUP \"boot emmcflash0.kernel1 'root=/dev/mmcblk1p3 rootfstype=ext4 rw rootwait'\"" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "setenv STARTUP \"boot emmcflash0.kernel1 'root=/dev/mmcblk1p3 rootfstype=ext4 rw rootwait'\"" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "setenv STARTUP \"boot emmcflash0.kernel2 'root=/dev/mmcblk1p5 rootfstype=ext4 rw rootwait'\"" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "setenv STARTUP \"boot emmcflash0.kernel3 'root=/dev/mmcblk1p7 rootfstype=ext4 rw rootwait'\"" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "setenv STARTUP \"boot emmcflash0.kernel4 'root=/dev/mmcblk1p9 rootfstype=ext4 rw rootwait'\"" > $(IMAGE_BUILD_DIR)/STARTUP_4
	mcopy -i $(IMAGE_BUILD_DIR)/boot.img -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/boot.img -v $(IMAGE_BUILD_DIR)/STARTUP_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/boot.img -v $(IMAGE_BUILD_DIR)/STARTUP_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/boot.img -v $(IMAGE_BUILD_DIR)/STARTUP_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/boot.img -v $(IMAGE_BUILD_DIR)/STARTUP_4 ::
	parted -s $(EMMC_IMAGE) unit KiB print
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/boot.img of=$(EMMC_IMAGE) seek=1 bs=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* 1024)
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage of=$(EMMC_IMAGE) seek=1 bs=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* 1024 + $(BOOT_PARTITION_SIZE) \* 1024)
	$(HOST_DIR)/bin/resize2fs $(IMAGE_BUILD_DIR)/$(IMAGE_LINK) $(ROOTFS_PARTITION_SIZE)k
	# Truncate on purpose
	dd if=$(IMAGE_BUILD_DIR)/$(IMAGE_LINK) of=$(EMMC_IMAGE) seek=1 bs=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* 1024 + $(BOOT_PARTITION_SIZE) \* 1024 + $(KERNEL_PARTITION_SIZE) \* 1024)
	mv $(EMMC_IMAGE) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip $(BOXTYPE)/$(IMAGE_NAME).img $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# edision-rootfs-image
#
edision-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	# kernel
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/kernel.bin
	# rootfs
	cd $(RELEASE_DIR) && \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar . >/dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	echo "rename this file to 'force' to force an update without confirmation" > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/noforce; \
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/kernel.bin $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

