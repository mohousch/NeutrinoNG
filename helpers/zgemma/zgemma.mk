#
# zgemma ubi image
#
zgemma-ubi-image-$(BOXTYPE): $(ARCHIVE)/$(BOOTARGS_SRC) $(ARCHIVE)/$(FASTBOOT_SRC) $(ARCHIVE)/$(PARAM_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)
	$(MAKE) install-bootargs
	$(MAKE) install-fastboot
	$(MAKE) install-param
	echo "rename this file to 'force' to force an update without confirmation" > $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/noforce;
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)
	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubifs.img -m 2048 -e 126976 -c 4096
	echo '[ubifs]' > $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'mode=ubi' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'image=$(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubifs.img' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'vol_id=0' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'vol_type=dynamic' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'vol_name=rootfs' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo 'vol_flags=autoresize' >> $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	ubinize -o $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/rootfs.ubi -m 2048 -p 128KiB $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	rm -f $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubifs.img
	rm -f $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/ubinize.cfg
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/imageversion
	install -m 0644 $(BASE_DIR)/machine/$(BOXTYPE)/files/logo.img $(IMAGE_BUILD_DIR)/$(FLASH_PREFIX)/logo.img
	cd $(IMAGE_BUILD_DIR)/ && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASH_PREFIX)* fastboot.bin bootargs.bin
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# zgemma multi-rootfs image
#
zgemma-multi-rootfs-image-$(BOXTYPE):
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/uImage
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	echo $(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	echo "$(BOXTYPE)_$(DATE)_emmc.zip" > $(IMAGE_BUILD_DIR)/unforce_$(BOXTYPE).txt; \
	echo "Rename the unforce_$(BOXTYPE).txt to force_$(BOXTYPE).txt and move it to the root of your usb-stick" > $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	echo "When you enter the recovery menu then it will force to install the image $$(cat $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion).zip in the image-slot1" >> $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip unforce_$(BOXTYPE).txt force_$(BOXTYPE)_READ.ME $(BOXTYPE)/rootfs.tar.bz2 $(BOXTYPE)/uImage $(BOXTYPE)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)



