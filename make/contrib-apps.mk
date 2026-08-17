#
# busybox
#
BUSYBOX_VER = 1.36.1
BUSYBOX_SRC = busybox-$(BUSYBOX_VER).tar.bz2
BUSYBOX_URL = https://busybox.net/downloads

BUSYBOX_PATCH  = busybox-$(BUSYBOX_VER)-nandwrite.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-unicode.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-extra.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-extra2.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-flashcp-small-output.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-block-telnet-internet.patch
BUSYBOX_PATCH += busybox-$(BUSYBOX_VER)-recursive_action-fix.patch

BUSYBOX_CONFIG = busybox-$(BUSYBOX_VER).config

$(ARCHIVE)/$(BUSYBOX_SRC):
	$(DOWNLOAD) $(BUSYBOX_URL)/$(BUSYBOX_SRC)

$(D)/busybox: $(D)/bootstrap $(ARCHIVE)/$(BUSYBOX_SRC) $(PATCHES)/$(BUSYBOX_CONFIG)
	$(START_BUILD)
	$(REMOVE)/busybox-$(BUSYBOX_VER)
	$(UNTAR)/$(BUSYBOX_SRC)
	$(CHDIR)/busybox-$(BUSYBOX_VER); \
		$(call apply_patches, $(BUSYBOX_PATCH)); \
		install -m 0644 $(lastword $^) .config; \
		sed -i -e 's#^CONFIG_PREFIX.*#CONFIG_PREFIX="$(TARGET_DIR)"#' .config; \
		sed -i -e 's#^CONFIG_EXTRA_CFLAGS.*#CONFIG_EXTRA_CFLAGS="$(BUSYBOX_EXTRA_CFLAGS)"#' .config; \
		sed -i -e 's#^CONFIG_EXTRA_LDFLAGS.*#CONFIG_EXTRA_LDFLAGS="$(BUSYBOX_EXTRA_LDFLAGS)"#' .config; \
		sed -i -e 's#^CONFIG_EXTRA_LDLIBS.*#CONFIG_EXTRA_LDLIBS="$(BUSYBOX_EXTRA_LDLIBS)"#' .config; \
		$(BUILDENV) \
		$(MAKE) busybox CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)"; \
		$(MAKE) install CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)" CONFIG_PREFIX=$(TARGET_DIR)
	$(REMOVE)/busybox-$(BUSYBOX_VER)
	$(TOUCH)

#
# busybox-menuconfig
#	
busybox-menuconfig: $(D)/bootstrap $(ARCHIVE)/$(BUSYBOX_SRC) $(PATCHES)/$(BUSYBOX_CONFIG)
	$(REMOVE)/busybox-$(BUSYBOX_VER)
	$(UNTAR)/$(BUSYBOX_SRC)
	$(CHDIR)/busybox-$(BUSYBOX_VER); \
		$(call apply_patches, $(BUSYBOX_PATCH)); \
		install -m 0644 $(lastword $^) .config; \
		sed -i -e 's#^CONFIG_PREFIX.*#CONFIG_PREFIX="$(TARGET_DIR)"#' .config; \
		$(MAKE) menuconfig

#
# sysvinit
#
SYSVINIT_VER = 3.06
SYSVINIT_SRC = sysvinit-$(SYSVINIT_VER).tar.xz
SYSVINIT_URL = https://github.com/slicer69/sysvinit/releases/download/$(SYSVINIT_VER)

SYSVINIT_PATCH  = sysvinit-$(SYSVINIT_VER)-crypt-lib.patch
SYSVINIT_PATCH += sysvinit-$(SYSVINIT_VER)-change-INIT_FIFO.patch
SYSVINIT_PATCH += sysvinit-$(SYSVINIT_VER)-remove-killall5.patch

$(ARCHIVE)/$(SYSVINIT_SRC):
	$(DOWNLOAD) $(SYSVINIT_URL)/$(SYSVINIT_SRC)

$(D)/sysvinit: $(D)/bootstrap $(ARCHIVE)/$(SYSVINIT_SRC)
	$(START_BUILD)
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	$(UNTAR)/$(SYSVINIT_SRC)
	$(CHDIR)/sysvinit-$(SYSVINIT_VER); \
		$(call apply_patches, $(SYSVINIT_PATCH)); \
		sed -i -e 's/\ sulogin[^ ]*//' -e 's/pidof\.8//' -e '/ln .*pidof/d' \
		-e '/bootlogd/d' -e '/utmpdump/d' -e '/mountpoint/d' -e '/mesg/d' src/Makefile; \
		$(BUILDENV) \
		$(MAKE) -C src SULOGINLIBS=-lcrypt; \
		$(MAKE) install ROOT=$(TARGET_DIR) MANDIR=/.remove
	rm -f $(addprefix $(TARGET_DIR)/sbin/,fstab-decode runlevel telinit)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,lastb)
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), fortis_hdbox octagon1008 cuberevo cuberevo_mini2 cuberevo_2000hd))
	install -m 644 $(SKEL_ROOT)/etc/inittab_ttyAS1 $(TARGET_DIR)/etc/inittab
else
	install -m 644 $(SKEL_ROOT)/etc/inittab $(TARGET_DIR)/etc/inittab
endif
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	$(TOUCH)

#
# mtd_utils
#
MTD_UTILS_VER = 1.5.2
MTD_UTILS_SRC = mtd-utils-$(MTD_UTILS_VER).tar.bz2

MTD_UTILS_PATCH = host-mtd-utils-$(MTD_UTILS_VER).patch
MTD_UTILS_PATCH += host-mtd-utils-$(MTD_UTILS_VER)-sysmacros.patch

$(D)/mtd_utils: $(D)/bootstrap $(D)/zlib $(D)/lzo $(D)/e2fsprogs $(ARCHIVE)/$(HOST_MTD_UTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(UNTAR)/$(MTD_UTILS_SRC)
	$(CHDIR)/mtd-utils-$(MTD_UTILS_VER); \
		$(call apply_patches, $(MTD_UTILS_PATCH)); \
		$(BUILDENV) \
		$(MAKE) PREFIX= CC=$(TARGET)-gcc LD=$(TARGET)-ld STRIP=$(TARGET)-strip WITHOUT_XATTR=1 DESTDIR=$(TARGET_DIR); \
		cp -a $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER)/mkfs.jffs2 $(TARGET_DIR)/usr/sbin
		cp -a $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER)/sumtool $(TARGET_DIR)/usr/sbin
#		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(TOUCH)

#
# module_init_tools
#
MODULE_INIT_TOOLS_VER = 3.16
MODULE_INIT_TOOLS_SRC = module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2

MODULE_INIT_TOOLS_PATCH = module-init-tools-$(MODULE_INIT_TOOLS_VER).patch

$(D)/module_init_tools: $(D)/bootstrap $(ARCHIVE)/$(HOST_MODULE_INIT_TOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(UNTAR)/$(MODULE_INIT_TOOLS_SRC)
	$(CHDIR)/module-init-tools-$(MODULE_INIT_TOOLS_VER); \
		$(call apply_patches, $(MODULE_INIT_TOOLS_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix= \
			--program-suffix="" \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-builddir \
		; \
		$(MAKE); \
		$(MAKE) install sbin_PROGRAMS="depmod modinfo modprobe" bin_PROGRAMS= DESTDIR=$(TARGET_DIR)
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(TOUCH)

#
# e2fsprogs
#
E2FSPROGS_VER = 1.47.3
E2FSPROGS_SRC = e2fsprogs-$(E2FSPROGS_VER).tar.gz
E2FSPROGS_URL = https://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v$(E2FSPROGS_VER)

E2FSPROGS_PATCH = e2fsprogs-$(E2FSPROGS_VER).patch

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
E2FSPROGS_ARGS = --enable-resizer
else
E2FSPROGS_ARGS = --disable-resizer
endif

$(ARCHIVE)/$(E2FSPROGS_SRC):
	$(DOWNLOAD) $(E2FSPROGS_URL)/$(E2FSPROGS_SRC)

$(D)/e2fsprogs: $(D)/bootstrap $(D)/util_linux $(ARCHIVE)/$(E2FSPROGS_SRC)
	$(START_BUILD)
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	$(UNTAR)/$(E2FSPROGS_SRC)
	$(CHDIR)/e2fsprogs-$(E2FSPROGS_VER); \
		$(call apply_patches, $(E2FSPROGS_PATCH)); \
		PATH=$(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER):$(PATH) \
		$(CONFIGURE) \
			--prefix=/usr \
			--libdir=/usr/lib \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-rpath \
			--disable-profile \
			--disable-testio-debug \
			--disable-defrag \
			--disable-jbd-debug \
			--disable-blkid-debug \
			--disable-testio-debug \
			--disable-debugfs \
			--disable-imager \
			$(E2FSPROGS_ARGS) \
			--disable-backtrace \
			--disable-nls \
			--disable-mmp \
			--disable-tdb \
			--disable-bmap-stats \
			--disable-fuse2fs \
			--disable-bmap-stats \
			--disable-bmap-stats-ops \
			--enable-e2initrd-helper \
			--enable-elf-shlibs \
			--enable-fsck \
			--enable-libblkid \
			--enable-libuuid \
			--enable-verbose-makecmds \
			--enable-symlink-install \
			--without-libintl-prefix \
			--without-libiconv-prefix \
			--with-root-prefix="" \
			--with-gnu-ld \
			--with-crond-dir=no \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR); \
		$(MAKE) -C lib/uuid  install DESTDIR=$(TARGET_DIR); \
		$(MAKE) -C lib/blkid install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/uuid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/blkid.pc
	rm -f $(addprefix $(TARGET_DIR)/sbin/,badblocks dumpe2fs logsave e2undo)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,filefrag e2freefrag mklost+found uuidd e4crypt)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,chattr lsattr uuidgen)
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	$(TOUCH)

#
# util_linux
#
UTIL_LINUX_MAJOR = 2.41
UTIL_LINUX_MINOR = 2
UTIL_LINUX_VER = $(UTIL_LINUX_MAJOR).$(UTIL_LINUX_MINOR)
UTIL_LINUX_SRC = util-linux-$(UTIL_LINUX_VER).tar.xz
UTIL_LINUX_URL = https://www.kernel.org/pub/linux/utils/util-linux/v$(UTIL_LINUX_MAJOR)

$(ARCHIVE)/$(UTIL_LINUX_SRC):
	$(DOWNLOAD) $(UTIL_LINUX_URL)/$(UTIL_LINUX_SRC)

$(D)/util_linux: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(UTIL_LINUX_SRC)
	$(START_BUILD)
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(UNTAR)/$(UTIL_LINUX_SRC)
	$(CHDIR)/util-linux-$(UTIL_LINUX_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-shared \
			--disable-gtk-doc \
			--disable-nls \
			--disable-rpath \
			--enable-libuuid \
			--disable-libblkid \
			--disable-libmount \
			--enable-libsmartcols \
			--disable-mount \
			--disable-partx \
			--disable-mountpoint \
			--disable-fallocate \
			--disable-unshare \
			--disable-nsenter \
			--disable-setpriv \
			--disable-eject \
			--disable-agetty \
			--disable-cramfs \
			--disable-bfs \
			--disable-minix \
			--disable-fdformat \
			--disable-hwclock \
			--disable-wdctl \
			--disable-switch_root \
			--disable-pivot_root \
			--enable-tunelp \
			--disable-kill \
			--disable-last \
			--disable-utmpdump \
			--disable-line \
			--disable-mesg \
			--disable-raw \
			--disable-rename \
			--disable-vipw \
			--disable-newgrp \
			--disable-chfn-chsh \
			--disable-login \
			--disable-login-chown-vcs \
			--disable-login-stat-mail \
			--disable-nologin \
			--disable-sulogin \
			--disable-su \
			--disable-runuser \
			--disable-ul \
			--disable-more \
			--disable-pg \
			--disable-setterm \
			--disable-schedutils \
			--disable-tunelp \
			--disable-wall \
			--disable-write \
			--disable-bash-completion \
			--disable-pylibmount \
			--disable-pg-bell \
			--disable-use-tty-group \
			--disable-makeinstall-chown \
			--disable-makeinstall-setuid \
			--without-audit \
			--without-ncurses \
			--without-ncursesw \
			--without-slang \
			--without-utempter \
			--disable-wall \
			--without-python \
			--disable-makeinstall-chown \
			--without-systemdsystemunitdir \
			--disable-year2038 \
			--disable-liblastlog2 \
		; \
		$(MAKE) sfdisk mkfs; \
		install -D -m 755 sfdisk $(TARGET_DIR)/sbin/sfdisk; \
		install -D -m 755 mkfs $(TARGET_DIR)/sbin/mkfs
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(TOUCH)

	
#
# vsftpd
#
VSFTPD_VER = 3.0.5
VSFTPD_SRC = vsftpd-$(VSFTPD_VER).tar.gz
VSFTPD_URL = https://security.appspot.com/downloads

VSFTPD_PATCH  = vsftpd-$(VSFTPD_VER).patch
VSFTPD_PATCH += vsftpd-$(VSFTPD_VER)-find_libs.patch

$(ARCHIVE)/$(VSFTPD_SRC):
	$(DOWNLOAD) $(VSFTPD_URL)/$(VSFTPD_SRC)

$(D)/vsftpd: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(VSFTPD_SRC)
	$(START_BUILD)
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(UNTAR)/$(VSFTPD_SRC)
	$(CHDIR)/vsftpd-$(VSFTPD_VER); \
		$(call apply_patches, $(VSFTPD_PATCH)); \
		$(MAKE) clean; \
		$(MAKE) $(BUILDENV); \
		$(MAKE) install PREFIX=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/vsftpd $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/vsftpd.conf $(TARGET_DIR)/etc/
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(TOUCH)

#
# opkg
#
OPKG_VER = 0.3.3
OPKG_SRC = opkg-$(OPKG_VER).tar.gz
OPKG_URL = https://downloads.yoctoproject.org/releases/opkg

OPKG_PATCH = opkg-$(OPKG_VER).patch

$(ARCHIVE)/$(OPKG_SRC):
	$(DOWNLOAD) $(OPKG_URL)/$(OPKG_SRC)
	
$(D)/opkg: $(D)/bootstrap $(D)/libarchive $(ARCHIVE)/$(OPKG_SRC)
	$(START_BUILD)
	$(REMOVE)/opkg-$(OPKG_VER)
	$(UNTAR)/$(OPKG_SRC)
	$(CHDIR)/opkg-$(OPKG_VER); \
		$(call apply_patches, $(OPKG_PATCH)); \
		LIBARCHIVE_LIBS="-L$(TARGET_DIR)/usr/lib -larchive" \
		LIBARCHIVE_CFLAGS="-I$(TARGET_DIR)/usr/include" \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-curl \
			--disable-gpg \
			--mandir=/.remove \
		; \
		$(MAKE) all ; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -d -m 0755 $(TARGET_DIR)/usr/lib/opkg
	install -d -m 0755 $(TARGET_DIR)/etc/opkg
	ln -sf opkg $(TARGET_DIR)/usr/bin/opkg-cl
	$(REWRITE_LIBTOOL)/libopkg.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libopkg.pc
	$(REMOVE)/opkg-$(OPKG_VER)
	$(TOUCH)

#
# lsb
#
LSB_MAJOR = 3.2
LSB_MINOR = 20
LSB_VER = $(LSB_MAJOR)-$(LSB_MINOR)
LSB_SRC = lsb_$(LSB_VER).tar.gz
LSB_URL = https://debian.sdinet.de/etch/sdinet/lsb

$(ARCHIVE)/$(LSB_SRC):
	$(DOWNLOAD) $(LSB_URL)/$(LSB_SRC)

$(D)/lsb: $(D)/bootstrap $(ARCHIVE)/$(LSB_SRC)
	$(START_BUILD)
	$(REMOVE)/lsb-$(LSB_MAJOR)
	$(UNTAR)/$(LSB_SRC)
	$(CHDIR)/lsb-$(LSB_MAJOR); \
		install -m 0644 init-functions $(TARGET_DIR)/lib/lsb
	$(REMOVE)/lsb-$(LSB_MAJOR)
	$(TOUCH)

#
# portmap
#
PORTMAP_VER = 6.0.0
PORTMAP_SRC = portmap_$(PORTMAP_VER).orig.tar.gz
PORTMAP_URL = https://debian-archive.anexia.at/debian/pool/main/p/portmap

PORTMAP_PATCH = portmap-$(PORTMAP_VER).patch

$(ARCHIVE)/$(PORTMAP_SRC):
	$(DOWNLOAD) $(PORTMAP_URL)/$(PORTMAP_SRC)

$(D)/portmap: $(D)/bootstrap $(ARCHIVE)/$(PORTMAP_SRC) $(PATCHES)/portmap_$(PORTMAP_VER)-3.diff.gz
	$(START_BUILD)
	$(REMOVE)/portmap-$(PORTMAP_VER)
	$(UNTAR)/$(PORTMAP_SRC)
	$(CHDIR)/portmap-$(PORTMAP_VER); \
		gunzip -cd $(lastword $^) | cat > debian.patch; \
		patch -p1 <debian.patch && \
		sed -e 's/### BEGIN INIT INFO/# chkconfig: S 41 10\n### BEGIN INIT INFO/g' -i debian/init.d; \
		$(call apply_patches, $(PORTMAP_PATCH)); \
		$(BUILDENV) $(MAKE) NO_TCP_WRAPPER=1 DAEMON_UID=65534 DAEMON_GID=65535 CC="$(TARGET)-gcc"; \
		install -m 0755 portmap $(TARGET_DIR)/sbin; \
		install -m 0755 pmap_dump $(TARGET_DIR)/sbin; \
		install -m 0755 pmap_set $(TARGET_DIR)/sbin; \
		install -m755 debian/init.d $(TARGET_DIR)/etc/init.d/portmap
		cp -a $(SKEL_ROOT)/lib/lsb/init-functions $(TARGET_DIR)/lib/lsb
	$(REMOVE)/portmap-$(PORTMAP_VER)
	$(TOUCH)

#
# gptfdisk
#
GPTFDISK_VER = 1.0.4
GPTFDISK_SRC = gptfdisk-$(GPTFDISK_VER).tar.gz
GPTFDISK_URL = https://sourceforge.net/projects/gptfdisk/files/gptfdisk/$(GPTFDISK_VER)

$(ARCHIVE)/$(GPTFDISK_SRC):
	$(DOWNLOAD) $(GPTFDISK_URL)/$(GPTFDISK_SRC)

$(D)/gptfdisk: $(D)/bootstrap $(D)/e2fsprogs $(D)/ncurses $(D)/libpopt $(ARCHIVE)/$(GPTFDISK_SRC)
	$(START_BUILD)
	$(REMOVE)/gptfdisk-$(GPTFDISK_VER)
	$(UNTAR)/$(GPTFDISK_SRC)
	$(CHDIR)/gptfdisk-$(GPTFDISK_VER); \
		$(BUILDENV) \
		$(MAKE) sgdisk; \
		install -m755 sgdisk $(TARGET_DIR)/usr/sbin/sgdisk
	$(REMOVE)/gptfdisk-$(GPTFDISK_VER)
	$(TOUCH)

#
# parted
#
$(D)/parted: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(HOST_PARTED_SRC)
	$(START_BUILD)
	$(REMOVE)/parted-$(HOST_PARTED_VER)
	$(UNTAR)/$(HOST_PARTED_SRC)
	$(CHDIR)/parted-$(HOST_PARTED_VER); \
		$(call apply_patches, $(HOST_PARTED_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--without-readline \
			--disable-shared \
			--disable-dynamic-loading \
			--disable-debug \
			--disable-device-mapper \
			--disable-nls \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libparted.pc
	$(REWRITE_LIBTOOL)/libparted.la
	$(REWRITE_LIBTOOL)/libparted-fs-resize.la
	$(REMOVE)/parted-$(HOST_PARTED_VER)
	$(TOUCH)

#
# dosfstools
#
DOSFSTOOLS_VER = 4.1
DOSFSTOOLS_SRC = dosfstools-$(DOSFSTOOLS_VER).tar.xz
DOSFSTOOLS_URL = https://github.com/dosfstools/dosfstools/releases/download/v$(DOSFSTOOLS_VER)

$(ARCHIVE)/$(DOSFSTOOLS_SRC):
	$(DOWNLOAD) $(DOSFSTOOLS_URL)/$(DOSFSTOOLS_SRC)

DOSFSTOOLS_CFLAGS = $(TARGET_CFLAGS) -D_GNU_SRC -fomit-frame-pointer -D_FILE_OFFSET_BITS=64

$(D)/dosfstools: bootstrap $(ARCHIVE)/$(DOSFSTOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/dosfstools-$(DOSFSTOOLS_VER)
	$(UNTAR)/$(DOSFSTOOLS_SRC)
	$(CHDIR)/dosfstools-$(DOSFSTOOLS_VER); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--docdir=/.remove \
			--without-udev \
			--enable-compat-symlinks \
			CFLAGS="$(DOSFSTOOLS_CFLAGS)" \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dosfstools-$(DOSFSTOOLS_VER)
	$(TOUCH)

#
# jfsutils
#
JFSUTILS_VER = 1.1.15
JFSUTILS_SRC = jfsutils-$(JFSUTILS_VER).tar.gz
JFSUTILS_URL = http://jfs.sourceforge.net/project/pub

JFSUTILS_PATCH = jfsutils-$(JFSUTILS_VER).patch
JFSUTILS_PATCH += jfsutils-$(JFSUTILS_VER)-gcc10_fix.patch

$(ARCHIVE)/$(JFSUTILS_SRC):
	$(DOWNLOAD) $(JFSUTILS_URL)/$(JFSUTILS_SRC)

$(D)/jfsutils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(JFSUTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	$(UNTAR)/$(JFSUTILS_SRC)
	$(CHDIR)/jfsutils-$(JFSUTILS_VER); \
		$(call apply_patches, $(JFSUTILS_PATCH)); \
		sed "s@<unistd.h>@&\n#include <sys/types.h>@g" -i fscklog/extract.c; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix= \
			--target=$(TARGET) \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,jfs_debugfs jfs_fscklog jfs_logdump)
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	$(TOUCH)

#
# ntfs-3g
#
NTFS_3G_VER = 2022.10.3
NTFS_3G_SRC = ntfs-3g_ntfsprogs-$(NTFS_3G_VER).tgz
NTFS_3G_URL = http://tuxera.com/opensource

$(ARCHIVE)/$(NTFS_3G_SRC):
	$(DOWNLOAD) $(NTFS_3G_URL)/$(NTFS_3G_SRC)

$(D)/ntfs_3g: $(D)/bootstrap $(ARCHIVE)/$(NTFS_3G_SRC)
	$(START_BUILD)
	$(REMOVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER)
	$(UNTAR)/$(NTFS_3G_SRC)
	$(CHDIR)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--exec-prefix=/usr \
			--bindir=/usr/bin \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-ldconfig \
			--disable-static \
			--disable-ntfsprogs \
			--enable-silent-rules \
			--with-fuse=internal \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libntfs-3g.pc
	$(REWRITE_LIBTOOL)/libntfs-3g.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,lowntfs-3g ntfs-3g.probe)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,mount.lowntfs-3g)
	$(REMOVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER)
	$(TOUCH)

#
# rsync
#
RSYNC_VER = 3.1.3
RSYNC_SRC = rsync-$(RSYNC_VER).tar.gz
RSYNC_URL = https://ftp.samba.org/pub/rsync

$(ARCHIVE)/$(RSYNC_SRC):
	$(DOWNLOAD) $(RSYNC_URL)/$(RSYNC_SRC)

$(D)/rsync: $(D)/bootstrap $(ARCHIVE)/$(RSYNC_SRC)
	$(START_BUILD)
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(UNTAR)/$(RSYNC_SRC)
	$(CHDIR)/rsync-$(RSYNC_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--disable-debug \
			--disable-locale \
		; \
		$(MAKE) all; \
		$(MAKE) install-all DESTDIR=$(TARGET_DIR)
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(TOUCH)

#
# fuse
#
FUSE_VER = 2.9.7
FUSE_SRC = fuse-$(FUSE_VER).tar.gz
FUSE_URL = https://github.com/libfuse/libfuse/releases/download/fuse-$(FUSE_VER)

$(ARCHIVE)/$(FUSE_SRC):
	$(DOWNLOAD) $(FUSE_URL)/$(FUSE_SRC)

$(D)/fuse: $(D)/bootstrap $(ARCHIVE)/$(FUSE_SRC)
	$(START_BUILD)
	$(REMOVE)/fuse-$(FUSE_VER)
	$(UNTAR)/$(FUSE_SRC)
	$(CHDIR)/fuse-$(FUSE_VER); \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -I$(KERNEL_DIR)/arch/sh" \
			--prefix=/usr \
			--exec-prefix=/usr \
			--disable-static \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		-rm $(TARGET_DIR)/etc/udev/rules.d/99-fuse.rules
		-rmdir $(TARGET_DIR)/etc/udev/rules.d
		-rmdir $(TARGET_DIR)/etc/udev
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fuse.pc
	$(REWRITE_LIBTOOL)/libfuse.la
	$(REWRITE_LIBTOOL)/libulockmgr.la
	$(REMOVE)/fuse-$(FUSE_VER)
	$(TOUCH)

#
# curlftpfs
#
CURLFTPFS_VER = 0.9.2
CURLFTPFS_SRC = curlftpfs-$(CURLFTPFS_VER).tar.gz
CURLFTPFS_URL = https://sourceforge.net/projects/curlftpfs/files/latest/download

CURLFTPFS_PATCH = curlftpfs-$(CURLFTPFS_VER).patch

$(ARCHIVE)/$(CURLFTPFS_SRC):
	$(DOWNLOAD) $(CURLFTPFS_URL)/$(CURLFTPFS_SRC)

$(D)/curlftpfs: $(D)/bootstrap $(D)/libcurl $(D)/fuse $(D)/libglib2 $(ARCHIVE)/$(CURLFTPFS_SRC)
	$(START_BUILD)
	$(REMOVE)/curlftpfs-$(CURLFTPFS_VER)
	$(UNTAR)/$(CURLFTPFS_SRC)
	$(CHDIR)/curlftpfs-$(CURLFTPFS_VER); \
		$(call apply_patches, $(CURLFTPFS_PATCH)); \
		export ac_cv_func_malloc_0_nonnull=yes; \
		export ac_cv_func_realloc_0_nonnull=yes; \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -I$(KERNEL_DIR)/arch/sh" \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/curlftpfs-$(CURLFTPFS_VER)
	$(TOUCH)

#
# sdparm
#
SDPARM_VER = 1.10
SDPARM_SRC = sdparm-$(SDPARM_VER).tgz
SDPARM_URL = http://sg.danny.cz/sg/p

$(ARCHIVE)/$(SDPARM_SRC):
	$(DOWNLOAD) $(SDPARM_URL)/$(SDPARM_SRC)

$(D)/sdparm: $(D)/bootstrap $(ARCHIVE)/$(SDPARM_SRC)
	$(START_BUILD)
	$(REMOVE)/sdparm-$(SDPARM_VER)
	$(UNTAR)/$(SDPARM_SRC)
	$(CHDIR)/sdparm-$(SDPARM_VER); \
		$(CONFIGURE) \
			--prefix= \
			--bindir=/sbin \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/sbin/,sas_disk_blink scsi_ch_swp)
	$(REMOVE)/sdparm-$(SDPARM_VER)
	$(TOUCH)

#
# hddtemp
#
HDDTEMP_VER = 0.3-beta15
HDDTEMP_SRC = hddtemp-$(HDDTEMP_VER).tar.bz2
HDDTEMP_URL = http://savannah.c3sl.ufpr.br/hddtemp

$(ARCHIVE)/$(HDDTEMP_SRC):
	$(DOWNLOAD) $(HDDTEMP_URL)/$(HDDTEMP_SRC)

$(D)/hddtemp: $(D)/bootstrap $(ARCHIVE)/$(HDDTEMP_SRC)
	$(START_BUILD)
	$(REMOVE)/hddtemp-$(HDDTEMP_VER)
	$(UNTAR)/$(HDDTEMP_SRC)
	$(CHDIR)/hddtemp-$(HDDTEMP_VER); \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--datadir=/.remove \
			--with-db_path=/var/hddtemp.db \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		install -d $(TARGET_DIR)/var/tuxbox/config
		install -m 644 $(SKEL_ROOT)/etc/hddtemp.db $(TARGET_DIR)/var
	$(REMOVE)/hddtemp-$(HDDTEMP_VER)
	$(TOUCH)

#
# hdparm
#
HDPARM_VER = 9.54
HDPARM_SRC = hdparm-$(HDPARM_VER).tar.gz
HDPARM_URL = https://sourceforge.net/projects/hdparm/files/hdparm

$(ARCHIVE)/$(HDPARM_SRC):
	$(DOWNLOAD) $(HDPARM_URL)/$(HDPARM_SRC)

$(D)/hdparm: $(D)/bootstrap $(ARCHIVE)/$(HDPARM_SRC)
	$(START_BUILD)
	$(REMOVE)/hdparm-$(HDPARM_VER)
	$(UNTAR)/$(HDPARM_SRC)
	$(CHDIR)/hdparm-$(HDPARM_VER); \
		$(BUILDENV) \
		$(MAKE) CROSS=$(TARGET)- all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/hdparm-$(HDPARM_VER)
	$(TOUCH)

#
# hdidle
#
HDIDLE_VER = 1.05
HDIDLE_SRC = hd-idle-$(HDIDLE_VER).tgz
HDIDLE_URL = https://sourceforge.net/projects/hd-idle/files

HDIDLE_PATCH = hd-idle-$(HDIDLE_VER).patch

$(ARCHIVE)/$(HDIDLE_SRC):
	$(DOWNLOAD) $(HDIDLE_URL)/$(HDIDLE_SRC)

$(D)/hdidle: $(D)/bootstrap $(ARCHIVE)/$(HDIDLE_SRC)
	$(START_BUILD)
	$(REMOVE)/hd-idle
	$(UNTAR)/$(HDIDLE_SRC)
	$(CHDIR)/hd-idle; \
		$(call apply_patches, $(HDIDLE_PATCH)); \
		$(BUILDENV) \
		$(MAKE) CC=$(TARGET)-gcc; \
		$(MAKE) install TARGET_DIR=$(TARGET_DIR) install
	$(REMOVE)/hd-idle
	$(TOUCH)

#
# fbshot
#
FBSHOT_VER = 0.3
FBSHOT_SRC = fbshot-$(FBSHOT_VER).tar.gz
FBSHOT_URL = http://distro.ibiblio.org/amigolinux/download/Utils/fbshot

FBSHOT_PATCH = fbshot-$(FBSHOT_VER)-$(BOXARCH).patch

$(ARCHIVE)/$(FBSHOT_SRC):
	$(DOWNLOAD) $(FBSHOT_URL)/$(FBSHOT_SRC)

$(D)/fbshot: $(D)/bootstrap $(D)/libpng $(ARCHIVE)/$(FBSHOT_SRC)
	$(START_BUILD)
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(UNTAR)/$(FBSHOT_SRC)
	$(CHDIR)/fbshot-$(FBSHOT_VER); \
		$(call apply_patches, $(FBSHOT_PATCH)); \
		sed -i s~'gcc'~"$(TARGET)-gcc $(TARGET_CFLAGS) $(TARGET_LDFLAGS)"~ Makefile; \
		sed -i 's/strip fbshot/$(TARGET)-strip fbshot/' Makefile; \
		$(MAKE) all; \
		install -D -m 755 fbshot $(TARGET_DIR)/usr/bin/fbshot
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(TOUCH)

#
# sysstat
#
SYSSTAT_VER = 12.6.1
SYSSTAT_SRC = sysstat-$(SYSSTAT_VER).tar.xz
SYSSTAT_URL = https://ftp.wrz.de/pub/BLFS/conglomeration/sysstat

$(ARCHIVE)/$(SYSSTAT_SRC):
	$(DOWNLOAD) $(SYSSTAT_URL)/$(SYSSTAT_SRC)

$(D)/sysstat: $(D)/bootstrap $(ARCHIVE)/$(SYSSTAT_SRC)
	$(START_BUILD)
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	$(UNTAR)/$(SYSSTAT_SRC)
	$(CHDIR)/sysstat-$(SYSSTAT_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-documentation \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	$(TOUCH)

#
# autofs
#
AUTOFS_VER = 4.1.4
AUTOFS_SRC = autofs-$(AUTOFS_VER).tar.gz
AUTOFS_URL = https://www.kernel.org/pub/linux/daemons/autofs/v4

AUTOFS_PATCH = autofs-$(AUTOFS_VER).patch

$(ARCHIVE)/$(AUTOFS_SRC):
	$(DOWNLOAD) $(AUTOFS_URL)/$(AUTOFS_SRC)

ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
AUTOFS_LIBNSL = $(D)/libnsl
endif

$(D)/autofs: $(D)/bootstrap $(D)/e2fsprogs $(AUTOFS_LIBNSL) $(ARCHIVE)/$(AUTOFS_SRC)
	$(START_BUILD)
	$(REMOVE)/autofs-$(AUTOFS_VER)
	$(UNTAR)/$(AUTOFS_SRC)
	$(CHDIR)/autofs-$(AUTOFS_VER); \
		$(call apply_patches, $(AUTOFS_PATCH)); \
		cp aclocal.m4 acinclude.m4; \
		autoconf; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all CC=$(TARGET)-gcc STRIP=$(TARGET)-strip; \
		$(MAKE) install INSTALLROOT=$(TARGET_DIR) SUBDIRS="lib daemon modules"
	install -m 755 $(SKEL_ROOT)/etc/init.d/autofs $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/auto.hotplug $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.master $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.misc $(TARGET_DIR)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.network $(TARGET_DIR)/etc/
	ln -sf ../usr/sbin/automount $(TARGET_DIR)/sbin/automount
	$(REMOVE)/autofs-$(AUTOFS_VER)
	$(TOUCH)

#
# shairport
#
SHAIRPORT_SRC = shairport.git
SHAIRPORT_URL = https://github.com/abrasive/shairport.git

$(ARCHIVE)/$(SHAIRPORT_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(SHAIRPORT_SRC) ]; then \
		cd $(ARCHIVE)/$(SHAIRPORT_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone -b 1.0-dev $(SHAIRPORT_URL) $(SHAIRPORT_SRC); \
	fi

$(D)/shairport: $(D)/bootstrap $(D)/openssl $(D)/howl $(D)/alsa_lib $(ARCHIVE)/$(SHAIRPORT_SRC)
	$(START_BUILD)
	$(REMOVE)/shairport
	cp -ra $(ARCHIVE)/$(SHAIRPORT_SRC) $(BUILD_TMP)/shairport
	$(CHDIR)/shairport; \
		sed -i 's|pkg-config|$$PKG_CONFIG|g' configure; \
		PKG_CONFIG=$(PKG_CONFIG) \
		$(BUILDENV) \
		$(MAKE); \
		$(MAKE) install PREFIX=$(TARGET_DIR)/usr
	$(REMOVE)/shairport
	$(TOUCH)

#
# shairport-sync
#
SHAIRPORT_SYNC_SRC = shairport-sync.git
SHAIRPORT_SYNC_URL = https://github.com/mikebrady/shairport-sync.git

$(ARCHIVE)/$(SHAIRPORT_SYNC_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(SHAIRPORT_SYNC_SRC) ]; then \
		cd $(ARCHIVE)/$(SHAIRPORT_SYNC_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(SHAIRPORT_SYNC_URL) $(SHAIRPORT_SYNC_SRC); \
	fi

$(D)/shairport-sync: $(D)/bootstrap $(D)/libdaemon $(D)/libpopt $(D)/libconfig $(D)/openssl $(D)/alsa_lib
	$(START_BUILD)
	$(REMOVE)/shairport-sync
	cp -ra $(ARCHIVE)/$(SHAIRPORT_SYNC_SRC) $(BUILD_TMP)/shairport-sync
	$(CHDIR)/shairport-sync; \
		autoreconf -fi; \
		PKG_CONFIG=$(PKG_CONFIG) \
		$(BUILDENV) \
		$(CONFIGURE) \
			--prefix=/usr \
			--with-alsa \
			--with-ssl=openssl \
			--with-metadata \
			--with-tinysvcmdns \
			--with-pipe \
			--with-stdout \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/shairport-sync
	$(TOUCH)

#
# dbus
#
DBUS_VER = 1.12.6
DBUS_SRC = dbus-$(DBUS_VER).tar.gz
DBUS_URL = https://dbus.freedesktop.org/releases/dbus

$(ARCHIVE)/$(DBUS_SRC):
	$(DOWNLOAD) $(DBUS_URL)/$(DBUS_SRC)

$(D)/dbus: $(D)/bootstrap $(D)/expat $(ARCHIVE)/$(DBUS_SRC)
	$(START_BUILD)
	$(REMOVE)/dbus-$(DBUS_VER)
	$(UNTAR)/$(DBUS_SRC)
	$(CHDIR)/dbus-$(DBUS_VER); \
		$(CONFIGURE) \
		CFLAGS="$(TARGET_CFLAGS) -Wno-cast-align" \
			--without-x \
			--prefix=/usr \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-console-auth-dir=/run/console/ \
			--without-systemdsystemunitdir \
			--disable-systemd \
			--disable-static \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dbus-1.pc
	$(REWRITE_LIBTOOL)/libdbus-1.la
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,dbus-cleanup-sockets dbus-daemon dbus-launch dbus-monitor)
	$(REMOVE)/dbus-$(DBUS_VER)
	$(TOUCH)

#
# avahi
#
AVAHI_VER = 0.7
AVAHI_SRC = avahi-$(AVAHI_VER).tar.gz
AVAHI_URL = https://github.com/lathiat/avahi/releases/download/v$(AVAHI_VER)

$(ARCHIVE)/$(AVAHI_SRC):
	$(DOWNLOAD) $(AVAHI_URL)/$(AVAHI_SRC)

$(D)/avahi: $(D)/bootstrap $(D)/expat $(D)/libdaemon $(D)/dbus $(ARCHIVE)/$(AVAHI_SRC)
	$(START_BUILD)
	$(REMOVE)/avahi-$(AVAHI_VER)
	$(UNTAR)/$(AVAHI_SRC)
	$(CHDIR)/avahi-$(AVAHI_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--target=$(TARGET) \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-distro=none \
			--with-avahi-user=nobody \
			--with-avahi-group=nogroup \
			--with-autoipd-user=nobody \
			--with-autoipd-group=nogroup \
			--with-xml=expat \
			--enable-libdaemon \
			--disable-nls \
			--disable-glib \
			--disable-gobject \
			--disable-qt3 \
			--disable-qt4 \
			--disable-gtk \
			--disable-gtk3 \
			--disable-dbm \
			--disable-gdbm \
			--disable-python \
			--disable-pygtk \
			--disable-python-dbus \
			--disable-mono \
			--disable-monodoc \
			--disable-autoipd \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--disable-doxygen-man \
			--disable-doxygen-rtf \
			--disable-doxygen-xml \
			--disable-doxygen-chm \
			--disable-doxygen-chi \
			--disable-doxygen-html \
			--disable-doxygen-ps \
			--disable-doxygen-pdf \
			--disable-core-docs \
			--disable-manpages \
			--disable-xmltoman \
			--disable-tests \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/avahi-core.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/avahi-client.pc
	$(REWRITE_LIBTOOL)/libavahi-common.la
	$(REWRITE_LIBTOOL)/libavahi-core.la
	$(REWRITE_LIBTOOL)/libavahi-client.la
	$(REMOVE)/avahi-$(AVAHI_VER)
	$(TOUCH)

#
# wget
#
WGET_VER = 1.19.5
WGET_SRC = wget-$(WGET_VER).tar.gz
WGET_URL = https://ftp.gnu.org/gnu/wget

$(ARCHIVE)/$(WGET_SRC):
	$(DOWNLOAD) $(WGET_URL)/$(WGET_SRC)

$(D)/wget: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(WGET_SRC)
	$(START_BUILD)
	$(REMOVE)/wget-$(WGET_VER)
	$(UNTAR)/$(WGET_SRC)
	$(CHDIR)/wget-$(WGET_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--with-openssl \
			--with-ssl=openssl \
			--with-libssl-prefix=$(TARGET_DIR) \
			--disable-ipv6 \
			--disable-debug \
			--disable-nls \
			--disable-opie \
			--disable-digest \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/wget-$(WGET_VER)
	$(TOUCH)

#
# coreutils
#
COREUTILS_VER = 8.23
COREUTILS_SRC = coreutils-$(COREUTILS_VER).tar.xz
COREUTILS_URL = https://ftp.gnu.org/gnu/coreutils

COREUTILS_PATCH = coreutils-$(COREUTILS_VER).patch

$(ARCHIVE)/$(COREUTILS_SRC):
	$(DOWNLOAD) $(COREUTILS_URL)/$(COREUTILS_SRC)

$(D)/coreutils: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/$(COREUTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	$(UNTAR)/$(COREUTILS_SRC)
	$(CHDIR)/coreutils-$(COREUTILS_VER); \
		$(call apply_patches, $(COREUTILS_PATCH)); \
		export fu_cv_sys_stat_statfs2_bsize=yes; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-largefile \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	$(TOUCH)

#
# smartmontools
#
SMARTMONTOOLS_VER = 6.6
SMARTMONTOOLS_SRC = smartmontools-$(SMARTMONTOOLS_VER).tar.gz
SMARTMONTOOLS_URL = https://sourceforge.net/projects/smartmontools/files/smartmontools/$(SMARTMONTOOLS_VER)

$(ARCHIVE)/$(SMARTMONTOOLS_SRC):
	$(DOWNLOAD) $(SMARTMONTOOLS_URL)/$(SMARTMONTOOLS_SRC)

$(D)/smartmontools: $(D)/bootstrap $(ARCHIVE)/$(SMARTMONTOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	$(UNTAR)/$(SMARTMONTOOLS_SRC)
	$(CHDIR)/smartmontools-$(SMARTMONTOOLS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=$(TARGET_DIR)/usr
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	$(TOUCH)

#
# nfs_utils
#
NFS_UTILS_VER = 2.5.3
NFS_UTILS_SRC = nfs-utils-$(NFS_UTILS_VER).tar.bz2
NFS_UTILS_URL = https://sourceforge.net/projects/nfs/files/nfs-utils/$(NFS_UTILS_VER)

NFS_UTILS_PATCH = nfs-utils-$(NFS_UTILS_VER).patch

$(ARCHIVE)/$(NFS_UTILS_SRC):
	$(DOWNLOAD) $(NFS_UTILS_URL)/$(NFS_UTILS_SRC)

$(D)/nfs_utils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/$(NFS_UTILS_SRC)
	$(START_BUILD)
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	$(UNTAR)/$(NFS_UTILS_SRC)
	$(CHDIR)/nfs-utils-$(NFS_UTILS_VER); \
		$(call apply_patches, $(NFS_UTILS_PATCH)); \
		$(CONFIGURE) \
			CC_FOR_BUILD=$(TARGET)-gcc \
			--prefix=/usr \
			--exec-prefix=/usr \
			--mandir=/.remove \
			--disable-gss \
			--enable-ipv6=no \
			--disable-tirpc \
			--disable-nfsv4 \
			--without-tcp-wrappers \
			--enable-silent-rules \
			--with-rpcgen \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-common $(TARGET_DIR)/etc/init.d/
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-kernel-server $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/exports $(TARGET_DIR)/etc/
	rm -f $(addprefix $(TARGET_DIR)/sbin/,mount.nfs mount.nfs4 umount.nfs umount.nfs4 osd_login)
	rm -f $(addprefix $(TARGET_DIR)/usr/sbin/,mountstats nfsiostat sm-notify start-statd)
	$(REMOVE)/nfs-utils-$(NFS_UTILS_VER)
	$(TOUCH)

#
# procps_ng
#
PROCPS_NG_VER = 3.3.12
PROCPS_NG_SRC = procps-ng-$(PROCPS_NG_VER).tar.xz
PROCPS_NG_URL = http://sourceforge.net/projects/procps-ng/files/Production

$(ARCHIVE)/$(PROCPS_NG_SRC):
	$(DOWNLOAD) $(PROCPS_NG_URL)/$(PROCPS_NG_SRC)

$(D)/procps_ng: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(PROCPS_NG_SRC)
	$(START_BUILD)
	$(REMOVE)/procps-ng-$(PROCPS_NG_VER)
	$(UNTAR)/$(PROCPS_NG_SRC)
	cd $(BUILD_TMP)/procps-ng-$(PROCPS_NG_VER); \
		export ac_cv_func_malloc_0_nonnull=yes; \
		export ac_cv_func_realloc_0_nonnull=yes; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix= \
		; \
		$(MAKE); \
		install -D -m 755 top/.libs/top $(TARGET_DIR)/bin/top; \
		install -D -m 755 ps/.libs/pscommand $(TARGET_DIR)/bin/ps; \
		cp -a proc/.libs/libprocps.so* $(TARGET_LIB_DIR)
	$(REMOVE)/procps-ng-$(PROCPS_NG_VER)
	$(TOUCH)

#
# ethtool
#
ETHTOOL_VER = 4.17
ETHTOOL_SRC = ethtool-$(ETHTOOL_VER).tar.xz
ETHTOOL_URL = https://www.kernel.org/pub/software/network/ethtool 

$(ARCHIVE)/$(ETHTOOL_SRC):
	$(DOWNLOAD) $(ETHTOOL_URL)/$(ETHTOOL_SRC)

$(D)/ethtool: $(D)/bootstrap $(ARCHIVE)/$(ETHTOOL_SRC)
	$(START_BUILD)
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	$(UNTAR)/$(ETHTOOL_SRC)
	$(CHDIR)/ethtool-$(ETHTOOL_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-pretty-dump \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	$(TOUCH)

#
# samba
#
SAMBA_VER = 3.6.25
SAMBA_SRC = samba-$(SAMBA_VER).tar.gz
SAMBA_URL = https://ftp.samba.org/pub/samba/stable

SAMBA_PATCH = \
	010-patch-cve-2015-5252.patch \
	011-patch-cve-2015-5296.patch \
	012-patch-cve-2015-5299.patch \
	015-patch-cve-2015-7560.patch \
	020-CVE-preparation-v3-6.patch \
	021-CVE-preparation-v3-6-addition.patch \
	022-CVE-2015-5370-v3-6.patch \
	023-CVE-2016-2110-v3-6.patch \
	024-CVE-2016-2111-v3-6.patch \
	025-CVE-2016-2112-v3-6.patch \
	026-CVE-2016-2115-v3-6.patch \
	027-CVE-2016-2118-v3-6.patch \
	028-CVE-2017-7494-v3-6.patch \
	100-configure_fixes.patch \
	110-multicall.patch \
	111-owrt_smbpasswd.patch \
	120-add_missing_ifdef.patch \
	200-remove_printer_support.patch \
	210-remove_ad_support.patch \
	220-remove_services.patch \
	230-remove_winreg_support.patch \
	240-remove_dfs_api.patch \
	250-remove_domain_logon.patch \
	260-remove_samr.patch \
	270-remove_registry_backend.patch \
	280-strip_srvsvc.patch \
	290-remove_lsa.patch \
	300-assert_debug_level.patch \
	310-remove_error_strings.patch \
	320-debug_level_checks.patch \
	330-librpc_default_print.patch \
	samba-3.6.25.patch

$(ARCHIVE)/$(SAMBA_SRC):
	$(DOWNLOAD) $(SAMBA_URL)/$(SAMBA_SRC)

$(D)/samba: $(D)/bootstrap $(ARCHIVE)/$(SAMBA_SRC)
	$(START_BUILD)
	$(REMOVE)/samba-$(SAMBA_VER)
	$(UNTAR)/$(SAMBA_SRC)
	$(CHDIR)/samba-$(SAMBA_VER); \
		$(call apply_patches, $(SAMBA_PATCH)); \
		cd source3; \
		./autogen.sh; \
		$(call apply_patches, samba-autoconf.patch); \
		$(BUILDENV) \
		ac_cv_lib_attr_getxattr=no \
		ac_cv_search_getxattr=no \
		ac_cv_file__proc_sys_kernel_core_pattern=yes \
		libreplace_cv_HAVE_C99_VSNPRINTF=yes \
		libreplace_cv_HAVE_GETADDRINFO=yes \
		libreplace_cv_HAVE_IFACE_IFCONF=yes \
		LINUX_LFS_SUPPORT=no \
		samba_cv_CC_NEGATIVE_ENUM_VALUES=yes \
		samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
		samba_cv_HAVE_IFACE_IFCONF=yes \
		samba_cv_HAVE_KERNEL_OPLOCKS_LINUX=yes \
		samba_cv_HAVE_SECURE_MKSTEMP=yes \
		libreplace_cv_HAVE_SECURE_MKSTEMP=yes \
		samba_cv_HAVE_WRFILE_KEYTAB=no \
		samba_cv_USE_SETREUID=yes \
		samba_cv_USE_SETRESUID=yes \
		samba_cv_have_setreuid=yes \
		samba_cv_have_setresuid=yes \
		samba_cv_optimize_out_funcation_calls=no \
		ac_cv_header_zlib_h=no \
		samba_cv_zlib_1_2_3=no \
		ac_cv_path_PYTHON="" \
		ac_cv_path_PYTHON_CONFIG="" \
		libreplace_cv_HAVE_GETADDRINFO=no \
		libreplace_cv_READDIR_NEEDED=no \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix= \
			--includedir=/usr/include \
			--exec-prefix=/usr \
			--disable-pie \
			--disable-avahi \
			--disable-cups \
			--disable-relro \
			--disable-swat \
			--disable-shared-libs \
			--disable-socket-wrapper \
			--disable-nss-wrapper \
			--disable-smbtorture4 \
			--disable-fam \
			--disable-iprint \
			--disable-dnssd \
			--disable-pthreadpool \
			--disable-dmalloc \
			--with-included-iniparser \
			--with-included-popt \
			--with-sendfile-support \
			--without-aio-support \
			--without-cluster-support \
			--without-ads \
			--without-krb5 \
			--without-dnsupdate \
			--without-automount \
			--without-ldap \
			--without-pam \
			--without-pam_smbpass \
			--without-winbind \
			--without-wbclient \
			--without-syslog \
			--without-nisplus-home \
			--without-quotas \
			--without-sys-quotas \
			--without-utmp \
			--without-acl-support \
			--with-configdir=/etc/samba \
			--with-privatedir=/etc/samba \
			--with-mandir=no \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log \
			--with-lockdir=/var/lock \
			--with-swatdir=/usr/share/swat \
			--disable-cups \
			--without-winbind \
			--without-libtdb \
			--without-libtalloc \
			--without-libnetapi \
			--without-libsmbclient \
			--without-libsmbsharemodes \
			--without-libtevent \
			--without-libaddns \
		; \
		$(MAKE); \
		$(MAKE) installservers installbin installscripts installdat installmodules \
			SBIN_PROGS="bin/samba_multicall" DESTDIR=$(TARGET_DIR) prefix=./. ; \
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/nmbd
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/smbd
			ln -sf samba_multicall $(TARGET_DIR)/usr/sbin/smbpasswd
	install -m 755 $(SKEL_ROOT)/etc/init.d/samba $(TARGET_DIR)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/samba/smb.conf $(TARGET_DIR)/etc/samba/
	rm -rf $(TARGET_LIB_DIR)/pdb
	rm -rf $(TARGET_LIB_DIR)/perfcount
	rm -rf $(TARGET_LIB_DIR)/nss_info
	rm -rf $(TARGET_LIB_DIR)/gpext
	$(REMOVE)/samba-$(SAMBA_VER)
	$(TOUCH)

#
# ntp
#
NTP_VER = 4.2.8p10
NTP_SRC = ntp-$(NTP_VER).tar.gz
NTP_URL = https://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2

NTP_PATCH = ntp-$(NTP_VER).patch

$(ARCHIVE)/$(NTP_SRC):
	$(DOWNLOAD) $(NTP_URL)/$(NTP_SRC)

$(D)/ntp: $(D)/bootstrap $(ARCHIVE)/$(NTP_SRC)
	$(START_BUILD)
	$(REMOVE)/ntp-$(NTP_VER)
	$(UNTAR)/$(NTP_SRC)
	$(CHDIR)/ntp-$(NTP_VER); \
		$(call apply_patches, $(NTP_PATCH)); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-tick \
			--disable-tickadj \
			--with-yielding-select=yes \
			--without-ntpsnmpd \
			--disable-debugging \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/ntp-$(NTP_VER)
	$(TOUCH)

#
# wireless_tools
#
WIRELESS_TOOLS_VER = 29
WIRELESS_TOOLS_SRC = wireless_tools.$(WIRELESS_TOOLS_VER).tar.gz
WIRELESS_TOOLS_URL = https://src.fedoraproject.org/repo/pkgs/wireless-tools/$(WIRELESS_TOOLS_SRC)/e06c222e186f7cc013fd272d023710cb

WIRELESS_TOOLS_PATCH = wireless-tools.$(WIRELESS_TOOLS_VER).patch

$(ARCHIVE)/$(WIRELESS_TOOLS_SRC):
	$(DOWNLOAD) $(WIRELESS_TOOLS_URL)/$(WIRELESS_TOOLS_SRC)

$(D)/wireless_tools: $(D)/bootstrap $(ARCHIVE)/$(WIRELESS_TOOLS_SRC)
	$(START_BUILD)
	$(REMOVE)/wireless_tools.$(WIRELESS_TOOLS_VER)
	$(UNTAR)/$(WIRELESS_TOOLS_SRC)
	$(CHDIR)/wireless_tools.$(WIRELESS_TOOLS_VER); \
		$(call apply_patches, $(WIRELESS_TOOLS_PATCH)); \
		$(MAKE) CC="$(TARGET)-gcc" CFLAGS="$(TARGET_CFLAGS) -I."; \
		$(MAKE) install PREFIX=$(TARGET_DIR)/usr INSTALL_MAN=$(TARGET_DIR)/.remove
	$(REMOVE)/wireless_tools.$(WIRELESS_TOOLS_VER)
	$(TOUCH)

#
# wpa_supplicant
#
WPA_SUPPLICANT_VER = 0.7.3
WPA_SUPPLICANT_SRC = wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz
WPA_SUPPLICANT_URL = https://w1.fi/releases

$(ARCHIVE)/$(WPA_SUPPLICANT_SRC):
	$(DOWNLOAD) $(WPA_SUPPLICANT_URL)/$(WPA_SUPPLICANT_SRC)

$(D)/wpa_supplicant: $(D)/bootstrap $(D)/openssl $(D)/wireless_tools $(ARCHIVE)/$(WPA_SUPPLICANT_SRC)
	$(START_BUILD)
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	$(UNTAR)/$(WPA_SUPPLICANT_SRC)
	$(CHDIR)/wpa_supplicant-$(WPA_SUPPLICANT_VER)/wpa_supplicant; \
		cp -f defconfig .config; \
		sed -i 's/#CONFIG_DRIVER_RALINK=y/CONFIG_DRIVER_RALINK=y/' .config; \
		sed -i 's/#CONFIG_IEEE80211W=y/CONFIG_IEEE80211W=y/' .config; \
		sed -i 's/#CONFIG_OS=unix/CONFIG_OS=unix/' .config; \
		sed -i 's/#CONFIG_TLS=openssl/CONFIG_TLS=openssl/' .config; \
		sed -i 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/' .config; \
		sed -i 's/#CONFIG_INTERWORKING=y/CONFIG_INTERWORKING=y/' .config; \
		export CFLAGS="-pipe -Os -Wall -g0 -I$(TARGET_DIR)/usr/include"; \
		export CPPFLAGS="-I$(TARGET_DIR)/usr/include"; \
		export LIBS="-L$(TARGET_DIR)/usr/lib -Wl,-rpath-link,$(TARGET_DIR)/usr/lib"; \
		export LDFLAGS="-L$(TARGET_DIR)/usr/lib"; \
		export DESTDIR=$(TARGET_DIR); \
		$(MAKE) CC=$(TARGET)-gcc; \
		$(MAKE) install BINDIR=/usr/sbin DESTDIR=$(TARGET_DIR)
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	$(TOUCH)

#
# dvbsnoop
#
DVBSNOOP_VER = d3f134b
DVBSNOOP_SRC = dvbsnoop-git-$(DVBSNOOP_VER).tar.bz2
DVBSNOOP_URL = https://github.com/Duckbox-Developers/dvbsnoop.git

$(ARCHIVE)/$(DVBSNOOP_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(DVBSNOOP_URL) $(DVBSNOOP_VER) $(notdir $@) $(ARCHIVE)

ifeq ($(BOXARCH), sh4)
DVBSNOOP_CONF_OPTS = --with-dvbincludes=$(KERNEL_DIR)/include
endif

$(D)/dvbsnoop: $(D)/bootstrap $(D)/kernel $(ARCHIVE)/$(DVBSNOOP_SRC)
	$(START_BUILD)
	$(REMOVE)/dvbsnoop-git-$(DVBSNOOP_VER)
	$(UNTAR)/$(DVBSNOOP_SRC)
	$(CHDIR)/dvbsnoop-git-$(DVBSNOOP_VER); \
		$(CONFIGURE) \
			--enable-silent-rules \
			--prefix=/usr \
			--mandir=/.remove \
			$(DVBSNOOP_CONF_OPTS) \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dvbsnoop-git-$(DVBSNOOP_VER)
	$(TOUCH)

#
# udpxy
#
UDPXY_VER = 612d227
UDPXY_SRC = udpxy-git-$(UDPXY_VER).tar.bz2
UDPXY_URL = https://github.com/pcherenkov/udpxy.git

UDPXY_PATCH = udpxy-git-$(UDPXY_VER).patch
UDPXY_PATCH += udpxy-git-$(UDPXY_VER)-fix-build-with-gcc8.patch
UDPXY_PATCH += udpxy-git-$(UDPXY_VER)-fix-build-with-gcc9.patch

$(ARCHIVE)/$(UDPXY_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(UDPXY_URL) $(UDPXY_VER) $(notdir $@) $(ARCHIVE)

$(D)/udpxy: $(D)/bootstrap $(ARCHIVE)/$(UDPXY_SRC)
	$(START_BUILD)
	$(REMOVE)/udpxy-git-$(UDPXY_VER)
	$(UNTAR)/$(UDPXY_SRC)
	$(CHDIR)/udpxy-git-$(UDPXY_VER)/chipmunk; \
		$(call apply_patches, $(UDPXY_PATCH)); \
		$(BUILDENV) \
		$(MAKE) CC=$(TARGET)-gcc CCKIND=gcc; \
		$(MAKE) install INSTALLROOT=$(TARGET_DIR)/usr MANPAGE_DIR=$(TARGET_DIR)/.remove
	$(REMOVE)/udpxy-git-$(UDPXY_VER)
	$(TOUCH)

#
# openvpn
#
OPENVPN_VER = 2.4.6
OPENVPN_SRC = openvpn-$(OPENVPN_VER).tar.xz
OPENVPN_URL1 = http://swupdate.openvpn.org/community/releases
OPENVPN_URL2 = http://build.openvpn.net/downloads/releases

$(ARCHIVE)/$(OPENVPN_SRC):
	$(DOWNLOAD) $(OPENVPN_URL1)/$(OPENVPN_SRC) || \
	$(DOWNLOAD) $(OPENVPN_URL2)/$(OPENVPN_SRC)

$(D)/openvpn: $(D)/bootstrap $(D)/openssl $(D)/lzo $(ARCHIVE)/$(OPENVPN_SRC)
	$(START_BUILD)
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(UNTAR)/$(OPENVPN_SRC)
	$(CHDIR)/openvpn-$(OPENVPN_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-lz4 \
			--disable-selinux \
			--disable-systemd \
			--disable-plugins \
			--disable-debug \
			--disable-pkcs11 \
			--enable-small \
			NETSTAT="/bin/netstat" \
			IFCONFIG="/sbin/ifconfig" \
			IPROUTE="/sbin/ip" \
			ROUTE="/sbin/route" \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/openvpn $(TARGET_DIR)/etc/init.d/
	install -d $(TARGET_DIR)/etc/openvpn
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(TOUCH)

#
# openssh
#
OPENSSH_VER = 7.7p1
OPENSSH_SRC = openssh-$(OPENSSH_VER).tar.gz
OPENSSH_URL = https://artfiles.org/openbsd/OpenSSH/portable

$(ARCHIVE)/$(OPENSSH_SRC):
	$(DOWNLOAD) $(OPENSSH_URL)/$(OPENSSH_SRC)

$(D)/openssh: $(D)/bootstrap $(D)/zlib $(D)/openssl $(ARCHIVE)/$(OPENSSH_SRC)
	$(START_BUILD)
	$(REMOVE)/openssh-$(OPENSSH_VER)
	$(UNTAR)/$(OPENSSH_SRC)
	$(CHDIR)/openssh-$(OPENSSH_VER); \
		CC=$(TARGET)-gcc; \
		./configure \
			$(CONFIGURE_OPTS) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc/ssh \
			--libexecdir=/sbin \
			--with-privsep-path=/var/empty \
			--with-cppflags="-pipe -Os -I$(TARGET_DIR)/usr/include" \
			--with-ldflags=-"L$(TARGET_DIR)/usr/lib" \
		; \
		$(MAKE); \
		$(MAKE) install-nokeys DESTDIR=$(TARGET_DIR)
	install -m 755 $(BUILD_TMP)/openssh-$(OPENSSH_VER)/opensshd.init $(TARGET_DIR)/etc/init.d/openssh
	sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' $(TARGET_DIR)/etc/ssh/sshd_config
	$(REMOVE)/openssh-$(OPENSSH_VER)
	$(TOUCH)

#
# dropbear
#
DROPBEAR_VER = 2018.76
DROPBEAR_SRC = dropbear-$(DROPBEAR_VER).tar.bz2
DROPBEAR_URL = http://matt.ucc.asn.au/dropbear/releases

$(ARCHIVE)/$(DROPBEAR_SRC):
	$(DOWNLOAD) $(DROPBEAR_URL)/$(DROPBEAR_SRC)

$(D)/dropbear: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/$(DROPBEAR_SRC)
	$(START_BUILD)
	$(REMOVE)/dropbear-$(DROPBEAR_VER)
	$(UNTAR)/$(DROPBEAR_SRC)
	$(CHDIR)/dropbear-$(DROPBEAR_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-pututxline \
			--disable-wtmp \
			--disable-wtmpx \
			--disable-loginfunc \
			--disable-pam \
		; \
		sed -i 's|^\(#define DROPBEAR_SMALL_CODE\).*|\1 0|' default_options.h; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" SCPPROGRESS=1; \
		$(MAKE) PROGRAMS="dropbear dbclient dropbearkey scp" install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/dropbear $(TARGET_DIR)/etc/init.d/
	install -d -m 0755 $(TARGET_DIR)/etc/dropbear
	$(REMOVE)/dropbear-$(DROPBEAR_VER)
	$(TOUCH)

#
# dropbearmulti
#
DROPBEARMULTI_VER = c8d852c
DROPBEARMULTI_SRC = dropbearmulti-git-$(DROPBEARMULTI_VER).tar.bz2
DROPBEARMULTI_URL = https://github.com/mkj/dropbear.git

$(ARCHIVE)/$(DROPBEARMULTI_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(DROPBEARMULTI_URL) $(DROPBEARMULTI_VER) $(notdir $@) $(ARCHIVE)

$(D)/dropbearmulti: $(D)/bootstrap $(ARCHIVE)/$(DROPBEARMULTI_SRC)
	$(START_BUILD)
	$(REMOVE)/dropbearmulti-git-$(DROPBEARMULTI_VER)
	$(UNTAR)/$(DROPBEARMULTI_SRC)
	$(CHDIR)/dropbearmulti-git-$(DROPBEARMULTI_VER); \
		$(BUILDENV) \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-syslog \
			--disable-lastlog \
			--infodir=/.remove \
			--localedir=/.remove \
			--mandir=/.remove \
			--docdir=/.remove \
			--htmldir=/.remove \
			--dvidir=/.remove \
			--pdfdir=/.remove \
			--psdir=/.remove \
			--disable-shadow \
			--disable-zlib \
			--disable-utmp \
			--disable-utmpx \
			--disable-wtmp \
			--disable-wtmpx \
			--disable-loginfunc \
			--disable-pututline \
			--disable-pututxline \
		; \
		$(MAKE) PROGRAMS="dropbear scp" MULTI=1; \
		$(MAKE) PROGRAMS="dropbear scp" MULTI=1 install DESTDIR=$(TARGET_DIR)
	cd $(TARGET_DIR)/usr/bin && ln -sf /usr/bin/dropbearmulti dropbear
	install -m 755 $(SKEL_ROOT)/etc/init.d/dropbear $(TARGET_DIR)/etc/init.d/
	install -d -m 0755 $(TARGET_DIR)/etc/dropbear
	$(REMOVE)/dropbearmulti-git-$(DROPBEARMULTI_VER)
	$(TOUCH)

#
# usb_modeswitch_data
#
USB_MODESWITCH_DATA_VER = 20160112
USB_MODESWITCH_DATA_SRC = usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER).tar.bz2
USB_MODESWITCH_DATA_URL = http://www.draisberghof.de/usb_modeswitch

USB_MODESWITCH_DATA_PATCH = usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER).patch

$(ARCHIVE)/$(USB_MODESWITCH_DATA_SRC):
	$(DOWNLOAD) $(USB_MODESWITCH_DATA_URL)/$(USB_MODESWITCH_DATA_SRC)

$(D)/usb_modeswitch_data: $(D)/bootstrap $(ARCHIVE)/$(USB_MODESWITCH_DATA_SRC)
	$(START_BUILD)
	$(REMOVE)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER)
	$(UNTAR)/$(USB_MODESWITCH_DATA_SRC)
	$(CHDIR)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER); \
		$(call apply_patches, $(USB_MODESWITCH_DATA_PATCH)); \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/usb-modeswitch-data-$(USB_MODESWITCH_DATA_VER)
	$(TOUCH)

#
# usb_modeswitch
#
USB_MODESWITCH_VER = 2.3.0
USB_MODESWITCH_SRC = usb-modeswitch-$(USB_MODESWITCH_VER).tar.bz2
USB_MODESWITCH_URL = http://www.draisberghof.de/usb_modeswitch

USB_MODESWITCH_PATCH = usb-modeswitch-$(USB_MODESWITCH_VER).patch

$(ARCHIVE)/$(USB_MODESWITCH_SRC):
	$(DOWNLOAD) $(USB_MODESWITCH_URL)/$(USB_MODESWITCH_SRC)

$(D)/usb_modeswitch: $(D)/bootstrap $(D)/libusb $(D)/usb_modeswitch_data $(ARCHIVE)/$(USB_MODESWITCH_SRC)
	$(START_BUILD)
	$(REMOVE)/usb-modeswitch-$(USB_MODESWITCH_VER)
	$(UNTAR)/$(USB_MODESWITCH_SRC)
	$(CHDIR)/usb-modeswitch-$(USB_MODESWITCH_VER); \
		$(call apply_patches, $(USB_MODESWITCH_PATCH)); \
		sed -i -e "s/= gcc/= $(TARGET)-gcc/" -e "s/-l usb/-lusb -lusb-1.0 -lpthread -lrt/" -e "s/install -D -s/install -D --strip-program=$(TARGET)-strip -s/" Makefile; \
		sed -i -e "s/@CC@/$(TARGET)-gcc/g" jim/Makefile.in; \
		$(BUILDENV) $(MAKE) DESTDIR=$(TARGET_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/usb-modeswitch-$(USB_MODESWITCH_VER)
	$(TOUCH)

#
# ofgwrite
#
OFGWRITE_SRC = ofgwrite-ddt.git
OFGWRITE_URL = https://github.com/Duckbox-Developers/ofgwrite-ddt.git

$(ARCHIVE)/$(OFGWRITE_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(OFGWRITE_SRC) ]; then \
		cd $(ARCHIVE)/$(OFGWRITE_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(OFGWRITE_URL) $(OFGWRITE_SRC); \
	fi

$(D)/ofgwrite: $(D)/bootstrap $(ARCHIVE)/$(OFGWRITE_SRC)
	$(START_BUILD)
	$(REMOVE)/ofgwrite-ddt
	cp -ra $(ARCHIVE)/$(OFGWRITE_SRC) $(BUILD_TMP)/ofgwrite-ddt
	$(CHDIR)/ofgwrite-ddt; \
		$(call apply_patches,$(OFGWRITE_PATCH)); \
		$(BUILDENV) \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_bin $(TARGET_DIR)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_caller $(TARGET_DIR)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite $(TARGET_DIR)/usr/bin
	$(REMOVE)/ofgwrite-ddt
	$(TOUCH)
	
#
# dvb-apps
#
DVB_APPS_SRC = dvb-apps.git
DVB_APPS_URL = https://github.com/openpli-arm/dvb-apps.git

DVB_APPS_PATCH = dvb-apps.patch

$(ARCHIVE)/$(DVB_APPS_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(DVB_APPS_SRC) ]; then \
		cd $(ARCHIVE)/$(DVB_APPS_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(DVB_APPS_URL) $(DVB_APPS_SRC); \
	fi

$(D)/dvb-apps: $(D)/bootstrap $(ARCHIVE)/$(DVB_APPS_SRC)
	$(START_BUILD)
	$(REMOVE)/dvb-apps
	cp -ra $(ARCHIVE)/$(DVB_APPS_SRC) $(BUILD_TMP)/dvb-apps
	$(CHDIR)/dvb-apps; \
		$(call apply_patches,$(DVB_APPS_PATCH)); \
		$(BUILDENV) \
		$(BUILDENV) $(MAKE) DESTDIR=$(TARGET_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/dvb-apps
	$(TOUCH)	

#
# ministaip
#
MINISATIP_SRC = minisatip.git
MINISATIP_URL = https://github.com/catalinii/minisatip.git

MINISATIP_PATCH = 

$(ARCHIVE)/$(MINISATIP_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(MINISATIP_SRC) ]; then \
		cd $(ARCHIVE)/$(MINISATIP__SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(MINISATIP_URL) $(MINISATIP_SRC); \
	fi

$(D)/minisatip: $(D)/bootstrap $(D)/openssl $(D)/libdvbcsa $(ARCHIVE)/$(MINISATIP_SRC)
	$(START_BUILD)
	$(REMOVE)/minisatip
	cp -ra $(ARCHIVE)/$(MINISATIP_SRC) $(BUILD_TMP)/minisatip
	$(CHDIR)/minisatip; \
		$(call apply_patches,$(MINISATIP_PATCH)); \
		$(BUILDENV) \
		export CFLAGS="-pipe -Os -Wall -g0 -ldl -I$(TARGET_INCLUDE_DIR)"; \
		export CPPFLAGS="-I$(TARGET_INCLUDE_DIR)"; \
		export LDFLAGS="-L$(TARGET_LIB_DIR)"; \
		./configure \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--enable-static \
		; \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/minisatip/minisatip $(TARGET_DIR)/usr/bin
	install -d $(TARGET_DIR)/usr/share/minisatip
	cp -a $(BUILD_TMP)/minisatip/html $(TARGET_DIR)/usr/share/minisatip
	$(REMOVE)/minisatip
	$(TOUCH)

#
# djmount
#
DJMOUNT_VER = 0.71
DJMOUNT_SRC = djmount-$(DJMOUNT_VER).tar.gz
DJMOUNT_URL = https://sourceforge.net/projects/djmount/files/djmount/$(DJMOUNT_VER)

DJMOUNT_PATCH  = djmount-$(DJMOUNT_VER)-fix-hang-with-asset-upnp.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-fix-incorrect-range-when-retrieving-content-via-HTTP.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-fix-new-autotools.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-fixed-crash-when-using-UTF-8-charset.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-fixed-crash.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-support-fstab-mounting.patch
DJMOUNT_PATCH += djmount-$(DJMOUNT_VER)-support-seeking-in-large-2gb-files.patch

$(ARCHIVE)/$(DJMOUNT_SRC):
	$(DOWNLOAD) $(DJMOUNT_URL)/$(DJMOUNT_SRC)

$(D)/djmount: $(D)/bootstrap $(D)/fuse $(ARCHIVE)/$(DJMOUNT_SRC)
	$(START_BUILD)
	$(REMOVE)/djmount-$(DJMOUNT_VER)
	$(UNTAR)/$(DJMOUNT_SRC)
	$(CHDIR)/djmount-$(DJMOUNT_VER); \
		touch libupnp/config.aux/config.rpath; \
		$(call apply_patches, $(DJMOUNT_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) -C \
			--prefix=/usr \
			--disable-debug \
		; \
		make; \
		make install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/djmount-$(DJMOUNT_VER)
	$(TOUCH)

#
# xupnpd
#
XUPNPD_SRC = xupnpd.git
XUPNPD_URL = https://github.com/clark15b/xupnpd.git
XUPNPD_BRANCH = 25d6d44c045

XUPNPD_PATCH = xupnpd.patch

$(ARCHIVE)/$(XUPNPD_SRC):
	set -e; 
	if [ -d $(ARCHIVE)/$(XUPNPD_SRC) ]; then \
		cd $(ARCHIVE)/$(XUPNPD_SRC); git pull; \
	else \
		cd $(ARCHIVE); git clone $(XUPNPD_URL) $(XUPNPD_SRC); \
	fi

$(D)/xupnpd: $(D)/bootstrap $(D)/openssl $(D)/lua $(ARCHIVE)/$(XUPNPD_SRC)
	$(START_BUILD)
	$(REMOVE)/xupnpd
	cp -ra $(ARCHIVE)/$(XUPNPD_SRC) $(BUILD_TMP)/xupnpd
	($(CHDIR)/xupnpd; git checkout -q $(XUPNPD_BRANCH);)
	$(CHDIR)/xupnpd; \
		$(call apply_patches, $(XUPNPD_PATCH))
	$(CHDIR)/xupnpd/src; \
		$(BUILDENV) \
		$(MAKE) embedded TARGET=$(TARGET) PKG_CONFIG=$(PKG_CONFIG) LUAFLAGS="$(TARGET_LDFLAGS) -I$(TARGET_INCLUDE_DIR)"; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	install -m 755 $(SKEL_ROOT)/etc/init.d/xupnpd $(TARGET_DIR)/etc/init.d/
	mkdir -p $(TARGET_DIR)/usr/share/xupnpd/config
	$(REMOVE)/xupnpd
	$(TOUCH)
	
#
# f2fs-tools
#
F2FS-TOOLS_VER = 1.16.0
F2FS-TOOLS_SRC = f2fs-tools-$(F2FS-TOOLS_VER).tar.gz
F2FS-TOOLS_URL = https://git.kernel.org/pub/scm/linux/kernel/git/jaegeuk/f2fs-tools.git/snapshot

F2FS-TOOLS_PATCH = f2fs-tools-$(F2FS-TOOLS_VER).patch

$(ARCHIVE)/$(F2FS-TOOLS_SRC):
	$(DOWNLOAD) $(F2FS-TOOLS_URL)/$(F2FS-TOOLS_SRC)

$(D)/f2fs-tools: $(D)/bootstrap $(D)/util_linux $(ARCHIVE)/$(F2FS-TOOLS_SRC)
	$(REMOVE)/f2fs-tools-$(F2FS-TOOLS_VER)
	$(UNTAR)/$(F2FS-TOOLS_SRC)
	$(CHDIR)/f2fs-tools-$(F2FS-TOOLS_VER); \
		$(call apply_patches, $(F2FS-TOOLS_PATCH)); \
		autoreconf -fi; \
		ac_cv_file__git=no \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--without-selinux \
			--without-blkid \
			; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/f2fs-tools-$(F2FS-TOOLS_VER)
	$(TOUCH)
	
#
# mc
#
MC_VER = 4.8.20
MC_SRC = mc-$(MC_VER).tar.xz
MC_URL = ftp.midnight-commander.org

MC_PATCH = mc-$(MC_VER).patch

$(ARCHIVE)/$(MC_SRC):
	$(DOWNLOAD) $(MC_URL)/$(MC_SRC)

$(D)/mc: $(D)/bootstrap $(D)/ncurses $(D)/libglib2 $(ARCHIVE)/$(MC_SRC)
	$(START_BUILD)
	$(REMOVE)/mc-$(MC_VER)
	$(UNTAR)/$(MC_SRC)
	$(CHDIR)/mc-$(MC_VER); \
		$(call apply_patches, $(MC_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--with-homedir=/var/tuxbox/config/mc \
			--without-gpm-mouse \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--disable-doxygen-html \
			--enable-charset \
			--disable-nls \
			--with-screen=ncurses \
			--without-x \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -rf $(TARGET_DIR)/usr/share/mc/examples
	find $(TARGET_DIR)/usr/share/mc/skins -type f ! -name default.ini | xargs --no-run-if-empty rm
	$(REMOVE)/mc-$(MC_VER)
	$(TOUCH)

#
# nano
#
NANO_VER = 2.2.6
NANO_SRC = nano-$(NANO_VER).tar.gz
NANO_URL = https://www.nano-editor.org/dist/v2.2

$(ARCHIVE)/$(NANO_SRC):
	$(DOWNLOAD) $(NANO_URL)/$(NANO_SRC)

$(D)/nano: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(NANO_SRC)
	$(START_BUILD)
	$(REMOVE)/nano-$(NANO_VER)
	$(UNTAR)/$(NANO_SRC)
	$(CHDIR)/nano-$(NANO_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-nls \
			--enable-tiny \
			--enable-color \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REMOVE)/nano-$(NANO_VER)
	$(TOUCH)

#
# htop
#
HTOP_VER = 2.2.0
HTOP_SRC = htop-$(HTOP_VER).tar.gz
HTOP_URL = http://hisham.hm/htop/releases/$(HTOP_VER)

HTOP_PATCH = htop-$(HTOP_VER).patch

$(ARCHIVE)/$(HTOP_SRC):
	$(DOWNLOAD) $(HTOP_URL)/$(HTOP_SRC)

$(D)/htop: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(HTOP_SRC)
	$(START_BUILD)
	$(REMOVE)/htop-$(HTOP_VER)
	$(UNTAR)/$(HTOP_SRC)
	$(CHDIR)/htop-$(HTOP_VER); \
		$(call apply_patches, $(HTOP_PATCH)); \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--disable-unicode \
			ac_cv_func_malloc_0_nonnull=yes \
			ac_cv_func_realloc_0_nonnull=yes \
			ac_cv_file__proc_stat=yes \
			ac_cv_file__proc_meminfo=yes \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -rf $(addprefix $(TARGET_DIR)/usr/share/,pixmaps applications)
	$(REMOVE)/htop-$(HTOP_VER)
	$(TOUCH)

#
# gdb
#
GDB_VER = 8.1.1
GDB_SRC = gdb-$(GDB_VER).tar.xz
GDB_URL = https://sourceware.org/pub/gdb/releases

GDB_PATCH  = gdb-$(GDB_VER)-fix-includes.patch

$(ARCHIVE)/$(GDB_SRC):
	$(DOWNLOAD) $(GDB_URL)/$(GDB_SRC)

$(D)/gdb: $(D)/bootstrap $(D)/zlib $(D)/ncurses $(ARCHIVE)/$(GDB_SRC)
	$(START_BUILD)
	$(REMOVE)/gdb-$(GDB_VER)
	$(UNTAR)/$(GDB_SRC)
	$(CHDIR)/gdb-$(GDB_VER); \
		$(call apply_patches, $(GDB_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-binutils \
			--disable-werror \
			--with-curses \
			--with-zlib \
			--enable-static \
			--with-system-gdbinit=/usr/share/gdb/gdbinit \
		; \
		$(MAKE) all-gdb; \
		$(MAKE) install-gdb DESTDIR=$(TARGET_DIR)
	$(REMOVE)/gdb-$(GDB_VER)
	$(TOUCH)

#
# valgrind
#
VALGRIND_VER = 3.13.0
VALGRIND_SRC = valgrind-$(VALGRIND_VER).tar.bz2
VALGRIND_URL = ftp://sourceware.org/pub/valgrind

$(ARCHIVE)/$(VALGRIND_SRC):
	$(DOWNLOAD) $(VALGRIND_URL)/$(VALGRIND_SRC)

$(D)/valgrind: $(D)/bootstrap $(ARCHIVE)/$(VALGRIND_SRC)
	$(START_BUILD)
	$(REMOVE)/valgrind-$(VALGRIND_VER)
	$(UNTAR)/$(VALGRIND_SRC)
	$(CHDIR)/valgrind-$(VALGRIND_VER); \
		sed -i -e "s#armv7#arm#g" configure; \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--datadir=/.remove \
			-enable-only32bit \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_LIB_DIR)/valgrind/,*.a *.xml)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cg_* callgrind_* ms_print)
	$(REMOVE)/valgrind-$(VALGRIND_VER)
	$(TOUCH)

#
# strace
#
STRACE_VER = 5.1
STRACE_SRC = strace-$(STRACE_VER).tar.xz
STRACE_URL = https://strace.io/files/$(STRACE_VER)

$(ARCHIVE)/$(STRACE_SRC):
	$(DOWNLOAD) $(STRACE_URL)/$(STRACE_SRC)

$(D)/strace: $(D)/bootstrap $(ARCHIVE)/$(STRACE_SRC)
	$(START_BUILD)
	$(REMOVE)/strace-$(STRACE_VER)
	$(UNTAR)/$(STRACE_SRC)
	$(CHDIR)/strace-$(STRACE_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--enable-silent-rules \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,strace-graph strace-log-merge)
	$(REMOVE)/strace-$(STRACE_VER)
	$(TOUCH)

