#
# image
#
image: release
	$(START_BUILD)
	$(MAKE) image-$(BOXTYPE)
	$(END_BUILD)
	
#
# image-clean
#
image-clean:
	cd $(IMAGE_DIR) && rm -rf *

