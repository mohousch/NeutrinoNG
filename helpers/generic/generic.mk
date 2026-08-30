#
# generic image
#
ifeq ($(BOOT), uefi)
	GENIMAGE_CFG = $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-efi.cfg
else
	GENIMAGE_CFG = $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-bios.cfg
endif
	
generic-efi-disk-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#
	cp -a $(TARGET_DIR)/boot/bzImage $(RELEASE_DIR)/boot/
ifeq ($(BOOT), uefi)
	cp -a $(TARGET_DIR)/boot/bzImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/efi-part $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage-efi.cfg $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
else
	mkdir -p $(RELEASE_DIR)/boot/grub
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/grub-bios.cfg $(RELEASE_DIR)/boot/grub/grub.cfg
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage-bios.cfg $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	# boot.img & grub.img
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/boot.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/grub.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
endif
	# rootfs
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 bs=512 count=2097152
	mkfs.ext2 -F -L "${BS_NAME} ${BS_CYCLE}" $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	fsck.ext2 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 || [ $? -le 3 ]
	# resize
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 1048576k
	#
ifeq ($(BOOT), uefi)
	$(HELPERS_DIR)/generic/post-image-efi.sh $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
endif
	#
	genimage \
	--rootpath $(RELEASE_DIR) \
	--tmppath $(IMAGE_BUILD_DIR)/tmp \
	--inputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) \
	--outputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) \
	--config $(GENIMAGE_CFG)
	#
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part.vfat
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/bzImage
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-efi.cfg
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-bios.cfg
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.img
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/grub.img
	#
	cp -a $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img $(IMAGE_DIR)/
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M').zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# run-qemu
#
run-qemu:
	qemu-system-x86_64 \
	-M pc \
	-m 2G \
	-bios /usr/share/OVMF/OVMF_CODE.fd \
	-drive file=$(IMAGE_DIR)/disk.img,if=virtio,format=raw \
	-net nic,model=virtio \
	-net user \
	-vga virtio

