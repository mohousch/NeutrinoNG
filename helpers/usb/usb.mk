#
# usb-image
#
usb-image-$(BOXTYPE):
	cd $(RELEASE_DIR) && \
	tar cvJf $(IMAGE_DIR)/$(BS_NAME)_$(BS_CYCLE)_$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.tar.xz --exclude=vmlinux.gz* . > /dev/null 2>&1
