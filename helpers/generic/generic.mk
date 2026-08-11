#
# generic image
#
generic-disk-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# do image stuff here
#	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/syslinux.cfg $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
#	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/grub.cfg $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
#	cp -a $(TARGET_DIR)/boot/bzImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	# disk.img
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=1M count=0 seek=2048 conv=fsync
	# write a disklabel
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img mklabel gpt
	# create partitions
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img unit KiB mkpart boot fat32 1024 1048576
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img unit KiB mkpart root ext4 1049600 100%
	parted -s $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img set 1 legacy_boot on
	# write mbr
	dd bs=440 count=1 conv=fsync,notrunc if=$(BASE_DIR)/machine/$(BOXTYPE)/files/gptmbr.bin of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img
	# filesystem
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 bs=512 count=2097152
	mkfs.ext4 -F -L "rootfs" $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 || [ $? -le 3 ]
	# resize
	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 1048576k
	# merge disk.ext4 into disk.img
	dd if=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4 of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=512 seek=2099200 conv=fsync,notrunc
	# boot.fat
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat bs=1M count=1024
	mformat -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -v NEUTRINONG ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(BASE_DIR)/machine/$(BOXTYPE)/files/syslinux.cfg ::
	# install syslinux
	syslinux.mtools -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat
	# copy files
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(TARGET_DIR)/boot/bzImage ::/bzImage
	#
	mmd -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat EFI EFI/BOOT
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(BASE_DIR)/machine/$(BOXTYPE)/files/bootx64.efi ::/EFI/BOOT
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(BASE_DIR)/machine/$(BOXTYPE)/files/ldlinux.e64 ::/EFI/BOOT
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(BASE_DIR)/machine/$(BOXTYPE)/files/bootia32.efi ::/EFI/BOOT
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat -o $(BASE_DIR)/machine/$(BOXTYPE)/files/grub.cfg ::/EFI/BOOT
	#
	sync
	fsck.fat -n $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat
	# merge boot.fat in disk.img
	dd if=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.img bs=512 seek=2048 conv=fsync,notrunc
	#
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/disk.ext4
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.fat
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/syslinux.cfg
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/bzImage
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/grub.cfg
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M').zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
generic-efi-disk-image:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#
	cp -a $(TARGET_DIR)/boot/bzImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp -a $(BASE_DIR)/machine/$(BOXTYPE)/files/efi-part $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
#	cd $(RELEASE_DIR); \
#	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* . > /dev/null 2>&1; \
#	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	# filesystem
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 bs=512 count=2097152
	mkfs.ext2 -F -L "rootfs" $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
#	fsck.ext2 -pvfD $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 || [ $? -le 3 ]
	# resize
#	resize2fs $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 1048576k
#	UUID=$(mkfs.ext2 -F -L "rootfs" "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ext2 -d $(RELEASE_DIR)" | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
	UUID=$(dumpe2fs "$IMAGE_BUILD_DIR/$FLASHIMAGE_PREFIX/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
	sed -i "s/UUID_TMP/$UUID/g" "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/efi-part/EFI/BOOT/grub.cfg"
	sed "s/UUID_TMP/$UUID/g" $(BASE_DIR)/machine/$(BOXTYPE)/files/genimage-efi.cfg > "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/genimage-efi.cfg"
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


