#
# vuplus-rootfs-image
#
vuplus-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
	cp $(TARGET_DIR)/boot/$(INITRD_NAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(INITRD_FILE)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo $(BOOT_UPDATE_TEXT) > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(BOOT_UPDATE_FILE)
	echo $(PART_TEXT) > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(PART_FILE)
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/$(INITRD_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/$(BOOT_UPDATE_FILE) $(FLASHIMAGE_PREFIX)/$(PART_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# vuplus-multi-rootfs image
#
vuplus-multi-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
	cp $(TARGET_DIR)/boot/$(INITRD_NAME) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(INITRD_FILE)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL1_FILE)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL2_FILE)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL3_FILE)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL4_FILE)
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	mv $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs2.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs3.tar.bz2
	cp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs1.tar.bz2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs4.tar.bz2
	#
	echo $(BOOT_UPDATE_TEXT) > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(BOOT_UPDATE_FILE)
	echo $(PART_TEXT) > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(PART_FILE)
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
	echo Dummy for update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar.bz2
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_multi_usb.zip $(FLASHIMAGE_PREFIX)/rootfs*.tar.bz2 $(FLASHIMAGE_PREFIX)/$(INITRD_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL1_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL2_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL3_FILE) $(FLASHIMAGE_PREFIX)/$(KERNEL4_FILE) $(FLASHIMAGE_PREFIX)/$(BOOT_UPDATE_FILE) $(FLASHIMAGE_PREFIX)/$(PART_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

