#
# DirectFB
#
DIRECTFB_VER = 1.7.7
DIRECTFB_SOURCE = DirectFB-$(DIRECTFB_VER).tar.gz

$(ARCHIVE)/$(DIRECTFB_SOURCE):
	$(DOWNLOAD) http://sources.buildroot.net/$(DIRECTFB_SOURCE)

$(D)/directfb: $(D)/bootstrap $(ARCHIVE)/$(DIRECTFB_SOURCE)
	$(START_BUILD)
	$(REMOVE)/DirectFB-$(DIRECTFB_VER)
	$(UNTAR)/$(DIRECTFB_SOURCE)
	$(CHDIR)/DirectFB-$(DIRECTFB_VER); \
		$(call apply_patches, $(PKG_PATCH)); \
		$(BUILDENV) \
		autoreconf -fi $(SILENT_OPT); \
		EGL_CFLAGS=-I$(TARGET_INCLUDE_DIR)/EGL -I$(TARGET_INCLUDE_DIR)/GLES2 \
		EGL_LIBS=-lEGL -lGLESv2 -L$(TARGET_LIB_DIR) \
		$(CONFIGURE) \
			--prefix=/usr \
			--sysconfdir=/etc \
			--enable-egl \
			--with-gfxdrivers=gles2 \
			--enable-freetype=yes \
			--enable-zlib \
			--disable-imlib2 \
			--disable-mesa \
			--disable-sdl \
			--disable-vnc \
			--disable-x11 \
			--without-tools \
			--with-inputdrivers=linuxinput \
			--enable-fusion \
		; \
		$(MAKE) ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libdirect.la
		$(REWRITE_LIBTOOLDEP)/libfusion.la
		$(REWRITE_LIBTOOL)/libfusion.la
		$(REWRITE_LIBTOOL)/libdirectfb.la
		$(REWRITE_LIBTOOLDEP)/libdirectfb.la
		$(REWRITE_LIBTOOL)/lib++dfb.la
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/direct.pc
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fusion.pc
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/directfb-internal.pc
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/directfb.pc
		$(REWRITE_PKGCONF) $(TARGET_DIR)/usr/bin/directfb-config
	$(REMOVE)/DirectFB-$(DIRECTFB_VER)
	$(TOUCH)

