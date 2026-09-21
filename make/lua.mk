#
# lua
#
LUA_VER = 5.2.4
LUA_VER_SHORT = 5.2
LUA_SRC = lua-$(LUA_VER).tar.gz
LUA_URL = https://www.lua.org/ftp

LUAPOSIX_VER = 31
LUAPOSIX_SRC = luaposix-git-$(LUAPOSIX_VER).tar.bz2
LUAPOSIX_URL = https://github.com/luaposix/luaposix.git

LUAPOSIX_PATCH = lua-$(LUA_VER)-luaposix-$(LUAPOSIX_VER).patch

$(ARCHIVE)/$(LUA_SRC):
	$(DOWNLOAD) $(LUA_URL)/$(LUA_SRC)

$(ARCHIVE)/$(LUAPOSIX_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LUAPOSIX_URL) release-v$(LUAPOSIX_VER) $(notdir $@) $(ARCHIVE)

$(D)/lua: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(LUAPOSIX_SRC) $(ARCHIVE)/$(LUA_SRC)
	$(START_BUILD)
	$(REMOVE)/lua-$(LUA_VER)
	mkdir -p $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT)
	$(UNTAR)/$(LUA_SRC)
	$(CHDIR)/lua-$(LUA_VER); \
		$(call apply_patches, $(LUAPOSIX_PATCH)); \
		tar xf $(ARCHIVE)/$(LUAPOSIX_SRC); \
		cd luaposix-git-$(LUAPOSIX_VER)/ext; cp posix/posix.c include/lua52compat.h ../../src/; cd ../..; \
		cd luaposix-git-$(LUAPOSIX_VER)/lib; cp *.lua $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT); cd ../..; \
		sed -i 's/<config.h>/"config.h"/' src/posix.c; \
		sed -i '/^#define/d' src/lua52compat.h; \
		sed -i 's|man/man1|/.remove|' Makefile; \
		$(MAKE) linux CC=$(TARGET)-gcc CPPFLAGS="$(TARGET_CPPFLAGS) -fPIC" LDFLAGS="-L$(TARGET_DIR)/usr/lib" BUILDMODE=dynamic PKG_VERSION=$(LUA_VER); \
		$(MAKE) install INSTALL_TOP=$(TARGET_DIR)/usr INSTALL_MAN=$(TARGET_DIR)/.remove
	cd $(TARGET_DIR)/usr && rm bin/lua bin/luac
	$(REMOVE)/lua-$(LUA_VER)
	$(TOUCH)
	
#
# lua-package
#
lua-package: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(LUAPOSIX_SRC) $(ARCHIVE)/$(LUA_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/lua-$(LUA_VER)
	mkdir -p $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(UNTAR)/$(LUA_SRC)
	$(CHDIR)/lua-$(LUA_VER); \
		$(call apply_patches, $(LUAPOSIX_PATCH)); \
		tar xf $(ARCHIVE)/$(LUAPOSIX_SRC); \
		cd luaposix-git-$(LUAPOSIX_VER)/ext; cp posix/posix.c include/lua52compat.h ../../src/; cd ../..; \
		cd luaposix-git-$(LUAPOSIX_VER)/lib; cp *.lua $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT); cd ../..; \
		sed -i 's/<config.h>/"config.h"/' src/posix.c; \
		sed -i '/^#define/d' src/lua52compat.h; \
		sed -i 's|man/man1|/.remove|' Makefile; \
		$(MAKE) linux CC=$(TARGET)-gcc CPPFLAGS="$(TARGET_CPPFLAGS) -fPIC" LDFLAGS="-L$(TARGET_DIR)/usr/lib" BUILDMODE=dynamic PKG_VERSION=$(LUA_VER); \
		$(MAKE) install INSTALL_TOP=$(PKGPREFIX)/usr INSTALL_MAN=$(PKGPREFIX)/.remove
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/bin/luac
	$(REMOVE)/lua-$(LUA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/lua/control
	touch $(BUILD_TMP)/lua/control/control
	echo Package: lua > $(BUILD_TMP)/lua/control/control
	echo Version: $(LUA_VER) >> $(BUILD_TMP)/lua/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/lua/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/lua/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/lua/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/lua/control/control 
	echo Depends:  >> $(BUILD_TMP)/lua/control/control
	pushd $(BUILD_TMP)/lua/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/lua-$(LUA_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/lua
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luacurl
#
LUACURL_VER = 9ac72c7
LUACURL_SRC = luacurl-git-$(LUACURL_VER).tar.bz2
LUACURL_URL = https://github.com/Lua-cURL/Lua-cURLv3.git

$(ARCHIVE)/$(LUACURL_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LUACURL_URL) $(LUACURL_VER) $(notdir $@) $(ARCHIVE)

$(D)/luacurl: $(D)/bootstrap $(D)/libcurl $(D)/lua $(ARCHIVE)/$(LUACURL_SRC)
	$(START_BUILD)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
	$(UNTAR)/$(LUACURL_SRC)
	$(CHDIR)/luacurl-git-$(LUACURL_VER); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" \
			LIBDIR=$(TARGET_DIR)/usr/lib \
			LUA_INC=$(TARGET_DIR)/usr/include; \
		$(MAKE) install DESTDIR=$(TARGET_DIR) LUA_CMOD=/usr/lib/lua/$(LUA_VER_SHORT) LUA_LMOD=/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
	$(TOUCH)
	
#
# luacurl-package
#
luacurl-package: $(D)/bootstrap $(D)/libcurl $(D)/lua $(ARCHIVE)/$(LUACURL_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
	$(UNTAR)/$(LUACURL_SRC)
	$(CHDIR)/luacurl-git-$(LUACURL_VER); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" \
			LIBDIR=$(TARGET_DIR)/usr/lib \
			LUA_INC=$(TARGET_DIR)/usr/include; \
		$(MAKE) install DESTDIR=$(PKGPREFIX) LUA_CMOD=/usr/lib/lua/$(LUA_VER_SHORT) LUA_LMOD=/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luacurl/control
	touch $(BUILD_TMP)/luacurl/control/control
	echo Package: luacurl > $(BUILD_TMP)/luacurl/control/control
	echo Version: $(LUACURL_VER) >> $(BUILD_TMP)/luacurl/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luacurl/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luacurl/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luacurl/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luacurl/control/control 
	echo Depends:  >> $(BUILD_TMP)/luacurl/control/control
	pushd $(BUILD_TMP)/luacurl/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luacurl-$(LUACURL_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luacurl
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luaexpat
#
LUAEXPAT_VER = 1.3.0
LUAEXPAT_SRC = luaexpat-$(LUAEXPAT_VER).tar.gz
LUAEXPAT_URL = https://src.fedoraproject.org/lookaside/pkgs/lua-expat/luaexpat-1.3.0.tar.gz/3c20b5795e7107f847f8da844fbfe2da

LUAEXPAT_PATCH = luaexpat-$(LUAEXPAT_VER).patch

$(ARCHIVE)/$(LUAEXPAT_SRC):
	$(DOWNLOAD) $(LUAEXPAT_URL)/$(LUAEXPAT_SRC)

$(D)/luaexpat: $(D)/bootstrap $(D)/lua $(D)/expat $(ARCHIVE)/$(LUAEXPAT_SRC)
	$(START_BUILD)
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
	$(UNTAR)/$(LUAEXPAT_SRC)
	$(CHDIR)/luaexpat-$(LUAEXPAT_VER); \
		$(call apply_patches, $(LUAEXPAT_PATCH)); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" PREFIX=$(TARGET_DIR)/usr; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)/usr
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
	$(TOUCH)
	
#
# luaexpat-package
#
luaexpat-package: $(D)/bootstrap $(D)/lua $(D)/expat $(ARCHIVE)/$(LUAEXPAT_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
	$(UNTAR)/$(LUAEXPAT_SRC)
	$(CHDIR)/luaexpat-$(LUAEXPAT_VER); \
		$(call apply_patches, $(LUAEXPAT_PATCH)); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" PREFIX=$(TARGET_DIR)/usr; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)/usr
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luaexpat/control
	touch $(BUILD_TMP)/luaexpat/control/control
	echo Package: luaexpat > $(BUILD_TMP)/luaexpat/control/control
	echo Version: $(LUAEXPAT_VER) >> $(BUILD_TMP)/luaexpat/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luaexpat/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luaexpat/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luaexpat/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luaexpat/control/control 
	echo Depends:  >> $(BUILD_TMP)/luaexpat/control/control
	pushd $(BUILD_TMP)/luaexpat/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luaexpat-$(LUAEXPAT_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luaexpat
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luasocket
#
LUASOCKET_VER = 5a17f79
LUASOCKET_SRC = luasocket-git-$(LUASOCKET_VER).tar.bz2
LUASOCKET_URL = https://github.com/diegonehab/luasocket.git

$(ARCHIVE)/$(LUASOCKET_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LUASOCKET_URL) $(LUASOCKET_VER) $(notdir $@) $(ARCHIVE)

$(D)/luasocket: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOCKET_SRC)
	$(START_BUILD)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
	$(UNTAR)/$(LUASOCKET_SRC)
	$(CHDIR)/luasocket-git-$(LUASOCKET_VER); \
		sed -i -e "s@LD_linux=gcc@LD_LINUX=$(TARGET)-gcc@" -e "s@CC_linux=gcc@CC_LINUX=$(TARGET)-gcc -L$(TARGET_DIR)/usr/lib@" -e "s@DESTDIR?=@DESTDIR?=$(TARGET_DIR)/usr@" src/makefile; \
		$(MAKE) CC=$(TARGET)-gcc LD=$(TARGET)-gcc LUAV=$(LUA_VER_SHORT) PLAT=linux COMPAT=COMPAT LUAINC_linux=$(TARGET_DIR)/usr/include LUAPREFIX_linux=; \
		$(MAKE) install LUAPREFIX_linux= LUAV=$(LUA_VER_SHORT)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
	$(TOUCH)
	
#
# luasocket-package
#	
luasocket-package: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOCKET_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
	$(UNTAR)/$(LUASOCKET_SRC)
	$(CHDIR)/luasocket-git-$(LUASOCKET_VER); \
		sed -i -e "s@LD_linux=gcc@LD_LINUX=$(TARGET)-gcc@" -e "s@CC_linux=gcc@CC_LINUX=$(TARGET)-gcc -L$(TARGET_DIR)/usr/lib@" -e "s@DESTDIR?=@DESTDIR?=$(PKGPREFIX)/usr@" src/makefile; \
		$(MAKE) CC=$(TARGET)-gcc LD=$(TARGET)-gcc LUAV=$(LUA_VER_SHORT) PLAT=linux COMPAT=COMPAT LUAINC_linux=$(TARGET_DIR)/usr/include LUAPREFIX_linux=; \
		$(MAKE) install LUAPREFIX_linux= LUAV=$(LUA_VER_SHORT)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luasocket/control
	touch $(BUILD_TMP)/luasocket/control/control
	echo Package: luasocket > $(BUILD_TMP)/luasocket/control/control
	echo Version: $(LUASOCKET_VER) >> $(BUILD_TMP)/luasocket/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luasocket/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luasocket/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luasocket/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luasocket/control/control 
	echo Depends:  >> $(BUILD_TMP)/luasocket/control/control
	pushd $(BUILD_TMP)/luasocket/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luasocket-$(LUASOCKET_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luasocket
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luafeedparser
#
LUAFEEDPARSER_VER = 9b284bc
LUAFEEDPARSER_SRC = luafeedparser-git-$(LUAFEEDPARSER_VER).tar.bz2
LUAFEEDPARSER_URL = https://github.com/slact/lua-feedparser.git

$(ARCHIVE)/$(LUAFEEDPARSER_SRC):
	$(SCRIPTS_DIR)/get-git-archive.sh $(LUAFEEDPARSER_URL) $(LUAFEEDPARSER_VER) $(notdir $@) $(ARCHIVE)

$(D)/luafeedparser: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUAFEEDPARSER_SRC)
	$(START_BUILD)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
	$(UNTAR)/$(LUAFEEDPARSER_SRC)
	$(CHDIR)/luafeedparser-git-$(LUAFEEDPARSER_VER); \
		sed -i -e "s/^PREFIX.*//" -e "s/^LUA_DIR.*//" Makefile ; \
		$(BUILDENV) $(MAKE) install  LUA_DIR=$(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
	$(TOUCH)
	
#
# luafeedparser-package
#
luafeedparser-package: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUAFEEDPARSER_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
	$(UNTAR)/$(LUAFEEDPARSER_SRC)
	$(CHDIR)/luafeedparser-git-$(LUAFEEDPARSER_VER); \
		sed -i -e "s/^PREFIX.*//" -e "s/^LUA_DIR.*//" Makefile ; \
		$(BUILDENV) $(MAKE) install  LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luafeedparser/control
	touch $(BUILD_TMP)/luafeedparser/control/control
	echo Package: luafeedparser > $(BUILD_TMP)/luafeedparser/control/control
	echo Version: $(LUAFEEDPARSER_VER) >> $(BUILD_TMP)/luafeedparser/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luafeedparser/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luafeedparser/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luafeedparser/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luafeedparser/control/control 
	echo Depends:  >> $(BUILD_TMP)/luafeedparser/control/control
	pushd $(BUILD_TMP)/luafeedparser/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luafeedparser-$(LUAFEEDPARSER_VER)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luafeedparser
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luasoap
#
LUASOAP_VER = 3_0_1
LUASOAP_SRC = luasoap-$(LUASOAP_VER).tar.gz
LUASOAP_URL = https://github.com/tomasguisasola/luasoap/archive/refs/tags

#LUASOAP_PATCH = luasoap-$(LUASOAP_VER).patch

$(ARCHIVE)/$(LUASOAP_SRC):
	$(DOWNLOAD) $(LUASOAP_URL)/v$(LUASOAP_VER).tar.gz -O $(ARCHIVE)/$(LUASOAP_SRC)

$(D)/luasoap: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOAP_SRC)
	$(START_BUILD)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
	$(UNTAR)/$(LUASOAP_SRC)
	$(CHDIR)/luasoap-$(LUASOAP_VER); \
		$(call apply_patches, $(LUASOAP_PATCH)); \
		$(MAKE) install LUA_DIR=$(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
	$(TOUCH)
	
#
# luasoap-package
#
luasoap-package: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOAP_SRC)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
	$(UNTAR)/$(LUASOAP_SRC)
	$(CHDIR)/luasoap-$(LUASOAP_VER); \
		$(call apply_patches, $(LUASOAP_PATCH)); \
		$(MAKE) install LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luasoap/control
	touch $(BUILD_TMP)/luasoap/control/control
	echo Package: luasoap > $(BUILD_TMP)/luasoap/control/control
	echo Version: $(LUA_VER_SHORT) >> $(BUILD_TMP)/luasoap/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luasoap/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luasoap/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luasoap/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luasoap/control/control 
	echo Depends:  >> $(BUILD_TMP)/luasoap/control/control
	pushd $(BUILD_TMP)/luasoap/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luasoap-$(LUA_VER_SHORT)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luasoap
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

#
# luajson
#
LUA_JSON_SRC = json.lua
LUA_JSON_URL = https://github.com/swiboe/swiboe/raw/master/term_gui

$(ARCHIVE)/$(LUA_JSON_SRC):
	$(DOWNLOAD) $(LUA_JSON_URL)/$(LUA_JSON_SRC)

$(D)/luajson: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUA_JSON_SRC)
	$(START_BUILD)
	cp $(ARCHIVE)/$(LUA_JSON_SRC) $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT)/json.lua
	$(TOUCH)
	
#
# luajson-package
#
luajson-package: $(D)/bootstrap $(D)/lua $(ARCHIVE)/json.lua
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGS_DIR)/$@
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	cp $(ARCHIVE)/json.lua $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)/json.lua
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	pushd $(PKGPREFIX) && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/data.tar.gz ./* && popd
	install -d $(BUILD_TMP)/luajson/control
	touch $(BUILD_TMP)/luajson/control/control
	echo Package: luajson > $(BUILD_TMP)/luajson/control/control
	echo Version: $(LUA_VER_SHORT) >> $(BUILD_TMP)/luajson/control/control
	echo Section: base/libraries >> $(BUILD_TMP)/luajson/control/control
ifeq ($(BOXARCH), mips)
	echo Architecture: $(BOXARCH)el >> $(BUILD_TMP)/luajson/control/control 
else
	echo Architecture: $(BOXARCH) >> $(BUILD_TMP)/luajson/control/control 
endif
	echo Maintainer: $(MAINTAINER)  >> $(BUILD_TMP)/luajson/control/control 
	echo Depends:  >> $(BUILD_TMP)/luajson/control/control
	pushd $(BUILD_TMP)/luajson/control && chmod +x * && tar --numeric-owner --group=0 --owner=0 -czf $(PKGS_DIR)/$@/control.tar.gz ./* && popd
	pushd $(PKGS_DIR)/$@ && echo 2.0 > debian-binary && ar rv $(PKGS_DIR)/luajson-$(LUA_VER_SHORT)_$(BOXARCH)_all.ipk ./data.tar.gz ./control.tar.gz ./debian-binary && popd && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(BUILD_TMP)/luajson
	rm -rf $(PKGPREFIX)
	rm -rf $(PKGS_DIR)/$@
	$(END_BUILD)

