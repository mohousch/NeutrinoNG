#
# generic image
#
generic-flash-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#do image stuff here
	cp -a $(SKEL_ROOT)/boot/syslinux.cfg $(RELEASE_DIR)/boot/syslinux/
	# kernel
	cp $(TARGET_DIR)/boot/bzImage $(RELEASE_DIR)/boot/
	#
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 bs=1M count=1024
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 || [ $? -le 3 ]
	# create sparse image disk
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=1M count=1024
	# merge disk.ext4 into disk.img
	dd if=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=1M count=1024
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4
	# install syslinux
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

