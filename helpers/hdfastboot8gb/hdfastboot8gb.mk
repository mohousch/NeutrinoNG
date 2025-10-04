#
# hdfastboot8gb-disk-image
#
HDFASTBOOT8GB_FLASH_IMAGE_NAME = disk
HDFASTBOOT8GB_FLASH_BOOT_IMAGE = bootoptions.img
HDFASTBOOT8GB_FLASH_IMAGE_LINK = $(HDFASTBOOT8GB_FLASH_IMAGE_NAME).ext4
HDFASTBOOT8GB_BLOCK_SIZE = 512
HDFASTBOOT8GB_BLOCK_SECTOR = 2
HDFASTBOOT8GB_FLASH_BOOTOPTIONS_PARTITION_SIZE = 4096
HDFASTBOOT8GB_FLASH_IMAGE_ROOTFS_SIZE = 1048576

hdfastboot8gb-disk-image-$(BOXTYPE): $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) $(ARCHIVE)/$(FLASH_PARTITONS_SRC)
	# Create image
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	#
	unzip -o $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) -d $(IMAGE_BUILD_DIR)
#	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	#
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_IMAGE_LINK) seek=$(shell expr $(HDFASTBOOT8GB_FLASH_IMAGE_ROOTFS_SIZE) \* $(HDFASTBOOT8GB_BLOCK_SECTOR)) count=0 bs=$(HDFASTBOOT8GB_BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_IMAGE_LINK) -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) bs=1024 count=$(HDFASTBOOT8GB_FLASH_BOOTOPTIONS_PARTITION_SIZE)
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE)
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootcmd=mmc read 0 0x3F000000 0x70000 0x4000; bootm 0x3F000000; mmc read 0 0x1FFBFC0 0x52000 0xC800; bootargs=androidboot.selinux=enforcing androidboot.serialno=0123456789 console=ttyAMA0,115200" > $(IMAGE_BUILD_DIR)/STARTUP_RED
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_GREEN
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_YELLOW
	echo "bootcmd=mmc read 0 0x1000000 0x53D000 0x8000; bootm 0x1000000 bootargs=console=ttyAMA0,115200 root=/dev/mmcblk0p21 rootfstype=ext4" > $(IMAGE_BUILD_DIR)/STARTUP_BLUE
	mcopy -i $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_RED ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_GREEN ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_YELLOW ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_BLUE ::
	#
	parted -s $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_IMAGE_LINK) unit KiB print
	cp $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/$(HDFASTBOOT8GB_FLASH_BOOT_IMAGE)
	ext2simg -zv $(IMAGE_BUILD_DIR)/$(HDFASTBOOT8GB_FLASH_IMAGE_LINK) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.fastboot.gz
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd60))
	mv $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/bootargs.bin
endif
	mv $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs.bin
	cp $(TARGET_DIR)/boot/$(KERNEL_FILE) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip *
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# hdfastboot8gb-rootfs-image
#	
hdfastboot8gb-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	#
	cp $(TARGET_DIR)/boot/$(KERNEL_FILE) $(IMAGE_BUILD_DIR)/$(BOXTYPE)/
	#
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=$(KERNEL_FILE)* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	#
	echo "$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')" > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	echo "$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_emmc.zip" > $(IMAGE_BUILD_DIR)/unforce_$(BOXTYPE).txt; \
	echo "Rename the unforce_$(BOXTYPE).txt to force_$(BOXTYPE).txt and move it to the root of your usb-stick" > $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	echo "When you enter the recovery menu then it will force to install the image $$(cat $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion).zip in the image-slot1" >> $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE)/unforce_$(BOXTYPE).txt $(BOXTYPE)/force_$(BOXTYPE)_READ.ME $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/$(KERNEL_FILE) $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

