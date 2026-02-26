#
# gbue4k-rootfs-image
#
gigablue-rootfs-image-$(BOXTYPE): $(ARCHIVE)/$(INITRD_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	# splash
	cp $(SKEL_ROOT)/boot/splash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/splash.bin
	cp $(SKEL_ROOT)/boot/warning.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(SKEL_ROOT)/boot/lcdsplash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(SKEL_ROOT)/boot/lcdwarning220.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/lcdwarning.bin
	cp $(SKEL_ROOT)/boot/lcdwaitkey220.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/lcdwaitkey.bin
	# kernel
	unzip -o $(ARCHIVE)/$(INITRD_SRC) -d $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(KERNEL_FILE)
	# rootfs
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=$(KERNEL_FILE) . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	#
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	#
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

