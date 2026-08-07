#
# toolcheck
#
TOOLCHECK  = find-git find-svn find-gzip find-bzip2 find-patch find-gawk
TOOLCHECK += find-makeinfo find-automake find-gcc find-libtool
TOOLCHECK += find-yacc find-flex find-tic find-pkg-config find-help2man
TOOLCHECK += find-cmake find-gperf

find-%:
	@TOOL=$(patsubst find-%,%,$@); \
		type -p $$TOOL >/dev/null || \
		{ echo -e "$(TERM_RED)required tool $$TOOL missing.$(TERM_NORMAL)"; false; }

toolcheck: $(TOOLCHECK)
	@echo "All required tools seem to be installed."
	@echo
ifeq ($(BOXARCH), sh4)
	@for i in audio_7100 audio_7105 audio_7111 video_7100 video_7105 video_7109 video_7111; do \
		if [ ! -e $(SKEL_ROOT)/boot/$$i.elf ]; then \
			echo -e "\n    $(TERM_RED)ERROR:$(TERM_NORMAL) One or more .elf files are missing in $(SKEL_ROOT)/boot!"; \
			echo "           $$i.elf is one of them"; \
			echo; \
			echo "    Correct this and retry."; \
			echo; \
		fi; \
	done
endif
	@if test "$(subst /bin/,,$(shell readlink /bin/sh))" != bash; then \
		echo "WARNING: /bin/sh is not linked to bash."; \
		echo "         This configuration might work, but is not supported."; \
		echo; \
	fi

#
# host_pkgconfig
#
HOST_PKGCONFIG_VER = 0.29.2
HOST_PKGCONFIG_SRC = pkg-config-$(HOST_PKGCONFIG_VER).tar.gz

$(ARCHIVE)/$(HOST_PKGCONFIG_SRC):
	$(DOWNLOAD) https://pkgconfig.freedesktop.org/releases/$(HOST_PKGCONFIG_SRC)

$(D)/host_pkgconfig: $(D)/directories $(ARCHIVE)/$(HOST_PKGCONFIG_SRC)
	$(START_BUILD)
	$(REMOVE)/pkg-config-$(HOST_PKGCONFIG_VER)
	$(UNTAR)/$(HOST_PKGCONFIG_SRC)
	$(CHDIR)/pkg-config-$(HOST_PKGCONFIG_VER); \
		./configure \
			--prefix=$(HOST_DIR) \
			--program-prefix=$(TARGET)- \
			--disable-host-tool \
			--with-pc_path=$(PKG_CONFIG_PATH) \
			--with-internal-glib \
		; \
		$(MAKE); \
		$(MAKE) install
	ln -sf $(TARGET)-pkg-config $(HOST_DIR)/bin/pkg-config
	$(REMOVE)/pkg-config-$(HOST_PKGCONFIG_VER)
	$(TOUCH)

#
# host_module_init_tools
#
HOST_MODULE_INIT_TOOLS_VER = 3.16
HOST_MODULE_INIT_TOOLS_SRC = module-init-tools-$(HOST_MODULE_INIT_TOOLS_VER).tar.bz2

HOST_MODULE_INIT_TOOLS_PATCH = module-init-tools-$(HOST_MODULE_INIT_TOOLS_VER).patch

$(ARCHIVE)/$(HOST_MODULE_INIT_TOOLS_SRC):
	$(DOWNLOAD) http://distro.ibiblio.org/fatdog/source/600/m/$(HOST_MODULE_INIT_TOOLS_SRC)

$(D)/host_module_init_tools: $(D)/directories $(ARCHIVE)/$(HOST_MODULE_INIT_TOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/module-init-tools-$(HOST_MODULE_INIT_TOOLS_VER)
	$(UNTAR)/$(HOST_MODULE_INIT_TOOLS_SRC)
	$(CHDIR)/module-init-tools-$(HOST_MODULE_INIT_TOOLS_VER); \
		$(call apply_patches,$(HOST_MODULE_INIT_TOOLS_PATCH)); \
		autoreconf -fi; \
		./configure \
			--prefix=$(HOST_DIR) \
			--sbindir=$(HOST_DIR)/bin \
		; \
		$(MAKE) all; \
		$(MAKE) install
	$(REMOVE)/module-init-tools-$(HOST_MODULE_INIT_TOOLS_VER)
	$(TOUCH)

#
# host_mtd_utils
#
HOST_MTD_UTILS_VER = 1.5.2
HOST_MTD_UTILS_SRC = mtd-utils-$(HOST_MTD_UTILS_VER).tar.bz2

HOST_MTD_UTILS_PATCH = host-mtd-utils-$(HOST_MTD_UTILS_VER).patch
HOST_MTD_UTILS_PATCH += host-mtd-utils-$(HOST_MTD_UTILS_VER)-sysmacros.patch

$(ARCHIVE)/$(HOST_MTD_UTILS_SRC):
	$(DOWNLOAD) ftp://ftp.infradead.org/pub/mtd-utils/$(HOST_MTD_UTILS_SRC)

$(D)/host_mtd_utils: $(D)/directories $(ARCHIVE)/$(HOST_MTD_UTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/mtd-utils-$(HOST_MTD_UTILS_VER)
	$(UNTAR)/$(HOST_MTD_UTILS_SRC)
	$(CHDIR)/mtd-utils-$(HOST_MTD_UTILS_VER); \
		$(call apply_patches,$(HOST_MTD_UTILS_PATCH)); \
		$(MAKE) `pwd`/mkfs.jffs2 `pwd`/sumtool BUILDDIR=`pwd` WITHOUT_XATTR=1 DESTDIR=$(HOST_DIR); \
		$(MAKE) install BINDIR=$(HOST_DIR)/bin MANDIR=$(HOST_DIR)/share/man
	$(REMOVE)/mtd-utils-$(HOST_MTD_UTILS_VER)
	$(TOUCH)

#
# host_mkcramfs
#
HOST_MKCRAMFS_VER = 1.1
HOST_MKCRAMFS_SRC = cramfs-$(HOST_MKCRAMFS_VER).tar.gz

HOST_MKCRAMFS_PATCH = cramfs-$(HOST_MKCRAMFS_VER)-sysmacros.patch

$(ARCHIVE)/$(HOST_MKCRAMFS_SRC):
	$(DOWNLOAD) https://sourceforge.net/projects/cramfs/files/cramfs/$(HOST_MKCRAMFS_VER)/$(HOST_MKCRAMFS_SRC)

$(D)/host_mkcramfs: $(D)/directories $(ARCHIVE)/$(HOST_MKCRAMFS_SRC)
	$(START_BUILD)
	$(REMOVE)/cramfs-$(HOST_MKCRAMFS_VER)
	$(UNTAR)/$(HOST_MKCRAMFS_SRC)
	$(CHDIR)/cramfs-$(HOST_MKCRAMFS_VER); \
		$(call apply_patches,$(HOST_MKCRAMFS_PATCH)); \
		$(MAKE) all
		cp $(BUILD_TMP)/cramfs-$(HOST_MKCRAMFS_VER)/mkcramfs $(HOST_DIR)/bin
		cp $(BUILD_TMP)/cramfs-$(HOST_MKCRAMFS_VER)/cramfsck $(HOST_DIR)/bin
	$(REMOVE)/cramfs-$(HOST_MKCRAMFS_VER)
	$(TOUCH)

#
# host_mksquashfs
#
HOST_MKSQUASHFS_VER = 3.3
HOST_MKSQUASHFS_SRC = squashfs$(HOST_MKSQUASHFS_VER).tar.gz

$(ARCHIVE)/$(HOST_MKSQUASHFS_SRC):
	$(DOWNLOAD) https://sourceforge.net/projects/squashfs/files/OldFiles/$(HOST_MKSQUASHFS_SRC)

$(D)/host_mksquashfs: directories $(ARCHIVE)/$(HOST_MKSQUASHFS_SRC)
	$(START_BUILD)
	$(REMOVE)/squashfs$(HOST_MKSQUASHFS_VER)
	$(UNTAR)/$(HOST_MKSQUASHFS_SRC)
	$(CHDIR)/squashfs$(HOST_MKSQUASHFS_VER)/squashfs-tools; \
		$(MAKE) CC=gcc all
		mv $(BUILD_TMP)/squashfs$(HOST_MKSQUASHFS_VER)/squashfs-tools/mksquashfs $(HOST_DIR)/bin/mksquashfs3.3
		mv $(BUILD_TMP)/squashfs$(HOST_MKSQUASHFS_VER)/squashfs-tools/unsquashfs $(HOST_DIR)/bin/unsquashfs3.3
	$(REMOVE)/squashfs$(HOST_MKSQUASHFS_VER)
	$(TOUCH)

#
# host_mksquashfs with LZMA support
#
HOST_MKSQUASHFS_LZMA_VER = 4.2
HOST_MKSQUASHFS_LZMA_SRC = squashfs$(HOST_MKSQUASHFS_LZMA_VER).tar.gz

HOST_MKSQUASHFS_LZMA_PATCH = squashfs-$(HOST_MKSQUASHFS_LZMA_VER)-sysmacros.patch

LZMA_VER = 4.65
LZMA_SRC = lzma-$(LZMA_VER).tar.bz2

$(ARCHIVE)/$(HOST_MKSQUASHFS_LZMA_SRC):
	$(DOWNLOAD) https://sourceforge.net/projects/squashfs/files/squashfs/squashfs$(HOST_MKSQUASHFS_LZMA_VER)/$(HOST_MKSQUASHFS_LZMA_SRC)

$(ARCHIVE)/$(LZMA_SRC):
	$(DOWNLOAD) http://downloads.openwrt.org/sources/$(LZMA_SRC)

$(D)/host_mksquashfs_lzma: directories $(ARCHIVE)/$(LZMA_SRC) $(ARCHIVE)/$(HOST_MKSQUASHFS_LZMA_SRC)
	$(START_BUILD)
	$(REMOVE)/lzma-$(LZMA_VER)
	$(UNTAR)/$(LZMA_SRC)
	$(REMOVE)/squashfs$(HOST_MKSQUASHFS_LZMA_VER)
	$(UNTAR)/$(HOST_MKSQUASHFS_LZMA_SRC)
	$(CHDIR)/squashfs$(HOST_MKSQUASHFS_LZMA_VER); \
		$(call apply_patches,$(HOST_MKSQUASHFS_LZMA_PATCH)); \
		$(MAKE) -C squashfs-tools EXTRA_CFLAGS=-fgnu89-inline \
			LZMA_SUPPORT=1 \
			LZMA_DIR=$(BUILD_TMP)/lzma-$(LZMA_VER) \
			XATTR_SUPPORT=0 \
			XATTR_DEFAULT=0 \
			install INSTALL_DIR=$(HOST_DIR)/bin
	$(REMOVE)/lzma-$(LZMA_VER)
	$(REMOVE)/squashfs$(HOST_MKSQUASHFS_LZMA_VER)
	$(TOUCH)

#
# host_e2fsprogs
#
HOST_E2FSPROGS_VER = 1.47.2
HOST_E2FSPROGS_SRC = e2fsprogs-$(HOST_E2FSPROGS_VER).tar.gz

$(ARCHIVE)/$(HOST_E2FSPROGS_SRC):
	$(DOWNLOAD) https://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v$(HOST_E2FSPROGS_VER)/$(HOST_E2FSPROGS_SRC)

$(D)/host_e2fsprogs: $(D)/directories $(ARCHIVE)/$(HOST_E2FSPROGS_SRC)
	$(START_BUILD)
	$(UNTAR)/$(HOST_E2FSPROGS_SRC)
	$(CHDIR)/e2fsprogs-$(HOST_E2FSPROGS_VER); \
		./configure; \
		$(MAKE)
	install -D -m 0755 $(BUILD_TMP)/e2fsprogs-$(HOST_E2FSPROGS_VER)/resize/resize2fs $(HOST_DIR)/bin/
	install -D -m 0755 $(BUILD_TMP)/e2fsprogs-$(HOST_E2FSPROGS_VER)/misc/mke2fs $(HOST_DIR)/bin/
	ln -sf mke2fs $(HOST_DIR)/bin/mkfs.ext2
	ln -sf mke2fs $(HOST_DIR)/bin/mkfs.ext3
	ln -sf mke2fs $(HOST_DIR)/bin/mkfs.ext4
	ln -sf mke2fs $(HOST_DIR)/bin/mkfs.ext4dev
	install -D -m 0755 $(BUILD_TMP)/e2fsprogs-$(HOST_E2FSPROGS_VER)/e2fsck/e2fsck $(HOST_DIR)/bin/
	ln -sf e2fsck $(HOST_DIR)/bin/fsck.ext2
	ln -sf e2fsck $(HOST_DIR)/bin/fsck.ext3
	ln -sf e2fsck $(HOST_DIR)/bin/fsck.ext4
	ln -sf e2fsck $(HOST_DIR)/bin/fsck.ext4dev
	$(REMOVE)/e2fsprogs-$(HOST_E2FSPROGS_VER)
	$(TOUCH)

#
# host_parted
#
HOST_PARTED_VER = 3.2
HOST_PARTED_SRC = parted-$(HOST_PARTED_VER).tar.xz

HOST_PARTED_PATCH = parted-$(HOST_PARTED_VER)-device-mapper.patch

$(ARCHIVE)/$(HOST_PARTED_SRC):
	$(DOWNLOAD) https://ftp.gnu.org/gnu/parted/$(HOST_PARTED_SRC)

$(D)/host_parted: $(D)/directories $(ARCHIVE)/$(HOST_PARTED_SRC)
	$(START_BUILD)
	$(REMOVE)/parted-$(HOST_PARTED_VER)
	$(UNTAR)/$(HOST_PARTED_SRC)
	$(CHDIR)/parted-$(HOST_PARTED_VER); \
		$(call apply_patches,$(HOST_PARTED_PATCH)); \
		./configure \
			--prefix=$(HOST_DIR) \
			--sbindir=$(HOST_DIR)/bin \
			--disable-device-mapper \
			--without-readline \
		; \
		$(MAKE) install
	$(REMOVE)/parted-$(HOST_PARTED_VER)
	$(TOUCH)
	
#
# host_cortex-strings
#
CORTEX_STRINGS_VER = 48fd30c
CORTEX_STRINGS_SRC = cortex-strings-git-$(CORTEX_STRINGS_VER).tar.bz2
CORTEX_STRINGS_URL = http://git.linaro.org/git-ro/toolchain/cortex-strings.git

$(ARCHIVE)/$(CORTEX_STRINGS_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(CORTEX_STRINGS_URL) $(CORTEX_STRINGS_VER) $(notdir $@) $(ARCHIVE)

$(D)/host_cortex_strings: $(D)/directories $(ARCHIVE)/$(CORTEX_STRINGS_SRC)
	$(START_BUILD)
	$(REMOVE)/cortex-strings-git-$(CORTEX_STRINGS_VER)
	$(UNTAR)/$(CORTEX_STRINGS_SRC)
	$(CHDIR)/cortex-strings-git-$(CORTEX_STRINGS_VER); \
		./autogen.sh; \
		./configure\
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--disable-shared \
			--enable-static \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libcortex-strings.la
	$(REMOVE)/cortex-strings-git-$(CORTEX_STRINGS_VER)
	$(TOUCH)
	
#
# host_dm_buildimage
#
BUILDIMAGE_PATCH = buildimage.patch

$(D)/host_dm_buildimage:
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/buildimage.git; \
		autoreconf -fi; \
		./configure; \
		$(MAKE); \
	install -m 755 $(TOOLS_DIR)/buildimage.git/src/buildimage $(HOST_DIR)/bin
	$(TOUCH)
	
#
# host_hisi3798mv200_buildimage
#
BUILDIMAGE_SRC = buildimage.zip

$(ARCHIVE)/$(BUILDIMAGE_SRC):
	$(DOWNLOAD) https://github.com/oe-alliance/oe-alliance-core/raw/5.0/meta-brands/meta-octagon/recipes-bsp/octagon-buildimage/$(BUILDIMAGE_SRC)
	
$(D)/host_hisi3798mv200_buildimage: $(ARCHIVE)/$(BUILDIMAGE_SRC)
	$(START_BUILD)
	$(REMOVE)/buildimage
	unzip -o $(ARCHIVE)/$(BUILDIMAGE_SRC) -d $(BUILD_TMP)/buildimage
	cd $(BUILD_TMP)/buildimage; \
	make; \
	cp -ra $(BUILD_TMP)/buildimage/mkupdate $(HOST_DIR)/bin/mkupdate
	$(REMOVE)/buildimage
	$(TOUCH)

#
# host_android tools
#
ANDROID_MIRROR = https://android.googlesource.com
HAT_CORE_REV = 2314b11
HAT_CORE_SRC = hat-core-git-$(HAT_CORE_REV).tar.bz2
HAT_EXTRAS_REV = 3ecbe8d
HAT_EXTRAS_SRC = hat-extras-git-$(HAT_EXTRAS_REV).tar.bz2
HAT_LIBSELINUX_REV = 07e9e13
HAT_LIBSELINUX_SRC = hat-libselinux-git-$(HAT_LIBSELINUX_REV).tar.bz2

$(ARCHIVE)/$(HAT_CORE_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(ANDROID_MIRROR)/platform/system/core $(HAT_CORE_REV) $(notdir $@) $(ARCHIVE)

$(ARCHIVE)/$(HAT_EXTRAS_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(ANDROID_MIRROR)/platform/system/extras $(HAT_EXTRAS_REV) $(notdir $@) $(ARCHIVE)

$(ARCHIVE)/$(HAT_LIBSELINUX_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(ANDROID_MIRROR)/platform/external/libselinux $(HAT_LIBSELINUX_REV) $(notdir $@) $(ARCHIVE)

$(D)/host_atools: $(D)/directories $(ARCHIVE)/$(HAT_CORE_SRC) $(ARCHIVE)/$(HAT_EXTRAS_SRC) $(ARCHIVE)/$(HAT_LIBSELINUX_SRC)
	$(START_BUILD)
	$(REMOVE)/hat
	$(MKDIR)/hat/system/core
	tar --strip 1 -C $(BUILD_TMP)/hat/system/core -xf $(ARCHIVE)/$(HAT_CORE_SRC)
	$(MKDIR)/hat/system/extras
	tar --strip 1 -C $(BUILD_TMP)/hat/system/extras -xf $(ARCHIVE)/$(HAT_EXTRAS_SRC)
	$(MKDIR)/hat/external/libselinux
	tar --strip 1 -C $(BUILD_TMP)/hat/external/libselinux -xf $(ARCHIVE)/$(HAT_LIBSELINUX_SRC)
	cp $(PATCHES)/ext4_utils.mk $(BUILD_TMP)/hat
	$(CHDIR)/hat; \
		$(MAKE) --file=ext4_utils.mk SRCDIR=$(BUILD_TMP)/hat
		install -D -m 0755 $(BUILD_TMP)/hat/ext2simg $(HOST_DIR)/bin/
		install -D -m 0755 $(BUILD_TMP)/hat/ext4fixup $(HOST_DIR)/bin/
		install -D -m 0755 $(BUILD_TMP)/hat/img2simg $(HOST_DIR)/bin/
		install -D -m 0755 $(BUILD_TMP)/hat/make_ext4fs $(HOST_DIR)/bin/
		install -D -m 0755 $(BUILD_TMP)/hat/simg2img $(HOST_DIR)/bin/
		install -D -m 0755 $(BUILD_TMP)/hat/simg2simg $(HOST_DIR)/bin/
	$(REMOVE)/hat
	$(TOUCH)
	
#
# host_python
#
HOST_PYTHON_VER_MAJOR = 2.7
HOST_PYTHON_VER_MINOR = 18
HOST_PYTHON_VER = $(HOST_PYTHON_VER_MAJOR).$(HOST_PYTHON_VER_MINOR)
HOST_PYTHON_SRC = Python-$(HOST_PYTHON_VER).tar.xz

HOST_PYTHON_PATCH = python-$(HOST_PYTHON_VER).patch
HOST_PYTHON_PATCH += python-$(HOST_PYTHON_VER)-support_64bit.patch

$(ARCHIVE)/$(HOST_PYTHON_SRC):
	$(DOWNLOAD) https://www.python.org/ftp/python/$(HOST_PYTHON_VER)/$(HOST_PYTHON_SRC)

$(D)/host_python: $(ARCHIVE)/$(HOST_PYTHON_SRC)
	$(START_BUILD)
	$(REMOVE)/Python-$(HOST_PYTHON_VER)
	$(UNTAR)/$(HOST_PYTHON_SRC)
	$(CHDIR)/Python-$(HOST_PYTHON_VER); \
		$(call apply_patches, $(HOST_PYTHON_PATCH)); \
		autoconf; \
		CONFIG_SITE= \
		OPT="$(HOST_CFLAGS)" \
		./configure \
			--without-cxx-main \
			--with-threads \
		; \
		$(MAKE) python Parser/pgen; \
		mv python ./hostpython; \
		mv Parser/pgen ./hostpgen; \
		\
		$(MAKE) distclean; \
		./configure \
			--prefix=$(HOST_DIR) \
			--sysconfdir=$(HOST_DIR)/etc \
			--without-cxx-main \
			--with-threads \
		; \
		$(MAKE) all install; \
		cp ./hostpgen $(HOST_DIR)/bin/pgen
	$(REMOVE)/Python-$(HOST_PYTHON_VER)
	$(TOUCH)
	
#
# host_mtools
#
HOST_MTOOLS_VER = 4.0.49
HOST_MTOOLS_SRC = mtools-$(HOST_MTOOLS_VER).tar.gz

$(ARCHIVE)/$(HOST_MTOOLS_SRC):
	$(DOWNLOAD) http://ftp.gnu.org/gnu/mtools/$(HOST_MTOOLS_SRC)

$(D)/host_mtools: $(D)/directories $(ARCHIVE)/$(HOST_MTOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/mtools-$(HOST_MTOOLS_VER)
	$(UNTAR)/$(HOST_MTOOLS_SRC)
	$(CHDIR)/mtools-$(HOST_MTOOLS_VER); \
		./configure \
			--prefix=$(HOST_DIR) \
			ac_cv_lib_bsd_gethostbyname=no \
			ac_cv_lib_bsd_main=no \
			ac_cv_path_INSTALL_INFO= \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/mtools-$(HOST_MTOOLS_VER)
	$(TOUCH)

#
# host_dosfstools
#
HOST_DOSFSTOOLS_VER = 4.2
HOST_DOSFSTOOLS_SRC = dosfstools-$(HOST_DOSFSTOOLS_VER).tar.gz

$(ARCHIVE)/$(HOST_DOSFSTOOLS_SRC):
	$(DOWNLOAD) https://github.com/dosfstools/dosfstools/releases/download/v$(HOST_DOSFSTOOLS_VER)/$(HOST_DOSFSTOOLS_SRC)

$(D)/host_dosfstools: $(D)/directories $(ARCHIVE)/$(HOST_DOSFSTOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/dosfstools-$(HOST_DOSFSTOOLS_VER)
	$(UNTAR)/$(HOST_DOSFSTOOLS_SRC)
	$(CHDIR)/dosfstools-$(HOST_DOSFSTOOLS_VER); \
		./configure \
			--prefix=$(HOST_DIR) \
			--enable-compat-symlinks \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/dosfstools-$(HOST_DOSFSTOOLS_VER)
	$(TOUCH)

#
# host_flashtool-fup
#
$(D)/host_flashtool-fup: $(D)/directories
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/flashtool-fup; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# host_flashtool-mup
#
$(D)/host_flashtool-mup: $(D)/directories
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/flashtool-mup; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# host_flashtool-pad
#
$(D)/host_flashtool-pad: $(D)/directories
	$(START_BUILD)
	set -e; cd $(TOOLS_DIR)/flashtool-pad; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# bootstrap
#
BOOTSTRAP  = $(D)/directories
BOOTSTRAP += $(D)/ccache
BOOTSTRAP += $(CROSSTOOL)
BOOTSTRAP += $(TARGET_DIR)/lib/libc.so.6
BOOTSTRAP += $(D)/host_pkgconfig
BOOTSTRAP += $(D)/host_module_init_tools
BOOTSTRAP += $(D)/host_mtd_utils
BOOTSTRAP += $(D)/host_e2fsprogs
BOOTSTRAP += $(D)/host_parted
BOOTSTRAP += $(D)/host_mtools
BOOTSTRAP += $(D)/host_dosfstools
BOOTSTRAP += $(D)/host_mksquashfs_lzma
ifeq ($(BOXARCH), sh4)
BOOTSTRAP += $(D)/host_u_boot_tools
BOOTSTRAP += $(D)/host_flashtool-fup
BOOTSTRAP += $(D)/host_flashtool-mup
BOOTSTRAP += $(D)/host_flashtool-pad
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), dm8000 dm7020hd dm7020hdv2 dm800se dm800sev2))
BOOTSTRAP += $(D)/host_dm_buildimage
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd60 hd61 hd66se multibox multiboxse))
BOOTSTRAP += $(D)/host_atools
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), sf8008 sf8008m ustym4kpro ustym4ks2ottx gbtrio4k gbtrio4kpro gbip4k))
BOOTSTRAP += $(D)/host_hisi3798mv200_buildimage
endif
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips x86_64))	
BOOTSTRAP += $(D)/host_python 
endif

$(D)/bootstrap: $(BOOTSTRAP)
	@touch $@	

#
# directories
#
ifneq ($(BOXTYPE),)
$(D)/directories:
	$(START_BUILD)
	test -d $(ARCHIVE) || mkdir $(ARCHIVE)
	test -d $(BASE_DIR)/builds || mkdir $(BASE_DIR)/builds
	test -d $(BASE_DIR)/builds/$(BOXTYPE) || mkdir $(BASE_DIR)/builds/$(BOXTYPE)
	test -d $(D) || mkdir $(D)
	test -d $(BUILD_TMP) || mkdir $(BUILD_TMP)
	test -d $(SOURCE_DIR) || mkdir $(SOURCE_DIR)
	install -d $(CROSS_DIR)
	install -d $(HOST_DIR)
	install -d $(HOST_DIR)/{bin,lib,share}
	install -d $(IMAGE_DIR)
	install -d $(PKGS_DIR)
	install -d $(TARGET_DIR)
	install -d $(TARGET_DIR)/{bin,boot,etc,lib,sbin,usr,var}
	install -d $(TARGET_DIR)/etc/{init.d,mdev,network,rc.d,default,samba}
	install -d $(TARGET_DIR)/etc/rc.d/{rc0.d,rc6.d}
	ln -sf ../init.d $(TARGET_DIR)/etc/rc.d/init.d
	install -d $(TARGET_DIR)/lib/{lsb,firmware}
	install -d $(TARGET_DIR)/usr/{bin,lib,sbin,share}
ifeq ($(BOXARCH), x86_64)	
	cd $(TARGET_DIR) && ln -sf lib lib64
	cd $(TARGET_DIR)/usr && ln -sf lib lib64
endif
	install -d $(TARGET_DIR)/usr/lib/pkgconfig
	install -d $(TARGET_DIR)/usr/include/linux
	install -d $(TARGET_DIR)/usr/include/linux/dvb
	install -d $(TARGET_DIR)/var/{lib,run}
	install -d $(TARGET_DIR)/var/lib/{misc,nfs,opkg}
	install -d $(TARGET_DIR)/var/bin
	$(TOUCH)
endif	

#
# ccache
#
CCACHE_BINDIR = $(HOST_DIR)/bin
CCACHE_BIN = $(CCACHE)

CCACHE_LINKS = \
	ln -sf $(CCACHE_BIN) $(CCACHE_BINDIR)/cc; \
	ln -sf $(CCACHE_BIN) $(CCACHE_BINDIR)/gcc; \
	ln -sf $(CCACHE_BIN) $(CCACHE_BINDIR)/g++; \
	ln -sf $(CCACHE_BIN) $(CCACHE_BINDIR)/$(TARGET)-gcc; \
	ln -sf $(CCACHE_BIN) $(CCACHE_BINDIR)/$(TARGET)-g++

CCACHE_ENV = install -d $(CCACHE_BINDIR); \
	$(CCACHE_LINKS)

$(D)/ccache: directories
	$(CCACHE_ENV)
	touch $@

# hack to make sure they are always copied
PHONY += ccache

