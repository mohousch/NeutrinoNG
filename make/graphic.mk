#
# DirectFB
#
DIRECTFB_VER = 1.7.7
DIRECTFB_SRC = DirectFB-$(DIRECTFB_VER).tar.gz

DIRECTFB_PATCH =

$(ARCHIVE)/$(DIRECTFB_SRC):
	$(DOWNLOAD) http://sources.buildroot.net/$(DIRECTFB_SRC)

$(D)/directfb: $(D)/bootstrap $(ARCHIVE)/$(DIRECTFB_SRC)
	$(START_BUILD)
	$(REMOVE)/DirectFB-$(DIRECTFB_VER)
	$(UNTAR)/$(DIRECTFB_SRC)
	$(CHDIR)/DirectFB-$(DIRECTFB_VER); \
		$(call apply_patches, $(DIRECTFB_PATCH)); \
		$(BUILDENV) \
		autoreconf -fi; \
#		EGL_CFLAGS=-I$(TARGET_INCLUDE_DIR)/EGL -I$(TARGET_INCLUDE_DIR)/GLES2 \
#		EGL_LIBS=-lEGL -lGLESv2 -L$(TARGET_LIB_DIR) \
		$(CONFIGURE) \
			--prefix=/usr \
			--sysconfdir=/etc \
			--enable-gl \
			--with-gfxdrivers=gl \
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

#
# glew
#
GLEW_VER = 2.3.1
GLEW_SRC = glew-$(GLEW_VER).tgz
GLEW_URL = https://downloads.sourceforge.net/project/glew/glew/$(GLEW_VER)

GLEW_PATCH =

$(ARCHIVE)/$(GLEW_SRC):
	$(DOWNLOAD) $(GLEW_URL)/$(GLEW_SRC)
	
$(D)/glew: $(ARCHIVE)/$(GLEW_SRC)
	$(START_BUILD)
	$(REMOVE)/glew-$(GLEW_VER)
	$(UNTAR)/$(GLEW_SRC)
	$(CHDIR)/glew-$(GLEW_VER); \
		$(call apply_patches, $(GLEW_PATCH)); \
		$(BUILDENV) \
		$(MAKE) ; \
		$(MAKE) install GLEW_DEST="/usr" LIBDIR="/usr/lib" DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libGLEW.a
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glew.pc
	$(REMOVE)/glew-$(GLEW_VER)
	$(TOUCH)
	
#
# mesa
#
MESA_VER = 26.2.0
MESA_SRC = mesa-$(MESA_VER).tar.xz
MESA_URL = https://mesa.freedesktop.org/archive

MESA_PATCH =

$(ARCHIVE)/$(MESA_SRC):
	$(DOWNLOAD) $(MESA_URL)/$(MESA_SRC)
	
$(D)/mesa: $(ARCHIVE)/$(MESA_SRC) $(D)/libxml2 $(D)/libarchive $(D)/lua
	$(START_BUILD)
	$(REMOVE)/mesa-$(MESA_VER)
	$(UNTAR)/$(MESA_SRC)
	$(CHDIR)/mesa-$(MESA_VER); \
		$(call apply_patches, $(MESA_PATCH)); \
			meson --reconfigure ${BUILD} \
			-Dprefix=/usr \
			-Dgallium-extra-hud=false \
			-Dgallium-rusticl=false \
			-Dshader-cache=enabled \
			-Dopengl=true \
			-Dgbm=enabled \
			-Degl=enabled \
			-Dvalgrind=disabled \
			-Dlibunwind=disabled \
			-Dlmsensors=disabled \
			-Dbuild-tests=false \
			-Dmicrosoft-clc=disabled \
			-Dplatforms="" \
			-Dglx=disabled \
			-Dglvnd=disabled
		$(MAKE);
#		$(MAKE) install GLEW_DEST="/usr" LIBDIR="/usr/lib" DESTDIR=$(TARGET_DIR)
#		$(REWRITE_LIBTOOL)/libGLEW.a
#		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glew.pc
#	$(REMOVE)/glew-$(GLEW_VER)
#	$(TOUCH)
	
#
# glu
#
GLU_VER = 9.0.3
GLU_SRC = glu-$(GLU_VER).tar.xz
GLU_URL = https://mesa.freedesktop.org/archive/glu

GLU_PATCH =

$(ARCHIVE)/$(GLU_SRC):
	$(DOWNLOAD) $(GLU_URL)/$(GLU_SRC)
	
$(D)/glu: $(ARCHIVE)/$(GLU_SRC) $(D)/mesa
	$(START_BUILD)
	$(REMOVE)/glu-$(GLU_VER)
	$(UNTAR)/$(GLU_SRC)
	$(CHDIR)/glu-$(GLU_VER); \
		$(call apply_patches, $(GLU_PATCH)); \
		meson meson --reconfigure ${BUILD} \
			-Dprefix=/usr \
			-Dgl_provider=glvnd; \
		$(MAKE);
#		$(MAKE) install GLEW_DEST="/usr" LIBDIR="/usr/lib" DESTDIR=$(TARGET_DIR)
#		$(REWRITE_LIBTOOL)/libGLEW.a
#		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glew.pc
#	$(REMOVE)/glew-$(GLEW_VER)
#	$(TOUCH)

