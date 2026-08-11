#
# generic image
#	
generic-efi-disk-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#
	cp -a $(TARGET_DIR)/boot/bzImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/efi-part $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# rootfs
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 bs=512 count=2097152
	mkfs.ext2 -F -L "NeutrinoNG" $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	fsck.ext2 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 || [ $? -le 3 ]
	# resize
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 1048576k
	#	
	UUID=$(dumpe2fs ${IMAGE_BUILD_DIR}/${FLASHIMAGE_PREFIX}/rootfs.ext2 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
	sed -i "s/UUID_TMP/$UUID/g" "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part/EFI/BOOT/grub.cfg"
	sed "s/UUID_TMP/$UUID/g" $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage-efi.cfg > "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-efi.cfg"
	#
	# check & resize
	fsck.ext2 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 || [ $? -le 3 ]
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 1048576k
	#
	genimage \
	--rootpath $(RELEASE_DIR) \
	--tmppath $(IMAGE_BUILD_DIR)/tmp \
	--inputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)  \
	--outputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) \
	--config $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage-efi.cfg
	#
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part.vfat
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/bzImage
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-efi.cfg
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M').zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)


