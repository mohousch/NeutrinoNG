#
# DirectFB
#
DIRECTFB_VER = 1.7.7
DIRECTFB_SRC = DirectFB-$(DIRECTFB_VER).tar.gz
DIRECTFB_URL = http://sources.buildroot.net

DIRECTFB_PATCH =

$(ARCHIVE)/$(DIRECTFB_SRC):
	$(DOWNLOAD) $(DIRECTFB_URL)/$(DIRECTFB_SRC)

$(D)/directfb: $(D)/bootstrap $(ARCHIVE)/$(DIRECTFB_SRC)
	$(START_BUILD)
	$(REMOVE)/DirectFB-$(DIRECTFB_VER)
	$(UNTAR)/$(DIRECTFB_SRC)
	$(CHDIR)/DirectFB-$(DIRECTFB_VER); \
		$(call apply_patches, $(DIRECTFB_PATCH)); \
		$(BUILDENV) \
		autoreconf -fi; \
		EGL_CFLAGS=-I$(TARGET_INCLUDE_DIR)/EGL -I$(TARGET_INCLUDE_DIR)/GLES2 \
		EGL_LIBS=-lEGL -lGLESv2 -L$(TARGET_LIB_DIR) \
		$(CONFIGURE) \
			--prefix=/usr \
			--sysconfdir=/etc \
			--enable-egl \
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
		$(MAKE); \
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
	
$(D)/glew: $(D)/bootstrap $(ARCHIVE)/$(GLEW_SRC)
	$(START_BUILD)
	$(REMOVE)/glew-$(GLEW_VER)
	$(UNTAR)/$(GLEW_SRC)
	$(CHDIR)/glew-$(GLEW_VER); \
		$(call apply_patches, $(GLEW_PATCH)); \
		$(BUILDENV) \
		$(MAKE); \
		$(MAKE) install GLEW_DEST="/usr" LIBDIR="/usr/lib" DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libGLEW.a
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glew.pc
	$(REMOVE)/glew-$(GLEW_VER)
	$(TOUCH)
	
#
# libpciaccess
#
LIBPCIACCESS_VER = 0.19
LIBPCIACCESS_SRC = libpciaccess-$(LIBPCIACCESS_VER).tar.xz
LIBPCIACCESS_URL = http://xorg.freedesktop.org/releases/individual/lib

LIBPCIACCESS_PATCH = 

$(ARCHIVE)/$(LIBPCIACCESS_SRC):
	$(DOWNLOAD) $(LIBPCIACCESS_URL)/$(LIBPCIACCESS_SRC)

$(D)/libpciaccess: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(LIBPCIACCESS_SRC)
	$(START_BUILD)
	$(REMOVE)/libpciaccess-$(LIBPCIACCESS_VER)
	$(UNTAR)/$(LIBPCIACCESS_SRC)
	$(CHDIR)/libpciaccess-$(LIBPCIACCESS_VER); \
		$(call apply_patches, $(LIBPCIACCESS_PATCH)); \
		meson setup build \
			--prefix=$(TARGET_DIR)/usr \
			--libdir=$(TARGET_DIR)/usr/lib \
			--buildtype=release \
			-Dzlib=enabled \
		; \
		cd build; ninja; \
		ninja install;
	$(REMOVE)/libpciaccess-$(LIBPCIACCESS_VER)
	$(TOUCH)
	
#
# libdrm
#
LIBDRM_VER = 2.4.134
LIBDRM_SRC = libdrm-$(LIBDRM_VER).tar.xz
LIBDRM_URL = https://dri.freedesktop.org/libdrm

LIBDRM_PATCH =

$(ARCHIVE)/$(LIBDRM_SRC):
	$(DOWNLOAD) $(LIBDRM_URL)/$(LIBDRM_SRC)
	
$(D)/libdrm: $(D)/bootstrap $(D)/libpciaccess $(ARCHIVE)/$(LIBDRM_SRC)
	$(START_BUILD)
	$(REMOVE)/libdrm-$(LIBDRM_VER)
	$(UNTAR)/$(LIBDRM_SRC)
	$(CHDIR)/libdrm-$(LIBDRM_VER); \
		$(call apply_patches, $(LIBDRM_PATCH)); \
		meson setup build \
			--prefix=$(TARGET_DIR)/usr \
			--libdir=$(TARGET_DIR)/usr/lib \
			--buildtype=release \
			-Dcairo-tests=disabled \
			-Dman-pages=disabled \
			-Damdgpu=enabled \
			-Dnouveau=enabled \
			-Dintel=enabled \
			-Dtests=false \
			-Dudev=false \
			-Dvalgrind=disabled \
		; \
		cd build; ninja; \
		ninja install;
	$(REMOVE)/libdrm-$(LIBDRM_VER)
	$(TOUCH)
	
#
# libX11
#
LIBX11_VER = 1.8.13
LIBX11_SRC = libX11-$(LIBX11_VER).tar.gz
LIBX11_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBX11_PATCH = 0001-disable-nls-tests.patch

$(ARCHIVE)/$(LIBX11_SRC):
	$(DOWNLOAD) $(LIBX11_URL)/$(LIBX11_SRC)
	
$(D)/libX11: $(D)/bootstrap $(D)/xproto $(ARCHIVE)/$(LIBX11_SRC)
	$(START_BUILD)
	$(REMOVE)/libX11-$(LIBX11_VER)
	$(UNTAR)/$(LIBX11_SRC)
	$(CHDIR)/libX11-$(LIBX11_VER); \
		$(call apply_patches, $(LIBX11_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-loadable-i18n \
			--disable-loadable-xcursor \
			--enable-xthreads \
			--disable-xcms \
			--enable-xlocale \
			--disable-xlocaledir \
			--enable-xkb \
			--with-keysymdefdir=$(TARGET_DIR)/usr/include/X11 \
			--disable-xf86bigfont \
			--enable-malloc0returnsnull \
			--disable-specs \
			--without-xmlto \
			--without-fop \
			--enable-composecache \
			--disable-lint-library \
			--disable-ipv6 \
			--without-launchd \
			--without-lint \
		; \
		$(MAKE);
	
#	$(TOUCH)

#
# xproto
#
XPROTO_VER = 2025.1
XPROTO_SRC = xorgproto-$(XPROTO_VER).tar.xz
XPROTO_URL = https://xorg.freedesktop.org/archive/individual/proto

XPROTO_PATCH =

$(ARCHIVE)/$(XPROTO_SRC):
	$(DOWNLOAD) $(XPROTO_URL)/$(XPROTO_SRC)
	
$(D)/xproto: $(D)/bootstrap $(ARCHIVE)/$(XPROTO_SRC)
	$(START_BUILD)
	$(REMOVE)/xorgproto-$(XPROTO_VER)
	$(UNTAR)/$(XPROTO_SRC)
	$(CHDIR)/xorgproto-$(XPROTO_VER); \
		$(call apply_patches, $(XPROTO_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/xorgproto-$(XPROTO_VER)
	$(TOUCH)
	
#
# glvnd
#
GLVND_VER = 1.7.0
GLVND_SRC = v$(GLVND_VER).tar.gz
GLVND_URL = https://github.com/NVIDIA/libglvnd/archive

GLVND_PATCH = 

$(ARCHIVE)/$(GLVND_SRC):
	$(DOWNLOAD) $(GLVND_URL)/$(GLVND_SRC) 
	
$(D)/glvnd: $(D)/bootstrap $(ARCHIVE)/$(GLVND_SRC)
	$(START_BUILD)
	$(REMOVE)/libglvnd-$(GLVND_VER)
	$(UNTAR)/$(GLVND_SRC)
	$(CHDIR)/libglvnd-$(GLVND_VER); \
		$(call apply_patches, $(GLVND_PATCH)); \
		meson setup build \
			--prefix=$(TARGET_DIR)/usr \
			--libdir=$(TARGET_DIR)/usr/lib \
			--buildtype=release \
			-Dx11=disabled \
			-Dglx=disabled \
			-Degl=false \
			-Dgles1=false -Dgles2=false \
		; \
		cd build; ninja; \
		ninja install;
	$(REMOVE)/libglvnd-$(GLVND_VER)
	$(TOUCH)
	
#
# glu
#
GLU_VER = 9.0.3
GLU_SRC = glu-$(GLU_VER).tar.xz
GLU_URL = https://mesa.freedesktop.org/archive/glu

GLU_PATCH =

$(ARCHIVE)/$(GLU_SRC):
	$(DOWNLOAD) $(GLU_URL)/$(GLU_SRC)
	
$(D)/glu: $(D)/bootstrap $(ARCHIVE)/$(GLU_SRC) $(D)/glvnd
	$(START_BUILD)
	$(REMOVE)/glu-$(GLU_VER)
	$(UNTAR)/$(GLU_SRC)
	$(CHDIR)/glu-$(GLU_VER); \
		$(call apply_patches, $(GLU_PATCH)); \
		meson setup build \
			--prefix=$(TARGET_DIR)/usr \
			--libdir=$(TARGET_DIR)/usr/lib \
			--buildtype=release \
			-Dgl_provider=glvnd \
		; \
		cd build; ninja; \
		ninja install;
	$(REMOVE)/glu-$(GLEW_VER)
	$(TOUCH)
	
#
# freeglut
#
FREEGLUT_VER = 3.8.0
FREEGLUT_SRC = freeglut-$(FREEGLUT_VER).tar.gz
FREEGLUT_URL = https://github.com/FreeGLUTProject/freeglut/releases/download/v$(FREEGLUT_VER)

FREEGLUT_PATCH =

$(ARCHIVE)/$(FREEGLUT_SRC):
	$(DOWNLOAD) $(FREEGLUT_URL)/$(FREEGLUT_SRC)
	
$(D)/freeglut: $(D)/bootstrap $(ARCHIVE)/$(FREEGLUT_SRC) $(D)/glu
	$(START_BUILD)
	$(REMOVE)/freeglut-$(FREEGLUT_VER)
	$(UNTAR)/$(FREEGLUT_SRC)
	$(CHDIR)/freeglut-$(FREEGLUT_VER); \
		$(call apply_patches, $(FREEGLUT_PATCH)); \
		rm CMakeFiles/* -rf CMakeCache.txt cmake_install.cmake; \
		cmake . -DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_C_COMPILER=$(TARGET)-gcc \
			-DCMAKE_CXX_COMPILER=$(TARGET)-g++ \
			-DFREEGLUT_BUILD_DEMOS=OFF \
#			-DFREEGLUT_WAYLAND=OFF \
#			-DFREEGLUT_GLES=OFF \
#			-DFREEGLUT_X11=OFF \
#			-DFREEGLUT_BUILD_SHARED_LIBS=ON \
#			-DFREEGLUT_BUILD_STATIC_LIBS=ON \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/freeglut.pc
	$(REMOVE)/freeglut-$(FREEGLUT_VER)
#	$(TOUCH)
	
#
# mesa
#
MESA_VER = 24.0.0
MESA_SRC = mesa-$(MESA_VER).tar.xz
MESA_URL = https://mesa.freedesktop.org/archive

MESA_PATCH =

$(ARCHIVE)/$(MESA_SRC):
	$(DOWNLOAD) $(MESA_URL)/$(MESA_SRC)
	
$(D)/mesa: $(D)/bootstrap $(ARCHIVE)/$(MESA_SRC) $(D)/libxml2 $(D)/libarchive $(D)/lua $(D)/libdrm $(D)/zlib $(D)/libpciaccess
	$(START_BUILD)
	$(REMOVE)/mesa-$(MESA_VER)
	$(UNTAR)/$(MESA_SRC)
	$(CHDIR)/mesa-$(MESA_VER); \
		$(call apply_patches, $(MESA_PATCH)); \
		meson setup build \
			--prefix=/usr \
			--buildtype=release \
			-Dgallium-drivers=auto \
			-Dgallium-extra-hud=false \
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
			-Dglvnd=true \
			-Dllvm=disabled \
		; \
		cd build; ninja; \
		ninja install;
	$(REMOVE)/mesa-$(MESA_VER)
#	$(TOUCH)

#
# sdl2
#
SDL2_VER = 2.32.10
SDL2_SRC = SDL2-$(SDL2_VER).tar.gz
SDL2_URL = http://www.libsdl.org/release

SDL2_PATCH =

$(ARCHIVE)/$(SDL2_SRC):
	$(DOWNLOAD) $(SDL2_URL)/$(SDL2_SRC)
	
$(D)/sdl2: $(D)/bootstrap $(ARCHIVE)/$(SDL2_SRC)
	$(START_BUILD)
	$(REMOVE)/SDL2-$(SDL2_VER)
	$(UNTAR)/$(SDL2_SRC)
	$(CHDIR)/SDL2-$(SDL2_VER); \
		$(call apply_patches, $(SDL2_PATCH)); \
		$(BUILDENV); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-arts \
			--disable-esd \
			--disable-dbus \
			--disable-pulseaudio \
			--disable-video-vivante \
			--disable-video-cocoa \
			--disable-video-metal \
			--disable-video-dummy \
			--disable-video-offscreen \
			--disable-video-vulkan \
			--disable-video-directfb \
			--disable-video-rpi \
			--disable-ime \
			--disable-ibus \
			--disable-fcitx \
			--disable-joystick-mfi \
			--disable-directx \
			--disable-xinput \
			--disable-wasapi \
			--disable-hidapi-joystick \
			--disable-hidapi-libusb \
			--disable-joystick-virtual \
			--disable-render-d3d \
		; \
		$(MAKE) CFLAGS="$(TARGET_CFLAGS)"; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/SDL2-$(SDL2_VER)
#	$(TOUCH)

