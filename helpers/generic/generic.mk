#
# generic image
#
generic-flash-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#do image stuff here
	cp -a $(SKEL_ROOT)/boot/grub.cfg $(RELEASE_DIR)/boot/grub/grub.cfg
	# kernel
	#cp $(TARGET_DIR)/boot/bzImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp $(TARGET_DIR)/boot/bzImage $(RELEASE_DIR)/boot/
	###
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 bs=100M count=32
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 || [ $? -le 3 ]
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=100M count=32
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img mklabel gpt
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img unit KiB mkpart boot fat16
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img unit KiB mkpart kernel
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img unit KiB mkpart rootfs ext4
	###
	# rootfs
#	cd $(RELEASE_DIR); \
#	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=bzImage . > /dev/null 2>&1; \
#	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
#	dd if=$(RELEASE_DIR)/boot/bzImage of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=512 count=2880
#	grub-file --is-x86-multiboot $(RELEASE_DIR)/boot/bzImage
	grub-mkrescue -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/NeutrinoNG.iso -V "NeutrinoNG" $(RELEASE_DIR)
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

