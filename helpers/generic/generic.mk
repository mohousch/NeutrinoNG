#
# generic image
#
generic-flash-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#do image stuff here
	cp -a $(SKEL_ROOT)/boot/grub.cfg $(RELEASE_DIR)/boot/grub/grub.cfg
	# kernel
	cp $(TARGET_DIR)/boot/bzImage $(RELEASE_DIR)/boot/
	###
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 bs=1M count=1024
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 || [ $? -le 3 ]
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=1M count=1024
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img mklabel msdos
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img -a min unit s mkpart primary fat32 1 1
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img -a min unit s mkpart primary ext4 2 2
	# merge disk.ext4 into disk.img
	dd if=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=1M count=1024
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	# install grub / syslinux ?
#	grub-file --is-x86-multiboot $(RELEASE_DIR)/boot/bzImage
#	grub-mkrescue -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/NeutrinoNG.iso -V "NeutrinoNG" $(RELEASE_DIR)
#	grub-install --target=x86_64-efi --directory=/usr/lib/grub/x86_64-efi $(DEVICE_INSTALL)
#	syslinux --install $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

