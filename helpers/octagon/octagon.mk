#
# octagon-disk-image
#
FLASH_IMAGE_NAME = disk
ROOTFS_SIZE = 320k #2*128k + 64k

octagon-disk-image-$(BOXTYPE): $(ARCHIVE)/$(FLASH_PARTITONS_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	#
	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/apploader.bin $(RELEASE_DIR)/usr/share/apploader.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/bootargs.bin $(RELEASE_DIR)/usr/share/bootargs.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/fastboot.bin $(RELEASE_DIR)/usr/share/fastboot.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/apploader.bin $(IMAGE_BUILD_DIR)/apploader.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/bootargs.bin $(IMAGE_BUILD_DIR)/bootargs.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/patitions/fastboot.bin $(IMAGE_BUILD_DIR)/fastboot.bin
	install -d $(IMAGE_BUILD_DIR)/userdata
	install -d $(IMAGE_BUILD_DIR)/userdata/linuxrootfs1
	install -d $(IMAGE_BUILD_DIR)/userdata/linuxrootfs2
	install -d $(IMAGE_BUILD_DIR)/userdata/linuxrootfs3
	install -d $(IMAGE_BUILD_DIR)/userdata/linuxrootfs4
	cp -a $(RELEASE_DIR) $(IMAGE_BUILD_DIR)/userdata
	#
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).rootfs.ext4 seek=$(ROOTFS_SIZE) count=0 bs=1024
	$(HOST_DIR)/bin/mkfs.ext4 -F -i 4096 $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).rootfs.ext4 -d $(IMAGE_BUILD_DIR)/userdata
	fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).rootfs.ext4 || [ $? -le 3 ]
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/uImage $(IMAGE_BUILD_DIR)/patitions/$(KERNEL_FILE)
	cp $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).rootfs.ext4 $(IMAGE_BUILD_DIR)/patitions/rootfs.ext4
	mkupdate -s 00000003-00000001-01010101 -f $(IMAGE_BUILD_DIR)/patitions/emmc_partitions.xml -d $(IMAGE_BUILD_DIR)/usb_update.bin
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip apploader.bin bootargs.bin fastboot.bin usb_update.bin imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# octagon-rootfs-image
#	
octagon-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo "$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

