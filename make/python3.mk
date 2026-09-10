#
# python3
#
PYTHON3_VER_MAJOR = 3.14
PYTHON3_VER_MINOR = 7
PYTHON3_VER = $(PYTHON3_VER_MAJOR).$(PYTHON3_VER_MINOR)
PYTHON3_SRC = Python-$(PYTHON3_VER).tar.xz

PYTHON3_PATCH  = 0001-default-is-optimized.patch \
	0002-Make-the-build-of-pyc-files-conditional.patch \
	0003-Disable-buggy-getaddrinfo-configure-test-when-cross-.patch \
	0004-Add-an-option-to-disable-pydoc.patch \
	0005-Add-an-option-to-disable-IDLE.patch \
	0006-configure.ac-move-PY-STDLIB-MOD-SET-NA-further-up.patch \
	0007-Add-option-to-disable-the-sqlite3-module.patch \
	0008-Add-an-option-to-disable-the-tk-module.patch \
	0009-Add-an-option-to-disable-the-curses-module.patch \
	0010-Add-an-option-to-disable-expat.patch \
	0011-configure.ac-fixup-CC-print-multiarch-output-for-mus.patch \
	0300-generate-legacy-pyc-bytecode.patch

#
# python helpers
#
PYTHON3_DIR = usr/lib/python$(PYTHON_VER_MAJOR)
PYTHON3_INCLUDE_DIR = usr/include/python$(PYTHON_VER_MAJOR)

PYTHON3_BUILD = \
	CC="$(TARGET)-gcc" \
	CFLAGS="$(TARGET_CFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	LDSHARED="$(TARGET)-gcc -shared" \
	PYTHONPATH=$(TARGET_DIR)/$(PYTHON3_DIR)/site-packages \
	CPPFLAGS="$(TARGET_CPPFLAGS) -I$(TARGET_DIR)/$(PYTHON3_INCLUDE_DIR)" \
	$(HOST_DIR)/bin/python ./setup.py -q build --executable=/usr/bin/python

PYTHON3_INSTALL = \
	CC="$(TARGET)-gcc" \
	CFLAGS="$(TARGET_CFLAGS)" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	LDSHARED="$(TARGET)-gcc -shared" \
	PYTHONPATH=$(TARGET_DIR)/$(PYTHON3_DIR)/site-packages \
	CPPFLAGS="$(TARGET_CPPFLAGS) -I$(TARGET_DIR)/$(PYTHON3_INCLUDE_DIR)" \
	$(HOST_DIR)/bin/python ./setup.py -q install --root=$(TARGET_DIR) --prefix=/usr

$(D)/python3: $(D)/bootstrap $(D)/ncurses $(D)/zlib $(D)/openssl $(D)/libffi $(D)/bzip2 $(D)/readline $(D)/sqlite $(ARCHIVE)/$(HOST_PYTHON3_SRC)
	$(START_BUILD)
	$(REMOVE)/Python-$(PYTHON3_VER)
	$(UNTAR)/$(PYTHON_SRC)
	$(CHDIR)/Python-$(PYTHON3_VER); \
		$(call apply_patches, $(PYTHON3_PATCH)); \
		CONFIG_SITE= \
		$(BUILDENV) \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--with-build-python \
			ac_cv_prog_HAS_HG=/bin/false \
			ac_cv_prog_SVNVERSION=/bin/false \
			ac_cv_file__dev_ptmx=no \
			ac_cv_file__dev_ptc=no \
			ac_cv_have_long_long_format=yes \
			ac_cv_working_tzset=yes \
			ac_cv_func_lchflags_works=no \
			ac_cv_func_chflags_works=no \
			ac_cv_func_printf_zd=yes \
			ac_cv_buggy_getaddrinfo=no \
			ac_cv_header_bluetooth_bluetooth_h=no \
			ac_cv_header_bluetooth_h=no \
			py_cv_module_unicodedata=yes \
			py_cv_module__codecs_cn=n/a \
			py_cv_module__codecs_hk=n/a \
			py_cv_module__codecs_iso2022=n/a \
			py_cv_module__codecs_jp=n/a \
			py_cv_module__codecs_kr=n/a \
			py_cv_module__codecs_tw=n/a \
			py_cv_module__decimal=n/a \
			py_cv_module_nis=n/a \
			py_cv_module_ossaudiodev=n/a \
			py_cv_module__dbm=n/a \
		; \
		$(MAKE) \
			PYTHON_MODULES_INCLUDE="$(TARGET_DIR)/usr/include" \
			PYTHON_MODULES_LIB="$(TARGET_DIR)/usr/lib" \
			PYTHON_XCOMPILE_DEPENDENCIES_PREFIX="$(TARGET_DIR)" \
			CROSS_COMPILE_TARGET=yes \
			CROSS_COMPILE=$(TARGET) \
			MACHDEP=linux2 \
			HOSTARCH=$(TARGET) \
			CFLAGS="$(TARGET_CFLAGS)" \
			LDFLAGS="$(TARGET_LDFLAGS)" \
			LD="$(TARGET)-gcc" \
			HOSTPYTHON=$(HOST_DIR)/bin/python$(PYTHON3_VER_MAJOR) \
			HOSTPGEN=$(HOST_DIR)/bin/pgen \
			all DESTDIR=$(TARGET_DIR) \
		; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	ln -sf ../../libpython$(PYTHON3_VER_MAJOR).so.1.0 $(TARGET_DIR)/$(PYTHON3_DIR)/config/libpython$(PYTHON3_VER_MAJOR).so; \
	ln -sf $(TARGET_DIR)/$(PYTHON3_INCLUDE_DIR) $(TARGET_DIR)/usr/include/python
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/python-$(PYTHON3_VER_MAJOR).pc
	$(REMOVE)/Python-$(PYTHON3_VER)
	$(TOUCH)

