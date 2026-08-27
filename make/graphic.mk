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
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdrm.pc
	$(REMOVE)/libdrm-$(LIBDRM_VER)
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
			-DFREEGLUT_WAYLAND=OFF \
			-DFREEGLUT_GLES=OFF \
			-DFREEGLUT_X11=ON \
			-DFREEGLUT_BUILD_SHARED_LIBS=ON \
			-DFREEGLUT_BUILD_STATIC_LIBS=ON \
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
# libX11
#
LIBX11_VER = 1.8.13
LIBX11_SRC = libX11-$(LIBX11_VER).tar.gz
LIBX11_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBX11_PATCH = 0001-disable-nls-tests.patch

$(ARCHIVE)/$(LIBX11_SRC):
	$(DOWNLOAD) $(LIBX11_URL)/$(LIBX11_SRC)
	
$(D)/libX11: $(D)/bootstrap $(D)/xorgproto $(D)/util-macros $(D)/xtrans $(D)/libXau $(D)/libxcb $(ARCHIVE)/$(LIBX11_SRC)
	$(START_BUILD)
	$(REMOVE)/libX11-$(LIBX11_VER)
	$(UNTAR)/$(LIBX11_SRC)
	$(CHDIR)/libX11-$(LIBX11_VER); \
		$(call apply_patches, $(LIBX11_PATCH)); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--disable-loadable-i18n \
			--disable-loadable-xcursor \
			--enable-xthreads \
			--disable-xcms \
			--disable-xlocale \
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
			--without-perl \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libX11.a
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libX11.pc
	$(REMOVE)/libX11-$(LIBX11__VER)
	$(TOUCH)

#
# xorgproto
#
XPROTO_VER = 2025.1
XPROTO_SRC = xorgproto-$(XPROTO_VER).tar.xz
XPROTO_URL = https://xorg.freedesktop.org/archive/individual/proto

XPROTO_PATCH =

$(ARCHIVE)/$(XPROTO_SRC):
	$(DOWNLOAD) $(XPROTO_URL)/$(XPROTO_SRC)
	
$(D)/xorgproto: $(D)/bootstrap $(D)/util-macros $(ARCHIVE)/$(XPROTO_SRC)
	$(START_BUILD)
	$(REMOVE)/xorgproto-$(XPROTO_VER)
	$(UNTAR)/$(XPROTO_SRC)
	$(CHDIR)/xorgproto-$(XPROTO_VER); \
		$(call apply_patches, $(XPROTO_PATCH)); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(TARGET_DIR)/usr \
			--datadir=$(TARGET_DIR)/usr/lib \
			--enable-legacy \
		; \
		$(MAKE); \
		$(MAKE) install
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xproto.pc
	$(REMOVE)/xorgproto-$(XPROTO_VER)
	$(TOUCH)

#
# libXfont2
#
XFONT2_VER = 2.0.9
XFONT2_SRC = libXfont2-$(XFONT2_VER).tar.xz
XFONT2_URL = https://xorg.freedesktop.org/archive/individual/lib

XFONT2_PATCH =

$(ARCHIVE)/$(XFONT2_SRC):
	$(DOWNLOAD) $(XFONT2_URL)/$(XFONT2_SRC)
	
$(D)/libXfont2: $(D)/bootstrap $(D)/util-macros $(ARCHIVE)/$(XFONT2_SRC)
	$(START_BUILD)
	$(REMOVE)/libXfont2-$(XFONT2_VER)
	$(UNTAR)/$(XFONT2_SRC)
	$(CHDIR)/libXfont2-$(XFONT2_VER); \
		$(call apply_patches, $(XFONT2_PATCH)); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--disable-dependency-tracking \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
#	$(REMOVE)/libXfont2-$(XFONT2_VER)
#	$(TOUCH)

#
# util-macros
#
XMACROS_VER = 1.20.2
XMACROS_SRC = util-macros-$(XMACROS_VER).tar.xz
XMACROS_URL = https://xorg.freedesktop.org/archive/individual/util

$(ARCHIVE)/$(XMACROS_SRC):
	$(DOWNLOAD) $(XMACROS_URL)/$(XMACROS_SRC)
	
$(D)/util-macros: $(D)/bootstrap $(ARCHIVE)/$(XMACROS_SRC)
	$(REMOVE)/util-macros-$(XMACROS_VER)
	$(UNTAR)/$(XMACROS_SRC)
	$(CHDIR)/util-macros-$(XMACROS_VER); \
		$(call apply_patches, $(XMACROS_PATCH)); \
		autoreconf -i; \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(TARGET_DIR)/usr \
			--datadir=/usr/lib \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xorg-macros.pc
	$(REMOVE)/util-macros-$(XMACROS_VER)
	$(TOUCH)
	
#
# libXext
#
LIBXEXT_VER = 1.3.7
LIBXEXT_SRC = libXext-$(LIBXEXT_VER).tar.xz
LIBXEXT_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBXEXT_PATCH = 

$(ARCHIVE)/$(LIBXEXT_SRC):
	$(DOWNLOAD) $(LIBXEXT_URL)/$(LIBXEXT_SRC)

$(D)/libXext: $(D)/bootstrap $(ARCHIVE)/$(LIBXEXT_SRC)
	$(START_BUILD)
	$(REMOVE)/libXext-$(LIBXEXT_VER)
	$(UNTAR)/$(LIBXEXT_SRC)
	$(CHDIR)/libXext-$(LIBXEXT_VER); \
		$(call apply_patches, $(LIBXEXT_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-malloc0returnsnull \
			--without-xmlto \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/libXext-$(LIBXEXT_VER)
#	$(TOUCH)
	
#
# libXinerama
#
LIBXINERAMA_VER = 1.1.6
LIBXINERAMA_SRC = libXinerama-$(LIBXINERAMA_VER).tar.xz
LIBXINERAMA_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBXINERAMA_PATCH = 

$(ARCHIVE)/$(LIBXINERAMA_SRC):
	$(DOWNLOAD) $(LIBXINERAMA_URL)/$(LIBXINERAMA_SRC)

$(D)/libXinerama: $(D)/bootstrap $(ARCHIVE)/$(LIBXINERAMA_SRC)
	$(START_BUILD)
	$(REMOVE)/libXinerama-$(LIBXINERAMA_VER)
	$(UNTAR)/$(LIBXINERAMA_SRC)
	$(CHDIR)/libXinerama-$(LIBXINERAMA_VER); \
		$(call apply_patches, $(LIBXINERAMA_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
#	$(REMOVE)/libXinerama-$(LIBXINERAMA_VER)
#	$(TOUCH)

#
# xtrans
#
XTRANS_VER = 1.6.0
XTRANS_SRC = xtrans-$(XTRANS_VER).tar.xz
XTRANS_URL = https://xorg.freedesktop.org/archive/individual/lib

XTRANS_PATCH = 

$(ARCHIVE)/$(XTRANS_SRC):
	$(DOWNLOAD) $(XTRANS_URL)/$(XTRANS_SRC)

$(D)/xtrans: $(D)/bootstrap $(ARCHIVE)/$(XTRANS_SRC)
	$(START_BUILD)
	$(REMOVE)/xtrans-$(XTRANS_VER)
	$(UNTAR)/$(XTRANS_SRC)
	$(CHDIR)/xtrans-$(XTRANS_VER); \
		$(call apply_patches, $(XTRANS_PATCH)); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(TARGET_DIR)/usr \
			--datadir=$(TARGET_DIR)/usr/lib \
			--without-xmlto \
		; \
		$(MAKE) all; \
		$(MAKE) install
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xtrans.pc
	$(REMOVE)/xtrans-$(XTRANS_VER)
	$(TOUCH)

#
# xcb-proto
#
XCBPROTO_VER = 1.17.0
XCBPROTO_SRC = xcb-proto-$(XCBPROTO_VER).tar.xz
XCBPROTO_URL = https://xorg.freedesktop.org/archive/individual/proto

XCBPROTO_PATCH = 

$(ARCHIVE)/$(XCBPROTO_SRC):
	$(DOWNLOAD) $(XCBPROTO_URL)/$(XCBPROTO_SRC)

$(D)/xcb-proto: $(D)/bootstrap $(ARCHIVE)/$(XCBPROTO_SRC)
	$(START_BUILD)
	$(REMOVE)/xcb-proto-$(XCBPROTO_VER)
	$(UNTAR)/$(XCBPROTO_SRC)
	$(CHDIR)/xcb-proto-$(XCBPROTO_VER); \
		$(call apply_patches, $(XCBPROTO_PATCH)); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		autoreconf -i; \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(TARGET_DIR)/usr \
			--datarootdir=$(TARGET_DIR)/usr/lib \
		; \
		$(MAKE) all; \
		$(MAKE) install
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xcb-proto.pc
	$(REMOVE)/xcb-proto-$(XCBPROTO_VER)
	$(TOUCH)

#
# libXau
#
LIBXAU_VER = 1.0.12
LIBXAU_SRC = libXau-$(LIBXAU_VER).tar.xz
LIBXAU_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBXAU_PATCH = 

$(ARCHIVE)/$(LIBXAU_SRC):
	$(DOWNLOAD) $(LIBXAU_URL)/$(LIBXAU_SRC)

$(D)/libXau: $(D)/bootstrap $(ARCHIVE)/$(LIBXAU_SRC)
	$(START_BUILD)
	$(REMOVE)/libXau-$(LIBXAU_VER)
	$(UNTAR)/$(LIBXAU_SRC)
	$(CHDIR)/libXau-$(LIBXAU_VER); \
		$(call apply_patches, $(LIBXAU_PATCH)); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libXau.la
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xau.pc
	$(REMOVE)/libXau-$(LIBXAU_VER)
	$(TOUCH)

#
# libxcb
#
LIBXCB_VER = 1.17.0
LIBXCB_SRC = libxcb-$(LIBXCB_VER).tar.xz
LIBXCB_URL = https://xorg.freedesktop.org/archive/individual/lib

LIBXCB_PATCH = 

$(ARCHIVE)/$(LIBXCB_SRC):
	$(DOWNLOAD) $(LIBXCB_URL)/$(LIBXCB_SRC)

$(D)/libxcb: $(D)/bootstrap $(D)/xcb-proto $(ARCHIVE)/$(LIBXCB_SRC)
	$(START_BUILD)
	$(REMOVE)/libxcb-$(LIBXCB_VER)
	$(UNTAR)/$(LIBXCB_SRC)
	$(CHDIR)/libxcb-$(LIBXCB_VER); \
		$(call apply_patches, $(LIBXCB_PATCH)); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(TARGET_DIR)/usr \
			--disable-screensaver \
			--disable-xprint \
			--disable-selinux \
			--disable-xvmc \
			PKG_CONFIG="${PKG_CONFIG} --define-variable=xcbincludedir=${TARGET_DIR}/usr/share/xcb" \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		$(REWRITE_LIBTOOL)/libxcb.la
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xcb.pc
	$(REMOVE)/libxcb-$(LIBXCB_VER)
	$(TOUCH)

#
# tinyX
#
TINYX_VER = 
TINYX_SRC = tinyx.git
TINYX_URL = https://github.com/tinycorelinux/tinyx.git

TINYX_PATCH = 

$(ARCHIVE)/$(TINYX_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(TINYX_SRC) ]; then \
		cd $(ARCHIVE)/$(TINYX_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(TINYX_URL) $(TINYX_SRC); \
	fi

$(D)/tinyX: $(D)/bootstrap $(ARCHIVE)/$(TINYX_SRC)
	$(START_BUILD)
	$(REMOVE)/tinyx
	cp -ra $(ARCHIVE)/$(TINYX_SRC) $(BUILD_TMP)/tinyx
	$(CHDIR)/tinyx; \
		$(call apply_patches, $(TINYX_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/tinyx
#	$(TOUCH)

#
# tinyxserver
#
TINYXSERVER_VER = 
TINYXSERVER_SRC = tinyxserver.git
TINYXSERVER_URL = https://github.com/idunham/tinyxserver.git

TINYXSERVER_PATCH = 

$(ARCHIVE)/$(TINYXSERVER_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(TINYXSERVER_SRC) ]; then \
		cd $(ARCHIVE)/$(TINYXSERVER_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(TINYXSERVER_URL) $(TINYXSERVER_SRC); \
	fi

$(D)/tinyxserver: $(D)/bootstrap $(ARCHIVE)/$(TINYXSERVER_SRC)
	$(START_BUILD)
	$(REMOVE)/tinyxserver
	cp -ra $(ARCHIVE)/$(TINYXSERVER_SRC) $(BUILD_TMP)/tinyxserver
	$(CHDIR)/tinyxserver; \
		$(call apply_patches, $(TINYXSERVER_PATCH)); \
		$(BUILDENV) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
#	$(REMOVE)/tinyxserver
#	$(TOUCH)

#
# libgbm
#
LIBGBM_VER = 
LIBGBM_SRC = libgbm.git
#LIBGBM_URL = https://github.com/glfs-book/libgbm.git
LIBGBM_URL = https://github.com/thayama/libgbm.git

LIBGBM_PATCH =

$(ARCHIVE)/$(LIBGBM_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(LIBGBM_SRC) ]; then \
		cd $(ARCHIVE)/$(LIBGBM_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(LIBGBM_URL) $(LIBGBM_SRC); \
	fi

$(D)/libgbm: $(D)/bootstrap $(ARCHIVE)/$(LIBGBM_SRC)
	$(START_BUILD)
	$(REMOVE)/libgbm
	cp -ra $(ARCHIVE)/$(LIBGBM_SRC) $(BUILD_TMP)/libgbm
	$(CHDIR)/libgbm; \
		$(call apply_patches, $(LIBGBM_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR);
		$(REWRITE_LIBTOOL)/libgbm.la
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libgbm.pc
	$(REMOVE)/libgbm
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

#
# sdl
#
SDL_VER = 1.2.15
SDL_SRC = SDL-$(SDL_VER).tar.gz
SDL_URL = http://www.libsdl.org/release

SDL_PATCH = \
	0001-Fix-compilation-with-libX11-1.5.99.902.patch \
	0002-SDL_x11yuv.c-fix-possible-use-after-free.patch \
	0003-Xext-Fix-function-declarations-without-a-prototype.patch \
	0004-src-stdlib-SDL_iconv.c-fix-types-mismatch.patch

$(ARCHIVE)/$(SDL_SRC):
	$(DOWNLOAD) $(SDL_URL)/$(SDL_SRC)
	
$(D)/sdl: $(D)/bootstrap $(ARCHIVE)/$(SDL_SRC)
	$(START_BUILD)
	$(REMOVE)/SDL-$(SDL_VER)
	$(UNTAR)/$(SDL_SRC)
	$(CHDIR)/SDL-$(SDL_VER); \
		$(call apply_patches, $(SDL_PATCH)); \
#		$(BUILDENV); \
#		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-video-qtopia=no \
			--enable-video-directfb=no \
			--enable-video-fbcon=yes \
			--enable-video-fbcon=no \
			--enable-video-x11=no \
			--disable-rpath \
			--enable-pulseaudio=no \
			--disable-arts \
			--disable-esd \
			--disable-nasm \
			--disable-video-ps3 \
		; \
		$(MAKE) CFLAGS="$(TARGET_CFLAGS)"; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/SDL-$(SDL_VER)
#	$(TOUCH)

