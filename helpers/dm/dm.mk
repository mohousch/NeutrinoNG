#
# dm-nfi-image
#
dm-nfi-image-$(BOXTYPE): $(ARCHIVE)/$(2ND_FILE)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	#
	cp -f $(ARCHIVE)/$(2ND_FILE) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	#
	rm -f $(RELEASE_DIR)/boot/*
	cp $(TARGET_DIR)/boot/$(KERNEL_FILE) $(RELEASE_DIR)/boot/
	ln -sf $(KERNEL_FILE) $(RELEASE_DIR)/boot/vmlinux
	echo "/boot/bootlogo-$(BOXTYPE).elf.gz filename=/boot/bootlogo-$(BOXTYPE).jpg" > $(RELEASE_DIR)/boot/autoexec.bat
	echo "/boot/$(KERNEL_FILE) ubi.mtd=root root=ubi0:rootfs rootfstype=ubifs rw console=ttyS0,115200n8" >> $(RELEASE_DIR)/boot/autoexec.bat
	cp $(RELEASE_DIR)/boot/autoexec.bat $(RELEASE_DIR)/boot/autoexec_$(BOXTYPE).bat
	cp $(BASE_DIR)/machine/$(BOXTYPE)/files/bootlogo-$(BOXTYPE).elf.gz $(RELEASE_DIR)/boot/
	cp $(SKEL_ROOT)/boot/bootlogo.jpg $(RELEASE_DIR)/boot/bootlogo-$(BOXTYPE).jpg
	#
	mkfs.jffs2 --root=$(RELEASE_DIR)/boot/ --disable-compressor=lzo --compression-mode=size --eraseblock=$(ERASE_BLOCK_SIZE) --output=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/boot.jffs2
	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(IMAGE_NAME).$(IMAGE_FSTYPES) $(MKUBIFS_ARGS)
	echo [ubifs] > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo mode=ubi >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo image=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(IMAGE_NAME).$(IMAGE_FSTYPES) >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo vol_id=0 >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo vol_type=dynamic >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo vol_name=$(UBI_VOLNAME) >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
#	echo vol_size=$(FLASHSIZE)MiB >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo vol_flags=autoresize >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	ubinize -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(ROOTFS_FILE) $(UBINIZE_ARGS) $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(IMAGE_NAME).$(IMAGE_FSTYPES)
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) && \
	buildimage -a $(BOXTYPE) $(BUILDIMAGE_EXTRA) -e $(ERASE_BLOCK_SIZE) -f $(FLASH_SIZE) -s $(SECTOR_SIZE) -b $(LOADER_SIZE):$(2ND_FILE) -d $(BOOT_SIZE):boot.jffs2 -d $(ROOT_SIZE):$(ROOTFS_FILE) > $(BOXTYPE).nfi
	echo $(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(BOXTYPE).nfo
	#
	cd $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(BOXTYPE).{nfi,nfo} imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# dm-rootfs-image
#
dm-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# kernel
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/$(KERNEL_FILE) $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

