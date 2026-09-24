#
# h3 disk image
#
h3-disk-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#
	cp -a $(TARGET_DIR)/boot/zImage $(RELEASE_DIR)/boot/
	cp -a $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage.cfg $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	mkdir -p $(RELEASE_DIR)/boot/extlinux
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/u-boot-sunxi-with-spl.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/extlinux.conf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	$(HELPERS_DIR)/allwinner/post-build.sh $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp -a $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/extlinux.conf $(RELEASE_DIR)/boot/extlinux/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/sun8i-h3-orangepi-pc.dtb $(RELEASE_DIR)/boot/
	# rootfs
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext4 bs=512 count=2097152
	mkfs.ext4 -F -L "${BS_NAME} ${BS_CYCLE}" $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext4 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext4 || [ $? -le 3 ]
	# resize
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext4 1048576k
	#
	genimage \
	--rootpath $(RELEASE_DIR) \
	--tmppath $(IMAGE_BUILD_DIR)/tmp \
	--inputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) \
	--outputpath $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) \
	--config $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage.cfg
	#
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext4
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/zImage
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage.cfg
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/extlinux.conf
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/u-boot-sunxi-with-spl.bin
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
	qemu-system-arm \
	-m 2G \
	-drive file=$(IMAGE_DIR)/disk.img,if=virtio,format=raw \
	-net nic,model=virtio \
	-net user \
	-vga virtio

