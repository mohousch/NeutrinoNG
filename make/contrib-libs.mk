#
# ncurses
#
NCURSES_VER = 6.0
NCURSES_SRC = ncurses-$(NCURSES_VER).tar.gz
NCURSES_URL = https://ftp.gnu.org/pub/gnu/ncurses

NCURSES_PATCH = ncurses-$(NCURSES_VER)-gcc-5.x-MKlib_gen.patch

$(ARCHIVE)/$(NCURSES_SRC):
	$(DOWNLOAD) $(NCURSES_URL)/$(NCURSES_SRC)

$(D)/ncurses: $(D)/bootstrap $(ARCHIVE)/$(NCURSES_SRC)
	$(START_BUILD)
	$(REMOVE)/ncurses-$(NCURSES_VER)
	$(UNTAR)/$(NCURSES_SRC)
	$(CHDIR)/ncurses-$(NCURSES_VER); \
		$(call apply_patches, $(NCURSES_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--enable-pc-files \
			--with-pkg-config \
			--with-pkg-config-libdir=/usr/lib/pkgconfig \
			--with-shared \
			--with-fallbacks='linux vt100 xterm' \
			--without-ada \
			--without-cxx \
			--without-cxx-binding \
			--without-debug \
			--without-manpages \
			--without-profile \
			--without-progs \
			--without-tests \
			--disable-big-core \
			--disable-rpath \
			--disable-rpath-hack \
			--enable-echo \
			--enable-const \
			--enable-overwrite \
		; \
		$(MAKE) libs \
			HOSTCC=gcc \
			HOSTCCFLAGS="$(CFLAGS) -DHAVE_CONFIG_H -I../ncurses -DNDEBUG -D_GNU_SRC -I../include" \
			HOSTLDFLAGS="$(LDFLAGS)"; \
		$(MAKE) install.libs DESTDIR=$(TARGET_DIR)
	mv $(TARGET_DIR)/usr/bin/ncurses6-config $(HOST_DIR)/bin
	rm -f $(addprefix $(TARGET_LIB_DIR)/,libform* libmenu* libpanel*)
	rm -f $(addprefix $(PKG_CONFIG_PATH)/,form.pc menu.pc panel.pc)
	$(REWRITE_PKGCONF) $(HOST_DIR)/bin/ncurses6-config
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ncurses.pc
	$(REMOVE)/ncurses-$(NCURSES_VER)
	$(TOUCH)

#
# gmp
#
GMP_VER = 6.1.2
GMP_SRC = gmp-$(GMP_VER).tar.xz
GMP_URL = https://gmplib.org/download/gmp

$(ARCHIVE)/$(GMP_SRC):
	$(DOWNLOAD) $(GMP_URL)/$(GMP_SRC)

$(D)/gmp: $(D)/bootstrap $(ARCHIVE)/$(GMP_SRC)
	$(START_BUILD)
	$(REMOVE)/gmp-$(GMP_VER)
	$(UNTAR)/$(GMP_SRC)
	$(CHDIR)/gmp-$(GMP_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--infodir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libgmp.la
	$(REMOVE)/gmp-$(GMP_VER)
	$(TOUCH)

#
# libffi
#
LIBFFI_VER = 3.2.1
LIBFFI_SRC = libffi-$(LIBFFI_VER).tar.gz
LIBFFI_URL = ftp://sourceware.org/pub/libffi

LIBFFI_PATCH = libffi-$(LIBFFI_VER).patch

$(ARCHIVE)/$(LIBFFI_SRC):
	$(DOWNLOAD) $(LIBFFI_URL)/$(LIBFFI_SRC)

$(D)/libffi: $(D)/bootstrap $(ARCHIVE)/$(LIBFFI_SRC)
	$(START_BUILD)
	$(REMOVE)/libffi-$(LIBFFI_VER)
	$(UNTAR)/$(LIBFFI_SRC)
	$(CHDIR)/libffi-$(LIBFFI_VER); \
		$(call apply_patches, $(LIBFFI_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-static \
			--enable-builddir=libffi \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libffi.pc
	$(REWRITE_LIBTOOL)/libffi.la
	$(REMOVE)/libffi-$(LIBFFI_VER)
	$(TOUCH)

#
# libglib2_genmarshal
#
LIBGLIB2_VER_MAJOR = 2
LIBGLIB2_VER_MINOR = 57
LIBGLIB2_VER_MICRO = 1
LIBGLIB2_VER = $(LIBGLIB2_VER_MAJOR).$(LIBGLIB2_VER_MINOR).$(LIBGLIB2_VER_MICRO)
LIBGLIB2_SRC = glib-$(LIBGLIB2_VER).tar.xz
LIBGLIB2_URL = https://ftp.gnome.org/pub/gnome/sources/glib/$(LIBGLIB2_VER_MAJOR).$(LIBGLIB2_VER_MINOR)

$(ARCHIVE)/$(LIBGLIB2_SRC):
	$(DOWNLOAD) $(LIBGLIB2_URL)/$(LIBGLIB2_SRC)

LIBGLIB2_PATCH  = libglib2-$(LIBGLIB2_VER)-disable-tests.patch
LIBGLIB2_PATCH += libglib2-$(LIBGLIB2_VER)-fix-gio-linking.patch

$(D)/libglib2: $(D)/bootstrap $(D)/zlib $(D)/libffi $(ARCHIVE)/$(LIBGLIB2_SRC)
	$(START_BUILD)
	$(REMOVE)/glib-$(LIBGLIB2_VER)
	$(UNTAR)/$(LIBGLIB2_SRC)
	$(CHDIR)/glib-$(LIBGLIB2_VER); \
		echo "glib_cv_va_copy=no" > config.cache; \
		echo "glib_cv___va_copy=yes" >> config.cache; \
		echo "glib_cv_va_val_copy=yes" >> config.cache; \
		echo "ac_cv_func_posix_getpwuid_r=yes" >> config.cache; \
		echo "ac_cv_func_posix_getgrgid_r=yes" >> config.cache; \
		echo "glib_cv_stack_grows=no" >> config.cache; \
		echo "glib_cv_uscore=no" >> config.cache; \
		echo "ac_cv_path_GLIB_GENMARSHAL=$(HOST_DIR)/bin/glib-genmarshal" >> config.cache; \
		$(call apply_patches, $(LIBGLIB2_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-static \
			--mandir=/.remove \
			--cache-file=config.cache \
			--disable-fam \
			--disable-libmount \
			--disable-gtk-doc \
			--disable-gtk-doc-html \
			--with-threads="posix" \
			--with-html-dir=/.remove \
			--with-pcre=internal \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glib-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gmodule-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gio-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gio-unix-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gmodule-export-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gmodule-no-export-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gobject-2.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gthread-2.0.pc
	$(REWRITE_LIBTOOL)/libglib-2.0.la
	$(REWRITE_LIBTOOL)/libgmodule-2.0.la
	$(REWRITE_LIBTOOL)/libgio-2.0.la
	$(REWRITE_LIBTOOL)/libgobject-2.0.la
	$(REWRITE_LIBTOOL)/libgthread-2.0.la
	$(REWRITE_LIBTOOLDEP)/libglib-2.0.la
	$(REWRITE_LIBTOOLDEP)/libgmodule-2.0.la
	$(REWRITE_LIBTOOLDEP)/libgio-2.0.la
	$(REWRITE_LIBTOOLDEP)/libgobject-2.0.la
	$(REWRITE_LIBTOOLDEP)/libgthread-2.0.la
	rm -rf $(addprefix $(TARGET_DIR)/usr/share/,bash-completion gettext gdb glib-2.0)
	$(REMOVE)/glib-$(LIBGLIB2_VER)
	$(TOUCH)

#
# libpcre
#
LIBPCRE_VER = 8.39
LIBPCRE_SRC = pcre-$(LIBPCRE_VER).tar.bz2
LIBPCRE_URL = https://sourceforge.net/projects/pcre/files/pcre/$(LIBPCRE_VER)

$(ARCHIVE)/$(LIBPCRE_SRC):
	$(DOWNLOAD) $(LIBPCRE_URL)/$(LIBPCRE_SRC)

$(D)/libpcre: $(D)/bootstrap $(ARCHIVE)/$(LIBPCRE_SRC)
	$(START_BUILD)
	$(REMOVE)/pcre-$(LIBPCRE_VER)
	$(UNTAR)/$(LIBPCRE_SRC)
	$(CHDIR)/pcre-$(LIBPCRE_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--enable-utf8 \
			--enable-unicode-properties \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	mv $(TARGET_DIR)/usr/bin/pcre-config $(HOST_DIR)/bin/pcre-config
	$(REWRITE_PKGCONF) $(HOST_DIR)/bin/pcre-config
	$(REWRITE_LIBTOOL)/libpcre.la
	$(REWRITE_LIBTOOL)/libpcrecpp.la
	$(REWRITE_LIBTOOL)/libpcreposix.la
	$(REWRITE_LIBTOOLDEP)/libpcrecpp.la
	$(REWRITE_LIBTOOLDEP)/libpcreposix.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libpcre.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libpcrecpp.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libpcreposix.pc
	$(REMOVE)/pcre-$(LIBPCRE_VER)
	$(TOUCH)

#
# libarchive
#
LIBARCHIVE_VER = 3.4.0
LIBARCHIVE_SRC = libarchive-$(LIBARCHIVE_VER).tar.gz
LIBARCHIVE_URL = https://www.libarchive.org/downloads

$(ARCHIVE)/$(LIBARCHIVE_SRC):
	$(DOWNLOAD) $(LIBARCHIVE_URL)/$(LIBARCHIVE_SRC)

$(D)/libarchive: $(D)/bootstrap $(ARCHIVE)/$(LIBARCHIVE_SRC)
	$(START_BUILD)
	$(REMOVE)/libarchive-$(LIBARCHIVE_VER)
	$(UNTAR)/$(LIBARCHIVE_SRC)
	$(CHDIR)/libarchive-$(LIBARCHIVE_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--enable-static=no \
			--disable-bsdtar \
			--disable-bsdcpio \
			--without-iconv \
			--without-libiconv-prefix \
			--without-lzo2 \
			--without-nettle \
			--without-xml2 \
			--without-expat \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libarchive.pc
	$(REWRITE_LIBTOOL)/libarchive.la
	$(REMOVE)/libarchive-$(LIBARCHIVE_VER)
	$(TOUCH)

#
# readline
#
READLINE_VER = 6.2
READLINE_SRC = readline-$(READLINE_VER).tar.gz
READLINE_URL = https://ftp.gnu.org/gnu/readline

$(ARCHIVE)/$(READLINE_SRC):
	$(DOWNLOAD) $(READLINE_URL)/$(READLINE_SRC)

$(D)/readline: $(D)/bootstrap $(ARCHIVE)/$(READLINE_SRC)
	$(START_BUILD)
	$(REMOVE)/readline-$(READLINE_VER)
	$(UNTAR)/$(READLINE_SRC)
	$(CHDIR)/readline-$(READLINE_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--datadir=/.remove \
			bash_cv_must_reinstall_sighandlers=no \
			bash_cv_func_sigsetjmp=present \
			bash_cv_func_strcoll_broken=no \
			bash_cv_have_mbstate_t=yes \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/readline-$(READLINE_VER)
	$(TOUCH)

#
# openssl
#
OPENSSL_MAJOR = 1.0.2
OPENSSL_MINOR = q
OPENSSL_VER = $(OPENSSL_MAJOR)$(OPENSSL_MINOR)
OPENSSL_SRC = openssl-$(OPENSSL_VER).tar.gz
OPENSSL_URL = https://www.openssl.org/source

OPENSSL_PATCH  = openssl-$(OPENSSL_VER)-optimize-for-size.patch
OPENSSL_PATCH += openssl-$(OPENSSL_VER)-makefile-dirs.patch
OPENSSL_PATCH += openssl-$(OPENSSL_VER)-disable_doc_tests.patch
OPENSSL_PATCH += openssl-$(OPENSSL_VER)-fix-parallel-building.patch
OPENSSL_PATCH += openssl-$(OPENSSL_VER)-compat_versioned_symbols-1.patch

OPENSSL_SED_PATCH = sed -i 's|MAKEDEPPROG=makedepend|MAKEDEPPROG=$(CROSS_DIR)/bin/$$(CC) -M|' Makefile

$(ARCHIVE)/$(OPENSSL_SRC):
	$(DOWNLOAD) $(OPENSSL_URL)/$(OPENSSL_SRC)

$(D)/openssl: $(D)/bootstrap $(ARCHIVE)/$(OPENSSL_SRC)
	$(START_BUILD)
	$(REMOVE)/openssl-$(OPENSSL_VER)
	$(UNTAR)/$(OPENSSL_SRC)
	$(CHDIR)/openssl-$(OPENSSL_VER); \
		$(call apply_patches, $(OPENSSL_PATCH)); \
		$(BUILDENV) \
		./Configure \
			-DL_ENDIAN \
			shared \
			no-hw \
			linux-generic32 \
			--prefix=/usr \
			--openssldir=/etc/ssl \
		; \
		$(OPENSSL_SED_PATCH); \
		$(MAKE) depend; \
		$(MAKE) all; \
		$(MAKE) install_sw INSTALL_PREFIX=$(TARGET_DIR)
	chmod 0755 $(TARGET_DIR)/usr/lib/lib{crypto,ssl}.so.*
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/openssl.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libcrypto.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libssl.pc
	cd $(TARGET_DIR) && rm -rf etc/ssl/man usr/bin/openssl usr/lib/engines
	ln -sf libcrypto.so.1.0.0 $(TARGET_DIR)/usr/lib/libcrypto.so.0.9.8
	ln -sf libssl.so.1.0.0 $(TARGET_DIR)/usr/lib/libssl.so.0.9.8
	$(REMOVE)/openssl-$(OPENSSL_VER)
	$(TOUCH)

#
# libbluray
#
LIBBLURAY_VER = 0.5.0
LIBBLURAY_SRC = libbluray-$(LIBBLURAY_VER).tar.bz2
LIBBLURAY_URL = ftp.videolan.org/pub/videolan/libbluray/$(LIBBLURAY_VER)

LIBBLURAY_PATCH = libbluray-$(LIBBLURAY_VER).patch

$(ARCHIVE)/$(LIBBLURAY_SRC):
	$(DOWNLOAD) $(LIBBLURAY_URL)/$(LIBBLURAY_SRC)

$(D)/libbluray: $(D)/bootstrap $(ARCHIVE)/$(LIBBLURAY_SRC)
	$(START_BUILD)
	$(REMOVE)/libbluray-$(LIBBLURAY_VER)
	$(UNTAR)/$(LIBBLURAY_SRC)
	$(CHDIR)/libbluray-$(LIBBLURAY_VER); \
		$(call apply_patches, $(LIBBLURAY_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--disable-static \
			--disable-extra-warnings \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--disable-doxygen-html \
			--disable-doxygen-ps \
			--disable-doxygen-pdf \
			--disable-examples \
			--without-libxml2 \
			--without-freetype \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libbluray.pc
	$(REWRITE_LIBTOOL)/libbluray.la
	$(REMOVE)/libbluray-$(LIBBLURAY_VER)
	$(TOUCH)

#
# boost
#
BOOST_VER_MAJOR = 1
BOOST_VER_MINOR = 61
BOOST_VER_MICRO = 0
BOOST_VER_ARCHIVE = $(BOOST_VER_MAJOR).$(BOOST_VER_MINOR).$(BOOST_VER_MICRO)
BOOST_VER = $(BOOST_VER_MAJOR)_$(BOOST_VER_MINOR)_$(BOOST_VER_MICRO)
BOOST_SRC = boost_$(BOOST_VER).tar.bz2
BOOST_URL = https://sourceforge.net/projects/boost/files/boost/$(BOOST_VER_ARCHIVE)

BOOST_PATCH = boost-$(BOOST_VER).patch

$(ARCHIVE)/$(BOOST_SRC):
	$(DOWNLOAD) $(BOOST_URL)/$(BOOST_SRC)

$(D)/boost: $(D)/bootstrap $(ARCHIVE)/$(BOOST_SRC)
	$(START_BUILD)
	$(REMOVE)/boost_$(BOOST_VER)
	$(UNTAR)/$(BOOST_SRC)
	$(CHDIR)/boost_$(BOOST_VER); \
		$(call apply_patches, $(BOOST_PATCH)); \
		rm -rf $(TARGET_DIR)/usr/include/boost; \
		mv $(BUILD_TMP)/boost_$(BOOST_VER)/boost $(TARGET_DIR)/usr/include/boost
	$(REMOVE)/boost_$(BOOST_VER)
	$(TOUCH)

#
# zlib
#
ZLIB_VER = 1.2.11
ZLIB_SRC = zlib-$(ZLIB_VER).tar.xz
ZLIB_URL = https://sourceforge.net/projects/libpng/files/zlib/$(ZLIB_VER)

ZLIB_PATCH = zlib-$(ZLIB_VER).patch

$(ARCHIVE)/$(ZLIB_SRC):
	$(DOWNLOAD) $(ZLIB_URL)/$(ZLIB_SRC)

$(D)/zlib: $(D)/bootstrap $(ARCHIVE)/$(ZLIB_SRC)
	$(START_BUILD)
	$(REMOVE)/zlib-$(ZLIB_VER)
	$(UNTAR)/$(ZLIB_SRC)
	$(CHDIR)/zlib-$(ZLIB_VER); \
		$(call apply_patches, $(ZLIB_PATCH)); \
		CC=$(TARGET)-gcc mandir=$(TARGET_DIR)/.remove CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
			--prefix=/usr \
			--shared \
			--uname=Linux \
		; \
		$(MAKE); \
		ln -sf /bin/true ldconfig; \
		$(MAKE) install prefix=$(TARGET_DIR)/usr
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/zlib.pc
	$(REMOVE)/zlib-$(ZLIB_VER)
	$(TOUCH)

#
# bzip2
#
BZIP2_VER = 1.0.8
BZIP2_SRC = bzip2-$(BZIP2_VER).tar.gz
BZIP2_URL = https://sourceware.org/pub/bzip2

BZIP2_PATCH = bzip2-$(BZIP2_VER).patch

$(ARCHIVE)/$(BZIP2_SRC):
	$(DOWNLOAD) $(BZIP2_URL)/$(BZIP2_SRC)

$(D)/bzip2: $(D)/bootstrap $(ARCHIVE)/$(BZIP2_SRC)
	$(START_BUILD)
	$(REMOVE)/bzip2-$(BZIP2_VER)
	$(UNTAR)/$(BZIP2_SRC)
	$(CHDIR)/bzip2-$(BZIP2_VER); \
		$(call apply_patches, $(BZIP2_PATCH)); \
		mv Makefile-libbz2_so Makefile; \
		$(MAKE) all CC=$(TARGET)-gcc AR=$(TARGET)-ar RANLIB=$(TARGET)-ranlib; \
		$(MAKE) install PREFIX=$(TARGET_DIR)/usr
	$(REMOVE)/bzip2-$(BZIP2_VER)
	$(TOUCH)

#
# timezone
#
TZDATA_VER = 2016a
TZDATA_SRC = tzdata$(TZDATA_VER).tar.gz
TZDATA_URL = ftp://ftp.iana.org/tz/releases

TZDATA_ZONELIST = africa antarctica asia australasia europe northamerica southamerica pacificnew etcetera backward
DEFAULT_TIMEZONE ?= "CET"

$(ARCHIVE)/$(TZDATA_SRC):
	$(DOWNLOAD) $(TZDATA_URL)/$(TZDATA_SRC)

$(D)/timezone: $(D)/bootstrap find-zic $(ARCHIVE)/$(TZDATA_SRC)
	$(START_BUILD)
	$(REMOVE)/timezone
	mkdir $(BUILD_TMP)/timezone
	tar -C $(BUILD_TMP)/timezone -xf $(ARCHIVE)/$(TZDATA_SRC)
	$(CHDIR)/timezone; \
		unset ${!LC_*}; LANG=POSIX; LC_ALL=POSIX; export LANG LC_ALL; \
		for zone in $(TZDATA_ZONELIST); do \
			zic -d zoneinfo -L /dev/null -y yearistype.sh $$zone ; \
			: zic -d zoneinfo/posix -L /dev/null -y yearistype.sh $$zone ; \
			: zic -d zoneinfo/right -L leapseconds -y yearistype.sh $$zone ; \
		done; \
		install -d -m 0755 $(TARGET_DIR)/usr/share $(TARGET_DIR)/etc; \
		cp -a zoneinfo $(TARGET_DIR)/usr/share/; \
		cp -v zone.tab iso3166.tab $(TARGET_DIR)/usr/share/zoneinfo/; \
		# Install default timezone
		if [ -e $(TARGET_DIR)/usr/share/zoneinfo/$(DEFAULT_TIMEZONE) ]; then \
			echo ${DEFAULT_TIMEZONE} > $(TARGET_DIR)/etc/timezone; \
		fi; \
	install -m 0644 $(SKEL_ROOT)/etc/timezone.xml $(TARGET_DIR)/etc/
	$(REMOVE)/timezone
	$(TOUCH)

#
# freetype
#
FREETYPE_VER = 2.9.1
FREETYPE_SRC = freetype-$(FREETYPE_VER).tar.bz2
FREETYPE_URL = https://sourceforge.net/projects/freetype/files/freetype2/$(FREETYPE_VER)

FREETYPE_PATCH = freetype-$(FREETYPE_VER).patch

$(ARCHIVE)/$(FREETYPE_SRC):
	$(DOWNLOAD) $(FREETYPE_URL)/$(FREETYPE_SRC)

$(D)/freetype: $(D)/bootstrap $(D)/zlib $(D)/libpng $(ARCHIVE)/$(FREETYPE_SRC)
	$(START_BUILD)
	$(REMOVE)/freetype-$(FREETYPE_VER)
	$(UNTAR)/$(FREETYPE_SRC)
	$(CHDIR)/freetype-$(FREETYPE_VER); \
		$(call apply_patches, $(FREETYPE_PATCH)); \
		sed -r "s:.*(#.*SUBPIXEL_(RENDERING|HINTING  2)) .*:\1:g" \
			-i include/freetype/config/ftoption.h; \
		sed -i '/^FONT_MODULES += \(type1\|cid\|pfr\|type42\|pcf\|bdf\|winfonts\|cff\)/d' modules.cfg; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-static \
			--enable-shared \
			--enable-freetype-config \
			--with-bzip2=no \
			--with-zlib=yes \
			--with-png=yes \
			--without-harfbuzz \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		if [ ! -e $(TARGET_DIR)/usr/include/freetype ] ; then \
			ln -sf freetype2 $(TARGET_DIR)/usr/include/freetype; \
		fi; \
		sed -e 's:^prefix=.*:prefix="$(TARGET_DIR)/usr":' \
		    -e 's:^exec_prefix=.*:exec_prefix="$${prefix}":' \
		    -e 's:^includedir=.*:includedir="$${prefix}/include":' \
		    -e 's:^libdir=.*:libdir="$${exec_prefix}/lib":' \
		    -i $(TARGET_DIR)/usr/bin/freetype-config; \
		mv $(TARGET_DIR)/usr/bin/freetype-config $(HOST_DIR)/bin/freetype-config
	$(REWRITE_LIBTOOL)/libfreetype.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/freetype2.pc
	$(REMOVE)/freetype-$(FREETYPE_VER)
	$(TOUCH)

#
# lirc
#
ifeq ($(BOXARCH), sh4)
LIRC_VER = 0.9.0
else
LIRC_VER = 0.10.2
endif
LIRC_SRC = lirc-$(LIRC_VER).tar.bz2
LIRC_URL = https://sourceforge.net/projects/lirc/files/LIRC/$(LIRC_VER)

ifeq ($(BOXARCH), sh4)
LIRC_PATCH = lirc-$(LIRC_VER).patch
endif

LIRC_OPTS = --with-kerneldir=$(KERNEL_DIR) \
			--enable-uinput \
			--enable-devinput \
			--without-x \
			--with-devdir=/dev \
			--with-moduledir=/lib/modules \
			--with-major=61 \
			--with-driver=userspace \
			--enable-debug \
			--with-syslog=LOG_DAEMON \
			--enable-sandboxed \
			DEVINPUT_HEADER=$(CROSS_DIR)/$(TARGET)/sys-root/usr/include/linux/input.h

$(ARCHIVE)/$(LIRC_SRC):
	$(DOWNLOAD) $(LIRC_URL)/$(LIRC_SRC)

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
LIRC_CFLAGS = -D__KERNEL_STRICT_NAMES -DUINPUT_NEUTRINO_HACK -DSPARK -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

$(D)/lirc: $(D)/bootstrap $(ARCHIVE)/$(LIRC_SRC)
	$(START_BUILD)
	$(REMOVE)/lirc-$(LIRC_VER)
	$(UNTAR)/$(LIRC_SRC)
	$(CHDIR)/lirc-$(LIRC_VER); \
		$(call apply_patches, $(LIRC_PATCH)); \
		$(CONFIGURE) \
		ac_cv_path_LIBUSB_CONFIG= \
		CFLAGS="$(TARGET_CFLAGS) $(LIRC_CFLAGS)" \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--sbindir=/usr/bin \
			--mandir=/.remove \
			--sysconfdir=/etc \
			$(LIRC_OPTS) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/liblirc_client.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,lircmd ircat irpty irrecord irsend irw lircrcd mode2 pronto2lirc)
	rm -rf $(TARGET_DIR)/usr/var
	$(REMOVE)/lirc-$(LIRC_VER)
	$(TOUCH)

#
# libjpeg
#
JPEG_VER = 8d
JPEG_SRC = jpegsrc.v$(JPEG_VER).tar.gz
JPEG_URL = http://www.ijg.org/files

JPEG_PATCH = jpeg-$(JPEG_VER).patch

$(ARCHIVE)/$(JPEG_SRC):
	$(DOWNLOAD) $(JPEG_URL)/$(JPEG_SRC)

$(D)/libjpeg: $(D)/bootstrap $(ARCHIVE)/$(JPEG_SRC)
	$(START_BUILD)
	$(REMOVE)/jpeg-$(JPEG_VER)
	$(UNTAR)/$(JPEG_SRC)
	$(CHDIR)/jpeg-$(JPEG_VER); \
		$(call apply_patches, $(JPEG_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libjpeg.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cjpeg djpeg jpegtran rdjpgcom wrjpgcom)
	$(REMOVE)/jpeg-$(JPEG_VER)
	$(TOUCH)

#
# libjpeg_turbo2
#
LIBJPEG_TURBO2_VER = 2.0.0
LIBJPEG_TURBO2_SRC = libjpeg-turbo-$(LIBJPEG_TURBO2_VER).tar.gz
LIBJPEG_TURBO2_URL = https://sourceforge.net/projects/libjpeg-turbo/files/$(LIBJPEG_TURBO2_VER)

LIBJPEG_TURBO2_PATCH = libjpeg-turbo-tiff-ojpeg.patch

$(ARCHIVE)/$(LIBJPEG_TURBO2_SRC):
	$(DOWNLOAD) $(LIBJPEG_TURBO2_URL)/$(LIBJPEG_TURBO2_SRC)

$(D)/libjpeg_turbo2: $(D)/bootstrap $(ARCHIVE)/$(LIBJPEG_TURBO2_SRC)
	$(START_BUILD)
	$(REMOVE)/libjpeg-turbo-$(LIBJPEG_TURBO2_VER)
	$(UNTAR)/$(LIBJPEG_TURBO2_SRC)
	$(CHDIR)/libjpeg-turbo-$(LIBJPEG_TURBO2_VER); \
		$(call apply_patches, $(LIBJPEG_TURBO2_PATCH)); \
		cmake   -DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_C_COMPILER=$(TARGET)-gcc \
			-DCMAKE_CXX_COMPILER=$(TARGET)-g++ \
			-DCMAKE_C_FLAGS="-pipe -Os" \
			-DCMAKE_CXX_FLAGS="-pipe -Os" \
			-DWITH_SIMD=False \
			-DCMAKE_INSTALL_DOCDIR=/.remove \
			-DCMAKE_INSTALL_MANDIR=/.remove \
			-DCMAKE_INSTALL_DEFAULT_LIBDIR=lib \
			-DENABLE_STATIC=OFF \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cjpeg djpeg jpegtran rdjpgcom wrjpgcom tjbench)
	$(REMOVE)/libjpeg-turbo-$(LIBJPEG_TURBO2_VER)
	$(TOUCH)

#
# libjpeg_turbo
#
LIBJPEG_TURBO_VER = 1.5.3
LIBJPEG_TURBO_SRC = libjpeg-turbo-$(LIBJPEG_TURBO_VER).tar.gz
LIBJPEG_TURBO_URL = https://sourceforge.net/projects/libjpeg-turbo/files/$(LIBJPEG_TURBO_VER)

$(ARCHIVE)/$(LIBJPEG_TURBO_SRC):
	$(DOWNLOAD) $(LIBJPEG_TURBO_URL)/$(LIBJPEG_TURBO_SRC)

$(D)/libjpeg_turbo: $(D)/bootstrap $(ARCHIVE)/$(LIBJPEG_TURBO_SRC)
	$(START_BUILD)
	$(REMOVE)/libjpeg-turbo-$(LIBJPEG_TURBO_VER)
	$(UNTAR)/$(LIBJPEG_TURBO_SRC)
	$(CHDIR)/libjpeg-turbo-$(LIBJPEG_TURBO_VER); \
		export CC=$(TARGET)-gcc; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--mandir=/.remove \
			--docdir=/.remove \
			--includedir=/.remove \
			--with-jpeg8 \
			--disable-static \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR); \
		make clean; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--mandir=/.remove \
			--docdir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libjpeg.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libjpeg.pc
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cjpeg djpeg jpegtran rdjpgcom wrjpgcom tjbench)
	rm -f $(TARGET_DIR)/usr/lib/libturbojpeg* $(TARGET_DIR)/usr/include/turbojpeg.h $(PKG_CONFIG_PATH)/libturbojpeg.pc
	$(REMOVE)/libjpeg-turbo-$(LIBJPEG_TURBO_VER)
	$(TOUCH)

#
# libpng
#
LIBPNG_VER = 1.6.35
LIBPNG_VER_X = 16
LIBPNG_SRC = libpng-$(LIBPNG_VER).tar.xz
LIBPNG_URL1 = https://sourceforge.net/projects/libpng/files/libpng$(LIBPNG_VER_X)/$(LIBPNG_VER)
LIBPNG_URL2 = https://sourceforge.net/projects/libpng/files/libpng$(LIBPNG_VER_X)/older-releases/$(LIBPNG_VER)

LIBPNG_PATCH = libpng-$(LIBPNG_VER)-disable-tools.patch

$(ARCHIVE)/$(LIBPNG_SRC):
	$(DOWNLOAD) $(LIBPNG_URL1)/$(LIBPNG_SRC) || \
	$(DOWNLOAD) $(LIBPNG_URL2)/$(LIBPNG_SRC)

$(D)/libpng: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(LIBPNG_SRC)
	$(START_BUILD)
	$(REMOVE)/libpng-$(LIBPNG_VER)
	$(UNTAR)/$(LIBPNG_SRC)
	$(CHDIR)/libpng-$(LIBPNG_VER); \
		$(call apply_patches, $(LIBPNG_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-mips-msa \
			--disable-powerpc-vsx \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		sed -e 's:^prefix=.*:prefix="$(TARGET_DIR)/usr":' -i $(TARGET_DIR)/usr/bin/libpng$(LIBPNG_VER_X)-config; \
		mv $(TARGET_DIR)/usr/bin/libpng*-config $(HOST_DIR)/bin/
	$(REWRITE_LIBTOOL)/libpng16.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libpng$(LIBPNG_VER_X).pc
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,pngfix png-fix-itxt)
	$(REMOVE)/libpng-$(LIBPNG_VER)
	$(TOUCH)

#
# png++
#
PNGPP_VER = 0.2.9
PNGPP_SRC = png++-$(PNGPP_VER).tar.gz
PNGPP_URL = https://download.savannah.gnu.org/releases/pngpp

$(ARCHIVE)/$(PNGPP_SRC):
	$(DOWNLOAD) $(PNGPP)/$(PNGPP_SRC)

$(D)/pngpp: $(D)/bootstrap $(D)/libpng $(ARCHIVE)/$(PNGPP_SRC)
	$(START_BUILD)
	$(REMOVE)/png++-$(PNGPP_VER)
	$(UNTAR)/$(PNGPP_SRC)
	$(CHDIR)/png++-$(PNGPP_VER); \
		$(MAKE) install-headers PREFIX=$(TARGET_DIR)/usr
	$(REMOVE)/png++-$(PNGPP_VER)
	$(TOUCH)

#
# giflib
#
GIFLIB_VER = 5.1.4
GIFLIB_SRC = giflib-$(GIFLIB_VER).tar.gz
GIFLIB_URL = https://sourceforge.net/projects/giflib/files/giflib-5.x

$(ARCHIVE)/$(GIFLIB_SRC):
	$(DOWNLOAD) $(GIFLIB_URL)/$(GIFLIB_SRC)

$(D)/giflib: $(D)/bootstrap $(ARCHIVE)/$(GIFLIB_SRC)
	$(START_BUILD)
	$(REMOVE)/giflib-$(GIFLIB_VER)
	$(UNTAR)/$(GIFLIB_SRC)
	$(CHDIR)/giflib-$(GIFLIB_VER); \
		export ac_cv_prog_have_xmlto=no; \
		$(CONFIGURE) \
			--prefix=/usr \
			--bindir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libgif.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,gif2rgb gifbuild gifclrmp gifecho giffix gifinto giftext giftool)
	$(REMOVE)/giflib-$(GIFLIB_VER)
	$(TOUCH)

#
# libconfig
#
LIBCONFIG_VER = 1.4.10
LIBCONFIG_SRC = libconfig-$(LIBCONFIG_VER).tar.gz
LIBCONFIG_URL = http://www.hyperrealm.com/packages

$(ARCHIVE)/$(LIBCONFIG_SRC):
	$(DOWNLOAD) $(LIBCONFIG_URL)/$(LIBCONFIG_SRC)

$(D)/libconfig: $(D)/bootstrap $(ARCHIVE)/$(LIBCONFIG_SRC)
	$(START_BUILD)
	$(REMOVE)/libconfig-$(LIBCONFIG_VER)
	$(UNTAR)/$(LIBCONFIG_SRC)
	$(CHDIR)/libconfig-$(LIBCONFIG_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-static \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libconfig.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libconfig++.pc
	$(REWRITE_LIBTOOL)/libconfig.la
	$(REWRITE_LIBTOOL)/libconfig++.la
	$(REMOVE)/libconfig-$(LIBCONFIG_VER)
	$(TOUCH)

#
# libcurl
#
LIBCURL_VER = 7.61.1
LIBCURL_SRC = curl-$(LIBCURL_VER).tar.bz2
LIBCURL_URL = https://curl.haxx.se/download

LIBCURL_PATCH = libcurl-$(LIBCURL_VER).patch

CACERT_SRC = cacert.pem
CACERT_URL = https://curl.haxx.se/ca

$(ARCHIVE)/$(CACERT_SRC):
	$(DOWNLOAD) $(CACERT_URL)/$(CACERT_SRC)

$(D)/ca-bundle: $(ARCHIVE)/$(CACERT_SRC)
	$(START_BUILD)
	install -D -m 644 $(ARCHIVE)/$(CACERT_SRC) $(TARGET_DIR)/$(CA_BUNDLE_DIR)/$(CA_BUNDLE)
	$(TOUCH)

$(ARCHIVE)/$(LIBCURL_SRC):
	$(DOWNLOAD) $(LIBCURL_URL)/$(LIBCURL_SRC)

$(D)/libcurl: $(D)/bootstrap $(D)/zlib $(D)/openssl $(D)/ca-bundle $(ARCHIVE)/$(LIBCURL_SRC)
	$(START_BUILD)
	$(REMOVE)/curl-$(LIBCURL_VER)
	$(UNTAR)/$(LIBCURL_SRC)
	$(CHDIR)/curl-$(LIBCURL_VER); \
		$(call apply_patches, $(LIBCURL_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--enable-silent-rules \
			--disable-debug \
			--disable-curldebug \
			--disable-manual \
			--disable-file \
			--disable-rtsp \
			--disable-dict \
			--disable-imap \
			--disable-pop3 \
			--disable-smtp \
			--enable-shared \
			--enable-optimize \
			--disable-verbose \
			--disable-ldap \
			--without-libidn \
			--without-libidn2 \
			--without-winidn \
			--without-libpsl \
			--with-ca-bundle=$(CA_BUNDLE_DIR)/$(CA_BUNDLE) \
			--with-random=/dev/urandom \
			--with-ssl=$(TARGET_DIR)/usr \
		; \
		$(MAKE) all; \
		sed -e "s,^prefix=,prefix=$(TARGET_DIR)," < curl-config > $(HOST_DIR)/bin/curl-config; \
		chmod 755 $(HOST_DIR)/bin/curl-config; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		rm -f $(TARGET_DIR)/usr/bin/curl-config
	$(REWRITE_LIBTOOL)/libcurl.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libcurl.pc
	$(REMOVE)/curl-$(LIBCURL_VER)
	$(TOUCH)

#
# libfribidi
#
LIBFRIBIDI_VER = 1.0.11
LIBFRIBIDI_SRC = fribidi-$(LIBFRIBIDI_VER).tar.xz
LIBFRIBIDI_URL = https://github.com/fribidi/fribidi/releases/download/v$(LIBFRIBIDI_VER)

LIBFRIBIDI_PATCH = libfribidi-$(LIBFRIBIDI_VER).patch

$(ARCHIVE)/$(LIBFRIBIDI_SRC):
	$(DOWNLOAD) $(LIBFRIBIDI_URL)/$(LIBFRIBIDI_SRC)

$(D)/libfribidi: $(D)/bootstrap $(ARCHIVE)/$(LIBFRIBIDI_SRC)
	$(START_BUILD)
	$(REMOVE)/fribidi-$(LIBFRIBIDI_VER)
	$(UNTAR)/$(LIBFRIBIDI_SRC)
	$(CHDIR)/fribidi-$(LIBFRIBIDI_VER); \
		$(call apply_patches, $(LIBFRIBIDI_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--enable-shared \
			--enable-static \
			--disable-debug \
			--disable-deprecated \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fribidi.pc
	$(REWRITE_LIBTOOL)/libfribidi.la
	cd $(TARGET_DIR) && rm usr/bin/fribidi
	$(REMOVE)/fribidi-$(LIBFRIBIDI_VER)
	$(TOUCH)

#
# libsigc
#
LIBSIGC_VER_MAJOR = 2
LIBSIGC_VER_MINOR = 4
LIBSIGC_VER_MICRO = 1
LIBSIGC_VER = $(LIBSIGC_VER_MAJOR).$(LIBSIGC_VER_MINOR).$(LIBSIGC_VER_MICRO)
LIBSIGC_SRC = libsigc++-$(LIBSIGC_VER).tar.xz
LIBSIGC_URL = https://ftp.gnome.org/pub/GNOME/sources/libsigc++/$(LIBSIGC_VER_MAJOR).$(LIBSIGC_VER_MINOR)

$(ARCHIVE)/$(LIBSIGC_SRC):
	$(DOWNLOAD) $(LIBSIGC_URL)/$(LIBSIGC_SRC)

$(D)/libsigc: $(D)/bootstrap $(ARCHIVE)/$(LIBSIGC_SRC)
	$(START_BUILD)
	$(REMOVE)/libsigc++-$(LIBSIGC_VER)
	$(UNTAR)/$(LIBSIGC_SRC)
	$(CHDIR)/libsigc++-$(LIBSIGC_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--disable-documentation \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR); \
		if [ -d $(TARGET_DIR)/usr/include/sigc++-2.0/sigc++ ] ; then \
			ln -sf ./sigc++-2.0/sigc++ $(TARGET_DIR)/usr/include/sigc++; \
		fi;
		mv $(TARGET_DIR)/usr/lib/sigc++-2.0/include/sigc++config.h $(TARGET_DIR)/usr/include; \
		rm -fr $(TARGET_DIR)/usr/lib/sigc++-2.0
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/sigc++-2.0.pc
	$(REWRITE_LIBTOOL)/libsigc-2.0.la
	$(REMOVE)/libsigc++-$(LIBSIGC_VER)
	$(TOUCH)

#
# libmad
#
LIBMAD_VER = 0.15.1b
LIBMAD_SRC = libmad-$(LIBMAD_VER).tar.gz
LIBMAD_URL = https://sourceforge.net/projects/mad/files/libmad/$(LIBMAD_VER)

LIBMAD_PATCH = libmad-$(LIBMAD_VER).patch \
	       libmad-mips-h-constraint-removal.patch \

$(ARCHIVE)/$(LIBMAD_SRC):
	$(DOWNLOAD) $(LIBMAD_URL)/$(LIBMAD_SRC)

$(D)/libmad: $(D)/bootstrap $(ARCHIVE)/$(LIBMAD_SRC)
	$(START_BUILD)
	$(REMOVE)/libmad-$(LIBMAD_VER)
	$(UNTAR)/$(LIBMAD_SRC)
	$(CHDIR)/libmad-$(LIBMAD_VER); \
		$(call apply_patches, $(LIBMAD_PATCH)); \
		touch NEWS AUTHORS ChangeLog; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-debugging \
			--enable-shared=yes \
			--enable-speed \
			--enable-sso \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/mad.pc
	$(REWRITE_LIBTOOL)/libmad.la
	$(REMOVE)/libmad-$(LIBMAD_VER)
	$(TOUCH)

#
# libid3tag
#
LIBID3TAG_VER = 0.15.1b
LIBID3TAG_SRC = libid3tag-$(LIBID3TAG_VER).tar.gz
LIBID3TAG_URL = https://sourceforge.net/projects/mad/files/libid3tag/$(LIBID3TAG_VER)

ifeq ($(BOXARCH), $(filter $(BOXARCH), sh4 arm mips))
LIBID3TAG_PATCH = libid3tag-$(LIBID3TAG_VER).patch
endif

$(ARCHIVE)/$(LIBID3TAG_SRC):
	$(DOWNLOAD) $(LIBID3TAG_URL)/$(LIBID3TAG_SRC)

$(D)/libid3tag: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(LIBID3TAG_SRC)
	$(START_BUILD)
	$(REMOVE)/libid3tag-$(LIBID3TAG_VER)
	$(UNTAR)/$(LIBID3TAG_SRC)
	$(CHDIR)/libid3tag-$(LIBID3TAG_VER); \
		$(call apply_patches, $(LIBID3TAG_PATCH)); \
		touch NEWS AUTHORS ChangeLog; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared=yes \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
ifeq ($(BOXARCH), $(filter $(BOXARCH), sh4 arm mips))		
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/id3tag.pc
endif
	$(REWRITE_LIBTOOL)/libid3tag.la
	$(REMOVE)/libid3tag-$(LIBID3TAG_VER)
	$(TOUCH)

#
# flac
#
FLAC_VER = 1.3.2
FLAC_SRC = flac-$(FLAC_VER).tar.xz
FLAC_URL = https://ftp.osuosl.org/pub/xiph/releases/flac

FLAC_PATCH = flac-$(FLAC_VER).patch

$(ARCHIVE)/$(FLAC_SRC):
	$(DOWNLOAD) $(FLAC_URL)/$(FLAC_SRC)

$(D)/flac: $(D)/bootstrap $(ARCHIVE)/$(FLAC_SRC)
	$(START_BUILD)
	$(REMOVE)/flac-$(FLAC_VER)
	$(UNTAR)/$(FLAC_SRC)
	$(CHDIR)/flac-$(FLAC_VER); \
		$(call apply_patches, $(FLAC_PATCH)); \
		touch NEWS AUTHORS ChangeLog; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--datarootdir=/.remove \
			--disable-cpplibs \
			--disable-debug \
			--disable-asm-optimizations \
			--disable-sse \
			--disable-altivec \
			--disable-doxygen-docs \
			--disable-thorough-tests \
			--disable-exhaustive-tests \
			--disable-valgrind-testing \
			--disable-ogg \
			--disable-oggtest \
			--disable-local-xmms-plugin \
			--disable-xmms-plugin \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) docdir=/.remove
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/flac.pc
	$(REWRITE_LIBTOOL)/libFLAC.la
	$(REMOVE)/flac-$(FLAC_VER)
	$(TOUCH)

#
# libogg
#
LIBOGG_VER = 1.3.3
LIBOGG_SRC = libogg-$(LIBOGG_VER).tar.gz
LIBOGG_URL = https://ftp.osuosl.org/pub/xiph/releases/ogg

$(ARCHIVE)/$(LIBOGG_SRC):
	$(DOWNLOAD) $(LIBOGG_URL)/$(LIBOGG_SRC)

$(D)/libogg: $(D)/bootstrap $(ARCHIVE)/$(LIBOGG_SRC)
	$(START_BUILD)
	$(REMOVE)/libogg-$(LIBOGG_VER)
	$(UNTAR)/$(LIBOGG_SRC)
	$(CHDIR)/libogg-$(LIBOGG_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--docdir=/.remove \
			--enable-shared \
			--disable-static \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ogg.pc
	$(REWRITE_LIBTOOL)/libogg.la
	$(REMOVE)/libogg-$(LIBOGG_VER)
	$(TOUCH)

#
# libvorbis
#
LIBVORBIS_VER = 1.3.6
LIBVORBIS_SRC = libvorbis-$(LIBVORBIS_VER).tar.xz
LIBVORBIS_URL = https://ftp.osuosl.org/pub/xiph/releases/vorbis

$(ARCHIVE)/$(LIBVORBIS_SRC):
	$(DOWNLOAD) $(LIBVORBIS_URL)/$(LIBVORBIS_SRC)

$(D)/libvorbis: $(D)/bootstrap $(D)/libogg $(ARCHIVE)/$(LIBVORBIS_SRC)
	$(START_BUILD)
	$(REMOVE)/libvorbis-$(LIBVORBIS_VER)
	$(UNTAR)/$(LIBVORBIS_SRC)
	$(CHDIR)/libvorbis-$(LIBVORBIS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--docdir=/.remove \
			--mandir=/.remove \
			--disable-docs \
			--disable-examples \
			--disable-oggtest \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) docdir=/.remove
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbis.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbisenc.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbisfile.pc
	$(REWRITE_LIBTOOL)/libvorbis.la
	$(REWRITE_LIBTOOL)/libvorbisenc.la
	$(REWRITE_LIBTOOL)/libvorbisfile.la
	$(REWRITE_LIBTOOLDEP)/libvorbis.la
	$(REWRITE_LIBTOOLDEP)/libvorbisenc.la
	$(REWRITE_LIBTOOLDEP)/libvorbisfile.la
	$(REMOVE)/libvorbis-$(LIBVORBIS_VER)
	$(TOUCH)

#
# libvorbisidec
#
LIBVORBISIDEC_VER = 1.2.1+git20180316
LIBVORBISIDEC_VER_APPEND = .orig
LIBVORBISIDEC_SRC = libvorbisidec_$(LIBVORBISIDEC_VER)$(LIBVORBISIDEC_VER_APPEND).tar.gz
LIBVORBISIDEC_URL = https://ftp.de.debian.org/debian/pool/main/libv/libvorbisidec

$(ARCHIVE)/$(LIBVORBISIDEC_SRC):
	$(DOWNLOAD) $(LIBVORBISIDEC_URL)/$(LIBVORBISIDEC_SRC)

$(D)/libvorbisidec: $(D)/bootstrap $(D)/libogg $(ARCHIVE)/$(LIBVORBISIDEC_SRC)
	$(START_BUILD)
	$(REMOVE)/libvorbisidec-$(LIBVORBISIDEC_VER)
	$(UNTAR)/$(LIBVORBISIDEC_SRC)
	$(CHDIR)/libvorbisidec-$(LIBVORBISIDEC_VER); \
		$(call apply_patches, $(LIBVORBISIDEC_PATCH)); \
		ACLOCAL_FLAGS="-I . -I $(TARGET_DIR)/usr/share/aclocal" \
		$(BUILDENV) \
		./autogen.sh \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/vorbisidec.pc
	$(REWRITE_LIBTOOL)/libvorbisidec.la
	$(REMOVE)/libvorbisidec-$(LIBVORBISIDEC_VER)
	$(TOUCH)

#
# libiconv
#
LIBICONV_VER = 1.15
LIBICONV_SRC = libiconv-$(LIBICONV_VER).tar.gz
LIBICONV_URL = https://ftp.gnu.org/gnu/libiconv

$(ARCHIVE)/$(LIBICONV_SRC):
	$(DOWNLOAD) $(LIBICONV_URL)/$(LIBICONV_SRC)

$(D)/libiconv: $(D)/bootstrap $(ARCHIVE)/$(LIBICONV_SRC)
	$(START_BUILD)
	$(REMOVE)/libiconv-$(LIBICONV_VER)
	$(UNTAR)/$(LIBICONV_SRC)
	$(CHDIR)/libiconv-$(LIBICONV_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--bindir=/.remove \
			--datarootdir=/.remove \
			--disable-static \
			--enable-shared \
		; \
		$(MAKE); \
		cp ./srcm4/* $(HOST_DIR)/share/aclocal/ ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libcharset.la
	$(REWRITE_LIBTOOL)/libiconv.la
	rm -f $(addprefix $(TARGET_DIR)/usr/lib/,preloadable_libiconv.so)
	$(REMOVE)/libiconv-$(LIBICONV_VER)
	$(TOUCH)

#
# expat
#
EXPAT_VER = 62aff4b
EXPAT_SRC = libexpat.git.tar.bz2
EXPAT_URL = https://github.com/libexpat/libexpat.git

EXPAT_PATCH  = expat-libtool-tag.patch
EXPAT_PATCH += expat-enum-fix.patch

$(ARCHIVE)/$(EXPAT_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(EXPAT_URL) $(EXPAT_VER) $(notdir $@) $(ARCHIVE)

$(D)/expat: $(D)/bootstrap $(ARCHIVE)/$(EXPAT_SRC)
	$(START_BUILD)
	$(REMOVE)/libexpat.git
	$(UNTAR)/$(EXPAT_SRC)
	$(CHDIR)/libexpat.git/expat; \
		$(call apply_patches, $(EXPAT_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--bindir=/.remove \
			--without-xmlwf \
			--without-docbook \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/expat.pc
	$(REWRITE_LIBTOOL)/libexpat.la
	$(REMOVE)/libexpat.git
	$(TOUCH)
#
# fontconfig
#
FONTCONFIG_VER = 2.11.93
FONTCONFIG_SRC = fontconfig-$(FONTCONFIG_VER).tar.bz2
FONTCONFIG_URL = https://www.freedesktop.org/software/fontconfig/release

FONTCONFIG_PATCH = fontconfig-glibc-$(FONTCONFIG_VER).patch

$(ARCHIVE)/$(FONTCONFIG_SRC):
	$(DOWNLOAD) $(FONTCONFIG_URL)/$(FONTCONFIG_SRC)

$(D)/fontconfig: $(D)/bootstrap $(D)/freetype $(D)/expat $(ARCHIVE)/$(FONTCONFIG_SRC)
	$(START_BUILD)
	$(REMOVE)/fontconfig-$(FONTCONFIG_VER)
	$(UNTAR)/$(FONTCONFIG_SRC)
	$(CHDIR)/fontconfig-$(FONTCONFIG_VER); \
		$(call apply_patches, $(FONTCONFIG_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--with-freetype-config=$(HOST_DIR)/bin/freetype-config \
			--with-expat-includes=$(TARGET_DIR)/usr/include \
			--with-expat-lib=$(TARGET_DIR)/usr/lib \
			--sysconfdir=/etc \
			--disable-docs \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libfontconfig.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fontconfig.pc
	$(REMOVE)/fontconfig-$(FONTCONFIG_VER)
	$(TOUCH)

#
# libdvdcss
#
LIBDVDCSS_VER = 1.2.13
LIBDVDCSS_SRC = libdvdcss-$(LIBDVDCSS_VER).tar.bz2
LIBDVDCSS_URL = https://download.videolan.org/pub/libdvdcss/$(LIBDVDCSS_VER)

$(ARCHIVE)/$(LIBDVDCSS_SRC):
	$(DOWNLOAD) $(LIBDVDCSS_URL)/$(LIBDVDCSS_SRC)

$(D)/libdvdcss: $(D)/bootstrap $(ARCHIVE)/$(LIBDVDCSS_SRC)
	$(START_BUILD)
	$(REMOVE)/libdvdcss-$(LIBDVDCSS_VER)
	$(UNTAR)/$(LIBDVDCSS_SRC)
	$(CHDIR)/libdvdcss-$(LIBDVDCSS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-doc \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdvdcss.pc
	$(REWRITE_LIBTOOL)/libdvdcss.la
	$(REMOVE)/libdvdcss-$(LIBDVDCSS_VER)
	$(TOUCH)

#
# libdvdnav
#
LIBDVDNAV_VER = 4.2.1
LIBDVDNAV_SRC = libdvdnav-$(LIBDVDNAV_VER).tar.xz
LIBDVDNAV_URL = http://dvdnav.mplayerhq.hu/releases

LIBDVDNAV_PATCH = libdvdnav-$(LIBDVDNAV_VER).patch

$(ARCHIVE)/$(LIBDVDNAV_SRC):
	$(DOWNLOAD) $(LIBDVDNAV_URL)/$(LIBDVDNAV_SRC)

$(D)/libdvdnav: $(D)/bootstrap $(D)/libdvdread $(ARCHIVE)/$(LIBDVDNAV_SRC)
	$(START_BUILD)
	$(REMOVE)/libdvdnav-$(LIBDVDNAV_VER)
	$(UNTAR)/$(LIBDVDNAV_SRC)
	$(CHDIR)/libdvdnav-$(LIBDVDNAV_VER); \
		$(call apply_patches, $(LIBDVDNAV_PATCH)); \
		$(BUILDENV) \
		libtoolize --copy --force --quiet --ltdl; \
		./autogen.sh \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--enable-static \
			--enable-shared \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dvdnav.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dvdnavmini.pc
	$(REWRITE_LIBTOOL)/libdvdnav.la
	$(REWRITE_LIBTOOL)/libdvdnavmini.la
	$(REMOVE)/libdvdnav-$(LIBDVDNAV_VER)
	$(TOUCH)

#
# libdvdread
#
LIBDVDREAD_VER = 4.9.9
LIBDVDREAD_SRC = libdvdread-$(LIBDVDREAD_VER).tar.xz
LIBDVDREAD_URL = http://dvdnav.mplayerhq.hu/releases

LIBDVDREAD_PATCH = libdvdread-$(LIBDVDREAD_VER).patch

$(ARCHIVE)/$(LIBDVDREAD_SRC):
	$(DOWNLOAD) $(LIBDVDREAD_URL)/$(LIBDVDREAD_SRC)

$(D)/libdvdread: $(D)/bootstrap $(ARCHIVE)/$(LIBDVDREAD_SRC)
	$(START_BUILD)
	$(REMOVE)/libdvdread-$(LIBDVDREAD_VER)
	$(UNTAR)/$(LIBDVDREAD_SRC)
	$(CHDIR)/libdvdread-$(LIBDVDREAD_VER); \
		$(call apply_patches, $(LIBDVDREAD_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-static \
			--enable-shared \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dvdread.pc
	$(REWRITE_LIBTOOL)/libdvdread.la
	$(REMOVE)/libdvdread-$(LIBDVDREAD_VER)
	$(TOUCH)

#
# libdreamdvd
#
LIBDREAMDVD_SRC = libdreamdvd.git
LIBDREAMDVD_URL = https://github.com/mirakels/libdreamdvd.git

LIBDREAMDVD_PATCH = libdreamdvd-1.0-sh4-support.patch libdreamdvd.patch

$(ARCHIVE)/$(LIBDREAMDVD_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(LIBDREAMDVD_SRC) ]; then \
		cd $(ARCHIVE)/$(LIBDREAMDVD_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(LIBDREAMDVD_URL) $(LIBDREAMDVD_SRC); \
	fi

$(D)/libdreamdvd: $(D)/bootstrap $(D)/libdvdnav $(ARCHIVE)/$(LIBDREAMDVD_SRC)
	$(START_BUILD)
	$(REMOVE)/libdreamdvd
	cp -ra $(ARCHIVE)/$(LIBDREAMDVD_SRC) $(BUILD_TMP)/libdreamdvd
	$(CHDIR)/libdreamdvd; \
		$(call apply_patches, $(LIBDREAMDVD_PATCH)); \
		$(BUILDENV) \
		libtoolize --copy --ltdl --force --quiet; \
		autoreconf --verbose --force --install; \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdreamdvd.pc
	$(REWRITE_LIBTOOL)/libdreamdvd.la
	$(REMOVE)/libdreamdvd
	$(TOUCH)

#
# libass
#
LIBASS_VER = 0.14.0
LIBASS_SRC = libass-$(LIBASS_VER).tar.xz
LIBASS_URL = https://github.com/libass/libass/releases/download/$(LIBASS_VER)

LIBASS_PATCH = libass-$(LIBASS_VER).patch

$(ARCHIVE)/$(LIBASS_SRC):
	$(DOWNLOAD) $(LIBASS_URL)/$(LIBASS_SRC)

$(D)/libass: $(D)/bootstrap $(D)/freetype $(D)/libfribidi $(ARCHIVE)/$(LIBASS_SRC)
	$(START_BUILD)
	$(REMOVE)/libass-$(LIBASS_VER)
	$(UNTAR)/$(LIBASS_SRC)
	$(CHDIR)/libass-$(LIBASS_VER); \
		$(call apply_patches, $(LIBASS_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-static \
			--disable-test \
			--disable-fontconfig \
			--disable-harfbuzz \
			--disable-require-system-font-provider \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libass.pc
	$(REWRITE_LIBTOOL)/libass.la
	$(REMOVE)/libass-$(LIBASS_VER)
	$(TOUCH)

#
# sqlite
#
SQLITE_VER = 3160100
SQLITE_SRC = sqlite-autoconf-$(SQLITE_VER).tar.gz
SQLITE_URL = http://www.sqlite.org/2017

$(ARCHIVE)/$(SQLITE_SRC):
	$(DOWNLOAD) $(SQLITE_URL)/$(SQLITE_SRC)

$(D)/sqlite: $(D)/bootstrap $(ARCHIVE)/$(SQLITE_SRC)
	$(START_BUILD)
	$(REMOVE)/sqlite-autoconf-$(SQLITE_VER)
	$(UNTAR)/$(SQLITE_SRC)
	$(CHDIR)/sqlite-autoconf-$(SQLITE_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/sqlite3.pc
	$(REWRITE_LIBTOOL)/libsqlite3.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,sqlite3)
	$(REMOVE)/sqlite-autoconf-$(SQLITE_VER)
	$(TOUCH)

#
# libsoup
#
LIBSOUP_VER_MAJOR = 2.64
LIBSOUP_VER_MINOR = 0
LIBSOUP_VER = $(LIBSOUP_VER_MAJOR).$(LIBSOUP_VER_MINOR)
LIBSOUP_SRC = libsoup-$(LIBSOUP_VER).tar.xz
LIBSOUP_URL = https://download.gnome.org/sources/libsoup/$(LIBSOUP_VER_MAJOR)

$(ARCHIVE)/$(LIBSOUP_SRC):
	$(DOWNLOAD) $(LIBSOUP_URL)/$(LIBSOUP_SRC)

$(D)/libsoup: $(D)/bootstrap $(D)/sqlite $(D)/libxml2 $(D)/libglib2 $(D)/libpsl $(ARCHIVE)/$(LIBSOUP_SRC)
	$(START_BUILD)
	$(REMOVE)/libsoup-$(LIBSOUP_VER)
	$(UNTAR)/$(LIBSOUP_SRC)
	$(CHDIR)/libsoup-$(LIBSOUP_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--disable-more-warnings \
			--without-gnome \
			--without-gssapi \
			--disable-gtk-doc \
			--disable-gtk-doc-html \
			--disable-gtk-doc-pdf \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) itlocaledir=$$(TARGET_DIR)/.remove
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libsoup-2.4.pc
	$(REWRITE_LIBTOOL)/libsoup-2.4.la
	$(REMOVE)/libsoup-$(LIBSOUP_VER)
	$(TOUCH)
	
#
# libpsl
#
LIBPSL_VER_MAJOR = 0.20
LIBPSL_VER_MINOR = 2
LIBPSL_VER = $(LIBPSL_VER_MAJOR).$(LIBPSL_VER_MINOR)
LIBPSL_SRC = libpsl.git
LIBPSL_URL = https://github.com/rockdaboot/libpsl.git

LIBPSL_PATCH =

$(ARCHIVE)/$(LIBPSL_SRC):
	set -e;
	if [ -d $(ARCHIVE)/$(LIBPSL_SRC) ]; then \
		cd $(ARCHIVE)/$(LIBPSL_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(LIBPSL_URL) $(LIBPSL_SRC); \
	fi

$(D)/libpsl: $(D)/bootstrap $(ARCHIVE)/$(LIBPSL_SRC)
	$(START_BUILD)
	$(REMOVE)/libpsl
	cp -ra $(ARCHIVE)/$(LIBPSL_SRC) $(BUILD_TMP)/libpsl
	$(CHDIR)/libpsl; \
		$(call apply_patches, $(LIBPSL_PATCH)); \
		$(BUILDENV) \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--enable-man=no \
			--enable-gtk-doc=no \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libpsl.pc
	$(REWRITE_LIBTOOL)/libpsl.la
	$(REMOVE)/libpsl
	$(TOUCH)

#
# libxml2
#
LIBXML2_MAJOR = 2.14
LIBXML2_MINOR = 5
LIBXML2_VER = $(LIBXML2_MAJOR).$(LIBXML2_MINOR)
LIBXML2_SRC = libxml2-$(LIBXML2_VER).tar.xz
LIBXML2_URL = https://download.gnome.org/sources/libxml2/$(LIBXML2_MAJOR)

LIBXML2_PATCH = libxml2-$(LIBXML2_VER).patch

$(ARCHIVE)/$(LIBXML2_SRC):
	$(DOWNLOAD) $(LIBXML2_URL)/$(LIBXML2_SRC)

ifeq ($(BOXARCH), sh4)
LIBXML2_CONF_OPTS += --without-iconv
LIBXML2_CONF_OPTS += --with-minimum
LIBXML2_CONF_OPTS += --with-schematron=yes
endif

$(D)/libxml2: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(LIBXML2_SRC)
	$(START_BUILD)
	$(REMOVE)/libxml2-$(LIBXML2_VER).tar.gz
	$(UNTAR)/$(LIBXML2_SRC)
	$(CHDIR)/libxml2-$(LIBXML2_VER); \
		$(call apply_patches, $(LIBXML2_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-shared \
			--disable-static \
			--without-python \
			--without-catalog \
			--without-debug \
			--without-legacy \
			--without-docbook \
			--without-mem-debug \
			--without-lzma \
			--with-zlib \
			$(LIBXML2_CONF_OPTS) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR); \
		if [ -d $(TARGET_DIR)/usr/include/libxml2/libxml ] ; then \
			ln -sf ./libxml2/libxml $(TARGET_DIR)/usr/include/libxml; \
		fi;
	mv $(TARGET_DIR)/usr/bin/xml2-config $(HOST_DIR)/bin
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libxml-2.0.pc
	$(REWRITE_PKGCONF) $(HOST_DIR)/bin/xml2-config
	$(REWRITE_LIBTOOL)/libxml2.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,xmlcatalog xmllint)
	rm -rf $(TARGET_LIB_DIR)/xml2Conf.sh
	rm -rf $(TARGET_LIB_DIR)/cmake
	$(REMOVE)/libxml2-$(LIBXML2_VER)
	$(TOUCH)

#
# libxslt
#
LIBXSLT_VER = 1.1.32
LIBXSLT_SRC = libxslt-$(LIBXSLT_VER).tar.gz
LIBXSLT_URL = ftp://xmlsoft.org/libxml2

$(ARCHIVE)/$(LIBXSLT_SRC):
	$(DOWNLOAD) $(LIBXSLT_URL)/$(LIBXSLT_SRC)

$(D)/libxslt: $(D)/bootstrap $(D)/libxml2 $(ARCHIVE)/$(LIBXSLT_SRC)
	$(START_BUILD)
	$(REMOVE)/libxslt-$(LIBXSLT_VER)
	$(UNTAR)/$(LIBXSLT_SRC)
	$(CHDIR)/libxslt-$(LIBXSLT_VER); \
		$(CONFIGURE) \
			CPPFLAGS="$(CPPFLAGS) -I$(TARGET_DIR)/usr/include/libxml2" \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-shared \
			--disable-static \
			--without-python \
			--without-crypto \
			--without-debug \
			--without-mem-debug \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	mv $(TARGET_DIR)/usr/bin/xslt-config $(HOST_DIR)/bin
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libexslt.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libxslt.pc
	$(REWRITE_PKGCONF) $(HOST_DIR)/bin/xslt-config
	$(REWRITE_LIBTOOL)/libexslt.la
	$(REWRITE_LIBTOOL)/libxslt.la
	$(REWRITE_LIBTOOLDEP)/libexslt.la
ifeq ($(BOXARCH), sh4)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,xsltproc xslt-config)
endif
	rm -rf $(TARGETLIB)/xsltConf.sh
	rm -rf $(TARGETLIB)/libxslt-plugins/
	$(REMOVE)/libxslt-$(LIBXSLT_VER)
	$(TOUCH)

#
# libpopt
#
LIBPOPT_VER = 1.19
LIBPOPT_SRC = popt-$(LIBPOPT_VER).tar.gz
LIBPOPT_URL = http://ftp.rpm.org/popt/releases/popt-1.x

$(ARCHIVE)/$(LIBPOPT_SRC):
	$(DOWNLOAD) $(LIBPOPT_URL)/$(LIBPOPT_SRC)

$(D)/libpopt: $(D)/bootstrap $(ARCHIVE)/$(LIBPOPT_SRC)
	$(START_BUILD)
	$(REMOVE)/popt-$(LIBPOPT_VER)
	$(UNTAR)/$(LIBPOPT_SRC)
	$(CHDIR)/popt-$(LIBPOPT_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-static \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/popt.pc
	$(REWRITE_LIBTOOL)/libpopt.la
	$(REMOVE)/popt-$(LIBPOPT_VER)
	$(TOUCH)

#
# libroxml
#
LIBROXML_VER = 2.3.0
LIBROXML_SRC = libroxml-$(LIBROXML_VER).tar.gz
LIBROXML_URL = http://download.libroxml.net/pool/v2.x

$(ARCHIVE)/$(LIBROXML_SRC):
	$(DOWNLOAD) $(LIBROXML_URL)/$(LIBROXML_SRC)

$(D)/libroxml: $(D)/bootstrap $(ARCHIVE)/$(LIBROXML_SRC)
	$(START_BUILD)
	$(REMOVE)/libroxml-$(LIBROXML_VER)
	$(UNTAR)/$(LIBROXML_SRC)
	$(CHDIR)/libroxml-$(LIBROXML_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--disable-static \
			--disable-roxml \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libroxml.pc
	$(REWRITE_LIBTOOL)/libroxml.la
	$(REMOVE)/libroxml-$(LIBROXML_VER)
	$(TOUCH)

#
# pugixml
#
PUGIXML_VER = 1.9
PUGIXML_SRC = pugixml-$(PUGIXML_VER).tar.gz
PUGIXML_URL = https://github.com/zeux/pugixml/releases/download/v$(PUGIXML_VER)

PUGIXML_PATCH = pugixml-$(PUGIXML_VER)-config.patch

$(ARCHIVE)/$(PUGIXML_SRC):
	$(DOWNLOAD) $(PUGIXML_URL)/$(PUGIXML_SRC)

$(D)/pugixml: $(D)/bootstrap $(ARCHIVE)/$(PUGIXML_SRC)
	$(START_BUILD)
	$(REMOVE)/pugixml-$(PUGIXML_VER)
	$(UNTAR)/$(PUGIXML_SRC)
	$(CHDIR)/pugixml-$(PUGIXML_VER); \
		$(call apply_patches, $(PUGIXML_PATCH)); \
		cmake  --no-warn-unused-cli \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DBUILD_SHARED_LIBS=ON \
			-DCMAKE_BUILD_TYPE=Linux \
			-DCMAKE_C_COMPILER=$(TARGET)-gcc \
			-DCMAKE_CXX_COMPILER=$(TARGET)-g++ \
			-DCMAKE_C_FLAGS="-pipe -Os" \
			-DCMAKE_CXX_FLAGS="-pipe -Os" \
			| tail -n +90 \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/pugixml-$(PUGIXML_VER)
	cd $(TARGET_DIR) && rm -rf usr/lib/cmake
	$(TOUCH)

#
# graphlcd
#
GRAPHLCD_VER = 55d4bd8
GRAPHLCD_SRC = graphlcd-git-$(GRAPHLCD_VER).tar.bz2
GRAPHLCD_URL = https://github.com/Duckbox-Developers/graphlcd.git

GRAPHLCD_PATCH = graphlcd-git-$(GRAPHLCD_VER).patch

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo4k vuduo4kse vuuno4kse vuultimo4k vusolo4k))
GRAPHLCD_PATCH += graphlcd-vuplus4k_1.patch
GRAPHLCD_PATCH += graphlcd-vuplus4k_2.patch
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), dm8000 dm7080))
GRAPHLCD_PATCH += graphlcd-dreambox_grautec.patch
GRAPHLCD_PATCH += graphlcd-dm8000.patch
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), dm900 dm920))
GRAPHLCD_PATCH += graphlcd-dreambox.patch
GRAPHLCD_PATCH += graphlcd-dm900.patch
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vuduo2))
GRAPHLCD_PATCH += graphlcd-vuplus4k_1.patch
GRAPHLCD_PATCH += graphlcd-vuduo2.patch
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), e4hdultra))
GRAPHLCD_PATCH += graphlcd-e4hdultra.patch
GRAPHLCD_PATCH += graphlcd-framebuffer.patch
endif

$(ARCHIVE)/$(GRAPHLCD_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(GRAPHLCD_URL) $(GRAPHLCD_VER) $(notdir $@) $(ARCHIVE)

$(D)/graphlcd: $(D)/bootstrap $(D)/freetype $(D)/libusb $(D)/libusb_compat $(ARCHIVE)/$(GRAPHLCD_SRC)
	$(START_BUILD)
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
	$(UNTAR)/$(GRAPHLCD_SRC)
	$(CHDIR)/graphlcd-git-$(GRAPHLCD_VER); \
		$(call apply_patches, $(GRAPHLCD_PATCH)); \
		$(MAKE) -C glcdgraphics all TARGET=$(TARGET)- DESTDIR=$(TARGET_DIR); \
		$(MAKE) -C glcddrivers all TARGET=$(TARGET)- DESTDIR=$(TARGET_DIR); \
		$(MAKE) -C glcdgraphics install DESTDIR=$(TARGET_DIR); \
		$(MAKE) -C glcddrivers install DESTDIR=$(TARGET_DIR); \
		cp -a graphlcd.conf $(TARGET_DIR)/etc
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
	$(TOUCH)

#
# libdpf
#
LIBDPF_VER = 62c8fd0
LIBDPF_SRC = dpf-ax-git-$(LIBDPF_VER).tar.bz2
LIBDPF_URL = https://github.com/MaxWiesel/dpf-ax.git

LIBDPF_PATCH = libdpf-crossbuild.patch

$(ARCHIVE)/$(LIBDPF_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LIBDPF_URL) $(LIBDPF_VER) $(notdir $@) $(ARCHIVE)

$(D)/libdpf: $(D)/bootstrap $(D)/libusb_compat $(ARCHIVE)/$(LIBDPF_SRC)
	$(START_BUILD)
	$(REMOVE)/dpf-ax-git-$(LIBDPF_VER)
	$(UNTAR)/$(LIBDPF_SRC)
	$(CHDIR)/dpf-ax-git-$(LIBDPF_VER)/dpflib; \
		$(call apply_patches, $(LIBDPF_PATCH)); \
		make libdpf.a CC=$(TARGET)-gcc PREFIX=$(TARGET_DIR)/usr; \
		mkdir -p $(TARGET_INCLUDE_DIR)/libdpf; \
		cp dpf.h $(TARGET_INCLUDE_DIR)/libdpf/libdpf.h; \
		cp ../include/spiflash.h $(TARGET_INCLUDE_DIR)/libdpf/; \
		cp ../include/usbuser.h $(TARGET_INCLUDE_DIR)/libdpf/; \
		cp libdpf.a $(TARGET_LIB_DIR)/
	$(REMOVE)/dpf-ax-git-$(LIBDPF_VER)
	$(TOUCH)

#
# lcd4linux
#
LCD4LINUX_VER = 07ef2dd
LCD4LINUX_SRC = lcd4linux-git-$(LCD4LINUX_VER).tar.bz2
LCD4LINUX_URL = https://github.com/TangoCash/lcd4linux.git

LCD4LINUX_PATCH = lcd4linux-widget.patch
ifeq ($(BOXTYPE), vusolo4k)
LCD4LINUX_PATCH += lcd4linux-vusolo4k.patch
LCD4LINUX_DRV = ,VUSOLO4K
endif

$(ARCHIVE)/$(LCD4LINUX_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LCD4LINUX_URL) $(LCD4LINUX_VER) $(notdir $@) $(ARCHIVE)

$(D)/lcd4linux: $(D)/bootstrap $(D)/libusb_compat $(D)/gd $(D)/libusb $(D)/libdpf $(ARCHIVE)/$(LCD4LINUX_SRC)
	$(START_BUILD)
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
	$(UNTAR)/$(LCD4LINUX_SRC)
	$(CHDIR)/lcd4linux-git-$(LCD4LINUX_VER); \
		$(call apply_patches, $(LCD4LINUX_PATCH)); \
		$(BUILDENV) ./bootstrap; \
		$(BUILDENV) ./configure $(CONFIGURE_OPTS) \
			--prefix=/usr \
			--with-drivers='DPF,SamsungSPF$(LCD4LINUX_DRV),PNG' \
			--with-plugins='all,!apm,!asterisk,!dbus,!dvb,!gps,!hddtemp,!huawei,!imon,!isdn,!kvv,!mpd,!mpris_dbus,!mysql,!pop3,!ppp,!python,!qnaplog,!raspi,!sample,!seti,!w1retap,!wireless,!xmms' \
			--without-ncurses \
		; \
		$(MAKE) vcs_version all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/lcd4linux $(TARGET_DIR)/etc/init.d/
	install -D -m 0600 $(SKEL_ROOT)/etc/lcd4linux.conf $(TARGET_DIR)/etc/lcd4linux.conf
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
	$(TOUCH)

#
# gd
#
GD_VER = 2.2.5
GD_SRC = libgd-$(GD_VER).tar.xz
GD_URL = https://github.com/libgd/libgd/releases/download/gd-$(GD_VER)

$(ARCHIVE)/$(GD_SRC):
	$(DOWNLOAD) $(GD_URL)/$(GD_SRC)

$(D)/gd: $(D)/bootstrap $(D)/libpng $(D)/libjpeg $(D)/freetype $(ARCHIVE)/$(GD_SRC)
	$(START_BUILD)
	$(REMOVE)/libgd-$(GD_VER)
	$(UNTAR)/$(GD_SRC)
	$(CHDIR)/libgd-$(GD_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--bindir=/.remove \
			--without-fontconfig \
			--without-xpm \
			--without-x \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libgd.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gdlib.pc
	$(REMOVE)/libgd-$(GD_VER)
	$(TOUCH)

#
# libusb
#
LIBUSB_VER = 1.0.22
LIBUSB_VER_MAJOR = 1.0
LIBUSB_SRC = libusb-$(LIBUSB_VER).tar.bz2
LIBUSB_URL = https://github.com//libusb/libusb/releases/download/v$(LIBUSB_VER)

LIBUSB_PATCH = libusb-$(LIBUSB_VER).patch
ifeq ($(BOXARCH), sh4)
LIBUSB_PATCH += libusb-1.0.22-sh4-clock_gettime.patch
endif
LIBUSB_PATCH += libusb-$(LIBUSB_VER)-automake-version.patch

$(ARCHIVE)/$(LIBUSB_SRC):
	$(DOWNLOAD) $(LIBUSB_URL)/$(LIBUSB_SRC)

$(D)/libusb: $(D)/bootstrap $(ARCHIVE)/$(LIBUSB_SRC)
	$(START_BUILD)
	$(REMOVE)/libusb-$(LIBUSB_VER)
	$(UNTAR)/$(LIBUSB_SRC)
	$(CHDIR)/libusb-$(LIBUSB_VER); \
		rm aclocal.m4; \
		rm compile; \
		rm config.*; \
		rm configure; \
		rm depcomp; \
		rm install-sh; \
		$(call apply_patches, $(LIBUSB_PATCH)); \
		chmod +x autogen.sh; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-static \
			--disable-log \
			--disable-debug-log \
			--disable-udev \
			--disable-examples-build \
		; \
		$(MAKE) ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libusb-1.0.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libusb-1.0.pc
	$(REMOVE)/libusb-$(LIBUSB_VER)
	$(TOUCH)

#
# libusb_compat
#
LIBUSB_COMPAT_VER = 0.1.5
LIBUSB_COMPAT_SRC = libusb-compat-$(LIBUSB_COMPAT_VER).tar.bz2
LIBUSB_COMPAT_URL = https://sourceforge.net/projects/libusb/files/libusb-compat-0.1/libusb-compat-$(LIBUSB_COMPAT_VER)

$(ARCHIVE)/$(LIBUSB_COMPAT_SRC):
	$(DOWNLOAD) $(LIBUSB_COMPAT_URL)/$(LIBUSB_COMPAT_SRC)

$(D)/libusb_compat: $(D)/bootstrap $(D)/libusb $(ARCHIVE)/$(LIBUSB_COMPAT_SRC)
	$(START_BUILD)
	$(REMOVE)/libusb-compat-$(LIBUSB_COMPAT_VER)
	$(UNTAR)/$(LIBUSB_COMPAT_SRC)
	$(CHDIR)/libusb-compat-$(LIBUSB_COMPAT_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-log \
			--disable-debug-log \
			--disable-examples-build \
		; \
		$(MAKE) ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(TARGET_DIR)/usr/bin/libusb-config
	$(REWRITE_LIBTOOL)/libusb.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libusb.pc
	$(REMOVE)/libusb-compat-$(LIBUSB_COMPAT_VER)
	$(TOUCH)

#
# alsa-lib
#
ALSA_LIB_VER = 1.1.7
ALSA_LIB_SRC = alsa-lib-$(ALSA_LIB_VER).tar.bz2
ALSA_LIB_URL = ftp://ftp.alsa-project.org/pub/lib

ALSA_LIB_PATCH  = alsa-lib-$(ALSA_LIB_VER).patch
ALSA_LIB_PATCH += alsa-lib-$(ALSA_LIB_VER)-link_fix.patch

$(ARCHIVE)/$(ALSA_LIB_SRC):
	$(DOWNLOAD) $(ALSA_LIB_URL)/$(ALSA_LIB_SRC)

$(D)/alsa_lib: $(D)/bootstrap $(ARCHIVE)/$(ALSA_LIB_SRC)
	$(START_BUILD)
	$(REMOVE)/alsa-lib-$(ALSA_LIB_VER)
	$(UNTAR)/$(ALSA_LIB_SRC)
	$(CHDIR)/alsa-lib-$(ALSA_LIB_VER); \
		$(call apply_patches, $(ALSA_LIB_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--with-alsa-devdir=/dev/snd/ \
			--with-plugindir=/usr/lib/alsa \
			--without-debug \
			--with-debug=no \
			--with-versioned=no \
			--enable-symbolic-functions \
			--disable-aload \
			--disable-rawmidi \
			--disable-resmgr \
			--disable-old-symbols \
			--disable-alisp \
			--disable-hwdep \
			--disable-python \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/alsa.pc
	$(REWRITE_LIBTOOL)/libasound.la
	$(REMOVE)/alsa-lib-$(ALSA_LIB_VER)
	$(TOUCH)

#
# alsa-utils
#
ALSA_UTILS_VER = 1.1.7
ALSA_UTILS_SRC = alsa-utils-$(ALSA_UTILS_VER).tar.bz2
ALSA_UTILS_URL = ftp://ftp.alsa-project.org/pub/utils

$(ARCHIVE)/$(ALSA_UTILS_SRC):
	$(DOWNLOAD) $(ALSA_UTILS_URL)/$(ALSA_UTILS_SRC)

$(D)/alsa_utils: $(D)/bootstrap $(D)/alsa_lib $(ARCHIVE)/$(ALSA_UTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/alsa-utils-$(ALSA_UTILS_VER)
	$(UNTAR)/$(ALSA_UTILS_SRC)
	$(CHDIR)/alsa-utils-$(ALSA_UTILS_VER); \
		sed -ir -r "s/(alsamixer|amidi|aplay|iecset|speaker-test|seq|alsactl|alsaucm|topology)//g" Makefile.am ;\
		autoreconf -fi -I $(TARGET_DIR)/usr/share/aclocal; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--with-curses=ncurses \
			--disable-bat \
			--disable-nls \
			--disable-alsatest \
			--disable-alsaconf \
			--disable-alsaloop \
			--disable-alsamixer \
			--disable-xmlto \
			--disable-rst2man \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/alsa-utils-$(ALSA_UTILS_VER)
	install -m 755 $(SKEL_ROOT)/etc/init.d/amixer $(TARGET_DIR)/etc/init.d/amixer
	install -m 644 $(SKEL_ROOT)/etc/amixer.conf $(TARGET_DIR)/etc/amixer.conf
	install -m 644 $(SKEL_ROOT)/etc/asound.conf $(TARGET_DIR)/etc/asound.conf
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,aserver)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,alsa-info.sh)
	$(TOUCH)

#
# libopenthreads
#
LIBOPENTHREADS_VER = 3.2
LIBOPENTHREADS_SRC = OpenThreads-$(LIBOPENTHREADS_VER).tar.gz
LIBOPENTHREADS_URL = https://sourceforge.net/projects/mxedeps/files

ifeq ($(BOXARCH), $(filter $(BOXARCH), sh4 mips arm))
LIBOPENTHREADS_PATCH = libopenthreads-$(LIBOPENTHREADS_VER).patch
endif

$(ARCHIVE)/$(LIBOPENTHREADS_SRC):
	$(DOWNLOAD) $(LIBOPENTHREADS_URL)/$(LIBOPENTHREADS_SRC)

$(D)/libopenthreads: $(D)/bootstrap $(ARCHIVE)/$(LIBOPENTHREADS_SRC)
	$(START_BUILD)
	$(REMOVE)/OpenThreads-$(LIBOPENTHREADS_VER)
	$(UNTAR)/$(LIBOPENTHREADS_SRC)
	$(CHDIR)/OpenThreads-$(LIBOPENTHREADS_VER); \
		$(call apply_patches, $(LIBOPENTHREADS_PATCH)); \
		echo "# dummy file to prevent warning message" > examples/CMakeLists.txt; \
		cmake . -DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_SYSTEM_NAME="Linux" \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_C_COMPILER="$(TARGET)-gcc" \
			-DCMAKE_CXX_COMPILER="$(TARGET)-g++" \
			-D_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS_EXITCODE=1 \
			-D_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS_EXITCODE__TRYRUN_OUTPUT=1 \
		; \
		find . -name cmake_install.cmake -print0 | xargs -0 \
		sed -i 's@SET(CMAKE_INSTALL_PREFIX "/usr/local")@SET(CMAKE_INSTALL_PREFIX "")@'; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)	
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/openthreads.pc
	$(REMOVE)/OpenThreads-$(LIBOPENTHREADS_VER)
	$(TOUCH)

#
# librtmp
#
LIBRTMP_VER = ad70c64
LIBRTMP_SRC = rtmpdump-git-$(LIBRTMP_VER).tar.bz2
LIBRTMP_URL = https://github.com/oe-alliance/rtmpdump.git

LIBRTMP_PATCH = rtmpdump-git-$(LIBRTMP_VER).patch

$(ARCHIVE)/$(LIBRTMP_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LIBRTMP_URL) $(LIBRTMP_VER) $(notdir $@) $(ARCHIVE)

$(D)/librtmp: $(D)/bootstrap $(D)/zlib $(D)/openssl $(ARCHIVE)/$(LIBRTMP_SRC)
	$(START_BUILD)
	$(REMOVE)/rtmpdump-git-$(LIBRTMP_VER)
	$(UNTAR)/$(LIBRTMP_SRC)
	$(CHDIR)/rtmpdump-git-$(LIBRTMP_VER); \
		$(call apply_patches, $(LIBRTMP_PATCH)); \
		$(MAKE) CROSS_COMPILE=$(TARGET)- XCFLAGS="-I$(TARGET_INCLUDE_DIR) -L$(TARGET_LIB_DIR)" LDFLAGS="-L$(TARGET_LIB_DIR)"; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR) MANDIR=$(TARGET_DIR)/.remove
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/librtmp.pc
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,rtmpgw rtmpsrv rtmpsuck)
	$(REMOVE)/rtmpdump-git-$(LIBRTMP_VER)
	$(TOUCH)

#
# libdvbsi++
#
LIBDVBSI_VER = f3c40ea
LIBDVBSI_SRC = libdvbsi-git-$(LIBDVBSI_VER).tar.bz2
LIBDVBSI_URL = https://github.com/OpenVisionE2/libdvbsi.git

#LIBDVBSI_PATCH = libdvbsi-git-$(LIBDVBSI_VER).patch

$(ARCHIVE)/$(LIBDVBSI_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LIBDVBSI_URL) $(LIBDVBSI_VER) $(notdir $@) $(ARCHIVE)

$(D)/libdvbsi: $(D)/bootstrap $(ARCHIVE)/$(LIBDVBSI_SRC)
	$(START_BUILD)
	$(REMOVE)/libdvbsi-git-$(LIBDVBSI_VER)
	$(UNTAR)/$(LIBDVBSI_SRC)
	$(CHDIR)/libdvbsi-git-$(LIBDVBSI_VER); \
		$(call apply_patches, $(LIBDVBSI_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdvbsi++.pc
	$(REWRITE_LIBTOOL)/libdvbsi++.la
	$(REMOVE)/libdvbsi-git-$(LIBDVBSI_VER)
	$(TOUCH)

#
# libmodplug
#
LIBMODPLUG_VER = 0.8.8.4
LIBMODPLUG_SRC = libmodplug-$(LIBMODPLUG_VER).tar.gz
LIBMODPLUG_URL = https://sourceforge.net/projects/modplug-xmms/files/libmodplug/$(LIBMODPLUG_VER)

$(ARCHIVE)/$(LIBMODPLUG_SRC):
	$(DOWNLOAD) $(LIBMODPLUG_URL)/$(LIBMODPLUG_SRC)

$(D)/libmodplug: $(D)/bootstrap $(ARCHIVE)/$(LIBMODPLUG_SRC)
	$(START_BUILD)
	$(REMOVE)/libmodplug-$(LIBMODPLUG_VER)
	$(UNTAR)/$(LIBMODPLUG_SRC)
	$(CHDIR)/libmodplug-$(LIBMODPLUG_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libmodplug.pc
	$(REWRITE_LIBTOOL)/libmodplug.la
	$(REMOVE)/libmodplug-$(LIBMODPLUG_VER)
	$(TOUCH)

#
# lzo
#
LZO_VER = 2.10
LZO_SRC = lzo-$(LZO_VER).tar.gz
LZO_URL = https://www.oberhumer.com/opensource/lzo/download

$(ARCHIVE)/$(LZO_SRC):
	$(DOWNLOAD) $(LZO_URL)/$(LZO_SRC)

$(D)/lzo: $(D)/bootstrap $(ARCHIVE)/$(LZO_SRC)
	$(START_BUILD)
	$(REMOVE)/lzo-$(LZO_VER)
	$(UNTAR)/$(LZO_SRC)
	$(CHDIR)/lzo-$(LZO_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--docdir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/lzo2.pc
	$(REWRITE_LIBTOOL)/liblzo2.la
	$(REMOVE)/lzo-$(LZO_VER)
	$(TOUCH)

#
# minidlna
#
MINIDLNA_VER = 1.1.5
MINIDLNA_SRC = minidlna-$(MINIDLNA_VER).tar.gz
MINIDLNA_URL = https://sourceforge.net/projects/minidlna/files/minidlna/$(MINIDLNA_VER)

MINIDLNA_PATCH = minidlna-$(MINIDLNA_VER).patch

$(ARCHIVE)/$(MINIDLNA_SRC):
	$(DOWNLOAD) $(MINIDLNA_URL)/$(MINIDLNA_SRC)

$(D)/minidlna: $(D)/bootstrap $(D)/zlib $(D)/sqlite $(D)/libexif $(D)/libjpeg $(D)/libid3tag $(D)/libogg $(D)/libvorbis $(D)/flac $(D)/ffmpeg $(ARCHIVE)/$(MINIDLNA_SRC)
	$(START_BUILD)
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
	$(UNTAR)/$(MINIDLNA_SRC)
	$(CHDIR)/minidlna-$(MINIDLNA_VER); \
		$(call apply_patches, $(MINIDLNA_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
	$(TOUCH)

#
# libexif
#
LIBEXIF_VER = 0.6.21
LIBEXIF_SRC = libexif-$(LIBEXIF_VER).tar.gz
LIBEXIF_URL = https://sourceforge.net/projects/libexif/files/libexif/$(LIBEXIF_VER)

$(ARCHIVE)/$(LIBEXIF_SRC):
	$(DOWNLOAD) $(LIBEXIF_URL)/$(LIBEXIF_SRC)

$(D)/libexif: $(D)/bootstrap $(ARCHIVE)/$(LIBEXIF_SRC)
	$(START_BUILD)
	$(REMOVE)/libexif-$(LIBEXIF_VER)
	$(UNTAR)/$(LIBEXIF_SRC)
	$(CHDIR)/libexif-$(LIBEXIF_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libexif.pc
	$(REWRITE_LIBTOOL)/libexif.la
	$(REMOVE)/libexif-$(LIBEXIF_VER)
	$(TOUCH)

#
# libupnp
#
LIBUPNP_VER = 1.6.25
LIBUPNP_SRC = libupnp-$(LIBUPNP_VER).tar.bz2
LIBUPNP_URL = https://sourceforge.net/projects/pupnp/files/pupnp/libUPnP\ $(LIBUPNP_VER)

$(ARCHIVE)/$(LIBUPNP_SRC):
	$(DOWNLOAD) $(LIBUPNP_URL)/$(LIBUPNP_SRC)

$(D)/libupnp: $(D)/bootstrap $(ARCHIVE)/$(LIBUPNP_SRC)
	$(START_BUILD)
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
	$(UNTAR)/$(LIBUPNP_SRC)
	$(CHDIR)/libupnp-$(LIBUPNP_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libupnp.pc
	$(REWRITE_LIBTOOL)/libixml.la
	$(REWRITE_LIBTOOL)/libthreadutil.la
	$(REWRITE_LIBTOOL)/libupnp.la	
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
	$(TOUCH)

#
# rarfs
#
RARFS_VER = 0.1.1
RARFS_SRC = rarfs-$(RARFS_VER).tar.gz
RARFS_URL = https://sourceforge.net/projects/rarfs/files/rarfs/$(RARFS_VER)

$(ARCHIVE)/$(RARFS_SRC):
	$(DOWNLOAD) $(RARFS_URL)/$(RARFS_SRC)

$(D)/rarfs: $(D)/bootstrap $(D)/fuse $(ARCHIVE)/$(RARFS_SRC)
	$(START_BUILD)
	$(REMOVE)/rarfs-$(RARFS_VER)
	$(UNTAR)/$(RARFS_SRC)
	$(CHDIR)/rarfs-$(RARFS_VER); \
		export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -D_FILE_OFFSET_BITS=64" \
			--prefix=/usr \
			--disable-option-checking \
			--includedir=/usr/include/fuse \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/rarfs-$(RARFS_VER)
	$(TOUCH)

#
# sshfs
#
SSHFS_VER = 2.9
SSHFS_SRC = sshfs-$(SSHFS_VER).tar.gz
SSHFS_URL = https://github.com/libfuse/sshfs/releases/download/sshfs-$(SSHFS_VER)

$(ARCHIVE)/$(SSHFS_SRC):
	$(DOWNLOAD) $(SSHFS_URL)/$(SSHFS_SRC)

$(D)/sshfs: $(D)/bootstrap $(D)/libglib2 $(D)/fuse $(ARCHIVE)/$(SSHFS_SRC)
	$(START_BUILD)
	$(REMOVE)/sshfs-$(SSHFS_VER)
	$(UNTAR)/$(SSHFS_SRC)
	$(CHDIR)/sshfs-$(SSHFS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/sshfs-$(SSHFS_VER)
	$(TOUCH)

#
# howl
#
HOWL_VER = 1.0.0
HOWL_SRC = howl-$(HOWL_VER).tar.gz
HOWL_URL = https://sourceforge.net/projects/howl/files/howl/$(HOWL_VER)

$(ARCHIVE)/$(HOWL_SRC):
	$(DOWNLOAD) $(HOWL_URL)/$(HOWL_SRC)

$(D)/howl: $(D)/bootstrap $(ARCHIVE)/$(HOWL_SRC)
	$(START_BUILD)
	$(REMOVE)/howl-$(HOWL_VER)
	$(UNTAR)/$(HOWL_SRC)
	$(CHDIR)/howl-$(HOWL_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/howl.pc
	$(REWRITE_LIBTOOL)/libhowl.la
	$(REMOVE)/howl-$(HOWL_VER)
	$(TOUCH)

#
# libdaemon
#
LIBDAEMON_VER = 0.14
LIBDAEMON_SRC = libdaemon-$(LIBDAEMON_VER).tar.gz
LIBDAEMON_URL = http://0pointer.de/lennart/projects/libdaemon

$(ARCHIVE)/$(LIBDAEMON_SRC):
	$(DOWNLOAD) $(LIBDAEMON_URL)/$(LIBDAEMON_SRC)

$(D)/libdaemon: $(D)/bootstrap $(ARCHIVE)/$(LIBDAEMON_SRC)
	$(START_BUILD)
	$(REMOVE)/libdaemon-$(LIBDAEMON_VER)
	$(UNTAR)/$(LIBDAEMON_SRC)
	$(CHDIR)/libdaemon-$(LIBDAEMON_VER); \
		$(CONFIGURE) \
			ac_cv_func_setpgrp_void=yes \
			--prefix=/usr \
			--disable-static \
			--disable-lynx \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdaemon.pc
	$(REWRITE_LIBTOOL)/libdaemon.la
	$(REMOVE)/libdaemon-$(LIBDAEMON_VER)
	$(TOUCH)

#
# libplist
#
LIBPLIST_VER = 1.10
LIBPLIST_SRC = libplist-$(LIBPLIST_VER).tar.gz
LIBPLIST_URL = https://cgit.sukimashita.com/libplist.git/snapshot

$(ARCHIVE)/$(LIBPLIST_SRC):
	$(DOWNLOAD) $(LIBPLIST_URL)/$(LIBPLIST_SRC)

$(D)/libplist: $(D)/bootstrap $(D)/libxml2 $(ARCHIVE)/$(LIBPLIST_SRC)
	$(START_BUILD)
	$(REMOVE)/libplist-$(LIBPLIST_VER)
	$(UNTAR)/$(LIBPLIST_SRC)
	export PKG_CONFIG_PATH=$(PKG_CONFIG_PATH); \
	$(CHDIR)/libplist-$(LIBPLIST_VER); \
		rm CMakeFiles/* -rf CMakeCache.txt cmake_install.cmake; \
		cmake . -DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_SYSTEM_NAME="Linux" \
			-DCMAKE_INSTALL_PREFIX="/usr" \
			-DCMAKE_C_COMPILER="$(TARGET)-gcc" \
			-DCMAKE_CXX_COMPILER="$(TARGET)-g++" \
			-DCMAKE_INCLUDE_PATH="$(TARGET_DIR)/usr/include" \
		; \
		find . -name cmake_install.cmake -print0 | xargs -0 \
		sed -i 's@SET(CMAKE_INSTALL_PREFIX "/usr/local")@SET(CMAKE_INSTALL_PREFIX "")@'; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libplist.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libplist++.pc
	$(REMOVE)/libplist-$(LIBPLIST_VER)
	$(TOUCH)

#
# libao
#
LIBAO_VER = 1.1.0
LIBAO_SRC = libao-$(LIBAO_VER).tar.gz
LIBAO_URL = https://ftp.osuosl.org/pub/xiph/releases/ao

$(ARCHIVE)/$(LIBAO_SRC):
	$(DOWNLOAD) $(LIBAO_URL)/$(LIBAO_SRC)

$(D)/libao: $(D)/bootstrap $(D)/alsa_lib $(ARCHIVE)/$(LIBAO_SRC)
	$(START_BUILD)
	$(REMOVE)/libao-$(LIBAO_VER)
	$(UNTAR)/$(LIBAO_SRC)
	$(CHDIR)/libao-$(LIBAO_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-shared \
			--disable-static \
			--enable-alsa \
			--enable-alsa-mmap \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ao.pc
	$(REWRITE_LIBTOOL)/libao.la
	$(REMOVE)/libao-$(LIBAO_VER)
	$(TOUCH)

#
# nettle
#
NETTLE_VER = 3.3
NETTLE_SRC = nettle-$(NETTLE_VER).tar.gz
NETTLE_URL = https://ftp.gnu.org/gnu/nettle

NETTLE_PATCH = nettle-$(NETTLE_VER).patch

$(ARCHIVE)/$(NETTLE_SRC):
	$(DOWNLOAD) $(NETTLE_URL)/$(NETTLE_SRC)

$(D)/nettle: $(D)/bootstrap $(D)/gmp $(ARCHIVE)/$(NETTLE_SRC)
	$(START_BUILD)
	$(REMOVE)/nettle-$(NETTLE_VER)
	$(UNTAR)/$(NETTLE_SRC)
	$(CHDIR)/nettle-$(NETTLE_VER); \
		$(call apply_patches, $(NETTLE_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-documentation \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/hogweed.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/nettle.pc
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,sexp-conv nettle-hash nettle-pbkdf2 nettle-lfib-stream pkcs1-conv)
	$(REMOVE)/nettle-$(NETTLE_VER)
	$(TOUCH)

#
# gnutls
#
GNUTLS_VER_MAJOR = 3.6
GNUTLS_VER_MINOR = 1
GNUTLS_VER = $(GNUTLS_VER_MAJOR).$(GNUTLS_VER_MINOR)
GNUTLS_SRC = gnutls-$(GNUTLS_VER).tar.xz
GNUTLS_URL = ftp://ftp.gnutls.org/gcrypt/gnutls/v$(GNUTLS_VER_MAJOR)

$(ARCHIVE)/$(GNUTLS_SRC):
	$(DOWNLOAD) $(GNUTLS_URL)/$(GNUTLS_SRC)

$(D)/gnutls: $(D)/bootstrap $(D)/nettle $(ARCHIVE)/$(GNUTLS_SRC)
	$(START_BUILD)
	$(REMOVE)/gnutls-$(GNUTLS_VER)
	$(UNTAR)/$(GNUTLS_SRC)
	$(CHDIR)/gnutls-$(GNUTLS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--datarootdir=/.remove \
			--with-included-libtasn1 \
			--enable-local-libopts \
			--with-libpthread-prefix=$(TARGET_DIR)/usr \
			--with-libz-prefix=$(TARGET_DIR)/usr \
			--with-included-unistring \
			--with-default-trust-store-dir=$(CA_BUNDLE_DIR)/ \
			--disable-guile \
			--without-p11-kit \
			--without-idn \
			--disable-libdane \
			--without-tpm \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/gnutls.pc
	$(REWRITE_LIBTOOL)/libgnutls.la
	$(REWRITE_LIBTOOL)/libgnutlsxx.la
	$(REWRITE_LIBTOOLDEP)/libgnutlsxx.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,psktool gnutls-cli-debug certtool srptool ocsptool gnutls-serv gnutls-cli)
	$(REMOVE)/gnutls-$(GNUTLS_VER)
	$(TOUCH)

#
# glib-networking
#
GLIB_NETWORKING_VER_MAJOR = 2.50
GLIB_NETWORKING_VER_MINOR = 0
GLIB_NETWORKING_VER = $(GLIB_NETWORKING_VER_MAJOR).$(GLIB_NETWORKING_VER_MINOR)
GLIB_NETWORKING_SRC = glib-networking-$(GLIB_NETWORKING_VER).tar.xz
GLIB_NETWORKING_URL = https://download.gnome.org/sources/glib-networking/$(GLIB_NETWORKING_VER_MAJOR)

$(ARCHIVE)/$(GLIB_NETWORKING_SRC):
	$(DOWNLOAD) $(GLIB_NETWORKING_URL)/$(GLIB_NETWORKING_SRC)

$(D)/glib_networking: $(D)/bootstrap $(D)/libglib2 $(ARCHIVE)/$(GLIB_NETWORKING_SRC)
	$(START_BUILD)
	$(REMOVE)/glib-networking-$(GLIB_NETWORKING_VER)
	$(UNTAR)/$(GLIB_NETWORKING_SRC)
	$(CHDIR)/glib-networking-$(GLIB_NETWORKING_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--datadir=/.remove \
			--datarootdir=/.remove \
			--localedir=/.remove \
			--with-gnutls=no \
		; \
		$(MAKE); \
		$(MAKE) install prefix=$(TARGET_DIR) giomoduledir=$(TARGET_DIR)/usr/lib/gio/modules itlocaledir=$(TARGET_DIR)/.remove
	$(REMOVE)/glib-networking-$(GLIB_NETWORKING_VER)
	$(TOUCH)

#
# Pixman: Pixel Manipulation library
#
PIXMAN_VER = 0.34.0
PIXMAN_SRC = pixman-$(PIXMAN_VER).tar.gz
PIXMAN_URL = https://www.cairographics.org/releases

PIXMAN_PATCH  = pixman-$(PIXMAN_VER)-0001-ARM-qemu-related-workarounds-in-cpu-features-detecti.patch
PIXMAN_PATCH += pixman-$(PIXMAN_VER)-asm_include.patch
PIXMAN_PATCH += pixman-$(PIXMAN_VER)-0001-test-utils-Check-for-FE_INVALID-definition-before-us.patch

$(ARCHIVE)/$(PIXMAN_SRC):
	$(DOWNLOAD) $(PIXMAN_URL)/$(PIXMAN_SRC)

$(D)/pixman: $(ARCHIVE)/$(PIXMAN_SRC) $(D)/bootstrap $(D)/zlib $(D)/libpng
	$(START_BUILD)
	$(REMOVE)/pixman-$(PIXMAN_VER)
	$(UNTAR)/$(PIXMAN_SRC)
	$(CHDIR)/pixman-$(PIXMAN_VER); \
		$(call apply_patches, $(PIXMAN_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-gtk \
			--disable-arm-simd \
			--disable-loongson-mmi \
			--disable-docs \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libpixman-1.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/pixman-1.pc
	$(REMOVE)/pixman-$(PIXMAN_VER)
	$(TOUCH)

#
# HarfBuzz is an OpenType text shaping engine
#
HARFBUZZ_VER = 1.8.8
HARFBUZZ_SRC = harfbuzz-$(HARFBUZZ_VER).tar.bz2
HARFBUZZ_URL = https://www.freedesktop.org/software/harfbuzz/release

HARFBUZZ_PATCH  = harfbuzz-$(HARFBUZZ_VER)-disable-docs.patch

$(ARCHIVE)/$(HARFBUZZ_SRC):
	$(DOWNLOAD) $(HARFBUZZ_URL)/$(HARFBUZZ_SRC)

$(D)/harfbuzz: $(ARCHIVE)/$(HARFBUZZ_SRC) $(D)/bootstrap $(D)/libglib2 $(D)/freetype
	$(START_BUILD)
	$(REMOVE)/harfbuzz-$(HARFBUZZ_VER)
	$(UNTAR)/$(HARFBUZZ_SRC)
	$(CHDIR)/harfbuzz-$(HARFBUZZ_VER); \
		$(call apply_patches, $(HARFBUZZ_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--without-cairo \
			--with-freetype \
			--without-fontconfig \
			--with-glib \
			--without-graphite2 \
			--without-icu \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libharfbuzz.la
	$(REWRITE_LIBTOOL)/libharfbuzz-subset.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/harfbuzz.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/harfbuzz-subset.pc
	$(REMOVE)/harfbuzz-$(HARFBUZZ_VER)
	$(TOUCH)

#
# libnsl
#
LIBNSL_VER = 2.0.0
LIBNSL_SRC = libnsl-$(LIBNSL_VER).tar.gz
LIBNSL_URL = https://github.com/thkukuk/libnsl/archive/v$(LIBNSL_VER)

$(ARCHIVE)/$(LIBNSL_SRC):
	$(DOWNLOAD) $(LIBNSL_URL)/$(LIBNSL_SRC)

$(D)/libnsl: $(D)/bootstrap $(ARCHIVE)/$(LIBNSL_SRC)
	$(START_BUILD)
	$(REMOVE)/libnsl-$(LIBNSL_VER)
	$(UNTAR)/$(LIBNSL_SRC)
	$(CHDIR)/libnsl-$(LIBNSL_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(CROSS_DIR)/$(TARGET)/sys-root
		cp -a $(CROSS_DIR)/$(TARGET)/sys-root/usr/lib/libnsl.so* $(TARGET_DIR)/usr/lib
	$(REMOVE)/libnsl-$(LIBNSL_VER)
	$(TOUCH)

#
# libevent
#
LIBEVENT_VER = 2.0.21-stable
LIBEVENT_SRC = libevent-$(LIBEVENT_VER).tar.gz
LIBEVENT_URL = https://github.com/downloads/libevent/libevent

$(ARCHIVE)/$(LIBEVENT_SRC):
	$(DOWNLOAD) $(LIBEVENT_URL)/$(LIBEVENT_SRC)

$(D)/libevent: $(D)/bootstrap $(ARCHIVE)/$(LIBEVENT_SRC)
	$(START_BUILD)
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	$(UNTAR)/$(LIBEVENT_SRC)
	$(CHDIR)/libevent-$(LIBEVENT_VER);\
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent_openssl.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libevent_pthreads.pc
	$(REWRITE_LIBTOOL)/libevent_core.la
	$(REWRITE_LIBTOOL)/libevent_extra.la
	$(REWRITE_LIBTOOL)/libevent.la
	$(REWRITE_LIBTOOL)/libevent_openssl.la
	$(REWRITE_LIBTOOL)/libevent_pthreads.la
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	$(TOUCH)

#
# libnfsidmap
#
LIBNFSIDMAP_VER = 0.25
LIBNFSIDMAP_SRC = libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz
LIBNFSIDMAP_URL = http://www.citi.umich.edu/projects/nfsv4/linux/libnfsidmap

$(ARCHIVE)/$(LIBNFSIDMAP_SRC):
	$(DOWNLOAD) $(LIBNFSIDMAP_URL)/$(LIBNFSIDMAP_SRC)

$(D)/libnfsidmap: $(D)/bootstrap $(ARCHIVE)/$(LIBNFSIDMAP_SRC)
	$(START_BUILD)
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	$(UNTAR)/$(LIBNFSIDMAP_SRC)
	$(CHDIR)/libnfsidmap-$(LIBNFSIDMAP_VER);\
		$(CONFIGURE) \
		ac_cv_func_malloc_0_nonnull=yes \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnfsidmap.pc
	$(REWRITE_LIBTOOL)/libnfsidmap.la
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	$(TOUCH)

#
# libnl
#
LIBNL_VER = 3.2.25
LIBNL_SRC = libnl-$(LIBNL_VER).tar.gz
LIBNL_URL = https://www.infradead.org/~tgr/libnl/files

$(ARCHIVE)/$(LIBNL_SRC):
	$(DOWNLOAD) $(LIBNL_URL)/$(LIBNL_SRC)

$(D)/libnl: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(LIBNL_SRC)
	$(START_BUILD)
	$(REMOVE)/libnl-$(LIBNL_VER)
	$(UNTAR)/$(LIBNL_SRC)
	$(CHDIR)/libnl-$(LIBNL_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--bindir=/.remove \
			--mandir=/.remove \
			--infodir=/.remove \
		make; \
		make install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-cli-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-genl-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-nf-3.0.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libnl-route-3.0.pc
	$(REWRITE_LIBTOOL)/libnl-3.la
	$(REWRITE_LIBTOOL)/libnl-cli-3.la
	$(REWRITE_LIBTOOL)/libnl-genl-3.la
	$(REWRITE_LIBTOOL)/libnl-idiag-3.la
	$(REWRITE_LIBTOOL)/libnl-nf-3.la
	$(REWRITE_LIBTOOL)/libnl-route-3.la
	$(REMOVE)/libnl-$(LIBNL_VER)
	$(TOUCH)

#
# libdvbcsa
#
LIBDVBCSA_SRC = libdvbcsa.git
LIBDVBCSA_URL = https://code.videolan.org/videolan/libdvbcsa.git

$(ARCHIVE)/$(LIBDVBCSA_SRC):
	set -e;
	if [ -d $(ARCHIVE)/libdvbcsa.git ]; then \
		cd $(ARCHIVE)/$(LIBDVBCSA_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(LIBDVBCSA_URL) $(LIBDVBCSA_SRC); \
	fi

$(D)/libdvbcsa: $(D)/bootstrap $(ARCHIVE)/$(LIBDVBCSA_SRC)
	$(START_BUILD)
	$(REMOVE)/libdvbcsa
	cp -ra $(ARCHIVE)/$(LIBDVBCSA_SRC) $(BUILD_TMP)/libdvbcsa
	$(CHDIR)/libdvbcsa; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libdvbcsa.la
	$(REMOVE)/libdvbcsa
	$(TOUCH)
	
#
# librtmpdump
#
LIBRTMPDUMP_VER = ad70c64
LIBRTMPDUMP_SRC = librtmpdump-$(LIBRTMPDUMP_VER).tar.bz2
LIBRTMPDUMP_URL = https://github.com/oe-alliance/rtmpdump.git

LIBRTMPDUMP_PATCH = rtmpdump-2.4.patch

$(ARCHIVE)/$(LIBRTMPDUMP_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LIBRTMPDUMP_URL) $(LIBRTMPDUMP_VER) $(notdir $@) $(ARCHIVE)

$(D)/librtmpdump: $(D)/bootstrap $(D)/zlib $(D)/openssl $(ARCHIVE)/$(LIBRTMPDUMP_SRC)
	$(START_BUILD)
	$(REMOVE)/librtmpdump-$(LIBRTMPDUMP_VER)
	$(UNTAR)/$(LIBRTMPDUMP_SRC)
	set -e; cd $(BUILD_TMP)/librtmpdump-$(LIBRTMPDUMP_VER); \
		$(call apply_patches,$(LIBRTMPDUMP_PATCH)); \
		$(BUILDENV) \
		$(MAKE) CROSS_COMPILE=$(TARGET)- ; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR) MANDIR=$(TARGET_DIR)/.remove
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/librtmp.pc
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,rtmpgw rtmpsrv rtmpsuck)
	$(REMOVE)/librtmpdump-$(LIBRTMPDUMP_VER)
	$(TOUCH)
	
#
# libxmlccwrap
#
LIBXMLCCWRAP_VER = 0.0.12
LIBXMLCCWRAP_SRC = libxmlccwrap-$(LIBXMLCCWRAP_VER).tar.gz
LIBXMLCCWRAP_URL = http://www.ant.uni-bremen.de/whomes/rinas/libxmlccwrap/download

$(ARCHIVE)/$(LIBXMLCCWRAP_SRC):
	$(DOWNLOAD) $(LIBXMLCCWRAP_URL)/$(LIBXMLCCWRAP_SRC)

$(D)/libxmlccwrap: $(D)/bootstrap $(D)/libxml2 $(D)/libxslt $(ARCHIVE)/$(LIBXMLCCWRAP_SRC)
	$(START_BUILD)
	$(REMOVE)/libxmlccwrap-$(LIBXMLCCWRAP_VER)
	$(UNTAR)/$(LIBXMLCCWRAP_SRC)
	$(CHDIR)/libxmlccwrap-$(LIBXMLCCWRAP_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libxmlccwrap.la
	$(REMOVE)/libxmlccwrap-$(LIBXMLCCWRAP_VER)
	$(TOUCH)	

#
# orc
#
ORC_VER = 0.4.27
ORC_SRC = orc-$(ORC_VER).tar.xz
ORC_URL = https://gstreamer.freedesktop.org/src/orc

$(ARCHIVE)/$(ORC_SRC):
	$(DOWNLOAD) $(ORC_URL)/$(ORC_SRC)

$(D)/orc: $(D)/bootstrap $(ARCHIVE)/$(ORC_SRC)
	$(START_BUILD)
	$(REMOVE)/orc-$(ORC_VER)
	$(UNTAR)/$(ORC_SRC)
	$(CHDIR)/orc-$(ORC_VER); \
		$(CONFIGURE) \
			--datarootdir=/.remove \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/orc-0.4.pc
	$(REWRITE_LIBTOOL)/liborc-0.4.la
	$(REWRITE_LIBTOOL)/liborc-test-0.4.la
	$(REWRITE_LIBTOOLDEP)/liborc-test-0.4.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,orc-bugreport orcc)
	$(REMOVE)/orc-$(ORC_VER)
	$(TOUCH)

#
# libdca
#
LIBDCA_VER = 0.0.5
LIBDCA_SRC = libdca-$(LIBDCA_VER).tar.bz2
LIBDCA_URL = http://download.videolan.org/pub/videolan/libdca/$(LIBDCA_VER)

$(ARCHIVE)/$(LIBDCA_SRC):
	$(DOWNLOAD) $(LIBDCA_URL)/$(LIBDCA_SRC)

$(D)/libdca: $(D)/bootstrap $(ARCHIVE)/$(LIBDCA_SRC)
	$(START_BUILD)
	$(REMOVE)/libdca-$(LIBDCA_VER)
	$(UNTAR)/$(LIBDCA_SRC)
	$(CHDIR)/libdca-$(LIBDCA_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdca.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdts.pc
	$(REWRITE_LIBTOOL)/libdca.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,extract_dca extract_dts)
	$(REMOVE)/libdca-$(LIBDCA_VER)
	$(TOUCH)

#
# libzvbi
#
LIBZVBI_VER = 0.2.35
LIBZVBI_SRC = zvbi-$(LIBZVBI_VER).tar.bz2
LIBZVBI_URL = https://sourceforge.net/projects/zapping/files/zvbi/$(LIBZVBI_VER)

$(ARCHIVE)/$(LIBZVBI_SRC):
	$(DOWNLOAD) $(LIBZVBI_URL)/$(LIBZVBI_SRC)

$(D)/libzvbi: $(D)/bootstrap $(ARCHIVE)/$(LIBZVBI_SRC)
	$(START_BUILD)
	$(REMOVE)/zvbi-$(LIBZVBI_VER)
	$(UNTAR)/$(LIBZVBI_SRC)
	$(CHDIR)/zvbi-$(LIBZVBI_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--bindir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libzvbi.la
	$(REWRITE_LIBTOOL)/libzvbi-chains.la
	$(REMOVE)/zvbi-$(LIBZVBI_VER)
	$(TOUCH)
	
