#
# Makefile for NeutrinoNG buildsystem
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

SHELL = /bin/bash
UID := $(shell id -u)

ifeq ($(UID), 0)
warn:
	@echo "You are running as root. Do not do this, it is dangerous."
	@echo "Aborting the build. Log in as a regular user and retry."
	@exit 1
endif

LC_ALL := C
LANG := C

export LC_ALL LANG

all: config

# Boxtype
config:
	@echo "Target receivers:"
	@echo "  Kathrein"
	@echo "    1)  UFS-912"
	@echo "  Fortis / Octagon / Atevio"
	@echo "    10)  Fortis HDbox    / Atevio AV7000"
	@echo "    11)  Octagon SF1008P / Atevio AV700"
	@echo "    12)                    Atevio AV7500"
	@echo "  SpiderBox"
	@echo "    13)  SpiderBox Hl101"
	@echo "  Cuberevo / AB IPBox / Xsarius"
	@echo "   20)  cuberevo / 9000"
	@echo "   21)  mini     / 900HD"
	@echo "   22)  mini2    / 910HD / Xsarius Alpha"
	@echo "   23)  2000HD"
	@echo "  Fulan"
	@echo "   30)  Spark"
	@echo "   31)  Spark7162"
	@echo "  Dream Media"
	@echo "   40)  dm800se"
	@echo "   41)  dm800sev2"
	@echo "   42)  dm820"
	@echo "   43)  dm900"
	@echo "   44)  dm920"
	@echo "   45)  dm7020hd"
	@echo "   46)  dm7020hdv2"
	@echo "   47)  dm7080"
	@echo "   48)  dm8000"
	@echo "  VU Plus"
	@echo "   50)  VU+ Duo"
	@echo "   51)  VU+ Duo2"
	@echo "   52)  VU+ Duo4k"
	@echo "   53)  VU+ Ultimo4k"
	@echo "   54)  VU+ Uno4k"
	@echo "   55)  VU+ Uno4kse"
	@echo "   56)  VU+ Zero4k"
	@echo "   57)  Vu+ Solo4K"
	@echo "  AX Mutant"
	@echo "   60)  Mut@nt HD51"
	@echo "   61)  Mut@nt HD60"
	@echo "   62)  Mut@nt HD61"
	@echo "   63)  Mut@nt HD66se"
	@echo "  Edision"
	@echo "   70)  osnino"
	@echo "   71)  osninoplus" 
	@echo "   72)  osninopro" 
	@echo "   73)  osmio4k"
	@echo "   74)  osmio4kplus"
	@echo "   75)  osmini4k"  
	@echo "  Gigablue"
	@echo "   80)  gb800se"
	@echo "   81)  gbue4k"
	@echo "   82)  gbultraue"
	@echo "   83)  gbtrio4k"
	@echo "   84)  gbtrio4kpro"
	@echo "   85)  gbip4k"
	@echo "  WWIO"
	@echo "   90)  WWIO BRE2ZE 4K"
	@echo "   91)  WWIO BRE2ZE T2C"
	@echo "  Air Digital"
	@echo "   100)  Zgemma h7"
	@echo "   101)  Zgemma h9"
	@echo "   102)  Zgemma h9combo"
	@echo "  AXAS"
	@echo "   110)  AXAS E4HD 4K Ultra"
	@echo "  Maxytec"
	@echo "   120)  multibox"
	@echo "   121)  multiboxse"
	@echo "  Octagon"
	@echo "   130)  sf8008"
	@echo "   131)   sf8008m"
	@echo "  Protek"
	@echo "   140)  protek4k"
	@echo "  Uclan"
	@echo "   150)  ustym4kpro"
	@echo "   151)  ustym4ks2ottx"
	@echo ""
	@echo -e "\033[01;32m   *)  generic\033[00m"
	@echo ""
	@read -p "Select target (1-150)? " BOXTYPE; \
	BOXTYPE=$${BOXTYPE}; \
	case "$$BOXTYPE" in \
		1) BOXTYPE="ufs912";; \
		10) BOXTYPE="fortis_hdbox";; \
		11) BOXTYPE="octagon1008";; \
		12) BOXTYPE="atevio7500";; \
		13) BOXTYPE="hl101";; \
		20) BOXTYPE="cuberevo";; \
		21) BOXTYPE="cuberevo_mini";; \
		22) BOXTYPE="cuberevo_mini2";; \
		23) BOXTYPE="cuberevo_2000hd";; \
		30) BOXTYPE="spark";; \
		31) BOXTYPE="spark7162";; \
		40) BOXTYPE="dm800se";; \
		41) BOXTYPE="dm800sev2";; \
		42) BOXTYPE="dm820";; \
		43) BOXTYPE="dm900";; \
		44) BOXTYPE="dm920";; \
		45) BOXTYPE="dm7020hd";; \
		46) BOXTYPE="dm7020hdv2";; \
		47) BOXTYPE="dm7080";; \
		48) BOXTYPE="dm8000";; \
		50) BOXTYPE="vuduo";; \
		51) BOXTYPE="vuduo2";; \
		52) BOXTYPE="vuduo4k";; \
		53) BOXTYPE="vuultimo4k";; \
		54) BOXTYPE="vuuno4k";; \
		55) BOXTYPE="vuuno4kse";; \
		56) BOXTYPE="vuzero4k";; \
		57) BOXTYPE="vusolo4k";; \
		60) BOXTYPE="hd51";; \
		61) BOXTYPE="hd60";; \
		62) BOXTYPE="hd61";; \
		63) BOXTYPE="hd66se";; \
		70) BOXTYPE="osnino";; \
		71) BOXTYPE="osninoplus";; \
		72) BOXTYPE="osninopro";; \
		73) BOXTYPE="osmio4k";; \
		74) BOXTYPE="osmio4kplus";; \
		75) BOXTYPE="osmini4k";; \
		80) BOXTYPE="gb800se";; \
		81) BOXTYPE="gbue4k";; \
		82) BOXTYPE="gbultraue";; \
		83) BOXTYPE="gbtrio4k";; \
		84) BOXTYPE="gbtrio4kpro";; \
		85) BOXTYPE="gbip4k";; \
		90) BOXTYPE="bre2ze4k";; \
		91) BOXTYPE="bre2zet2c";; \
		100) BOXTYPE="h7";; \
		101) BOXTYPE="h9";; \
		102) BOXTYPE="h9combo";; \
		110) BOXTYPE="e4hdultra";; \
		120) BOXTYPE="multibox";; \
		121) BOXTYPE="multiboxse";; \
		130) BOXTYPE="sf8008";; \
		131) BOXTYPE="sf8008m";; \
		140) BOXTYPE="protek4k";; \
		150) BOXTYPE="ustym4kpro";; \
		151) BOXTYPE="ustym4ks2ottx";; \
		*) BOXTYPE="generic";; \
	esac; \
	echo "BOXTYPE?=$$BOXTYPE" > .config
	@echo ""		
# Gstreamer
	@echo -e "\nGstreamer as mediaplayer for neutrino2 (only for mipsel / arm)"
	@echo "   1) yes"
	@echo -e "   \033[01;32m2) no\033[00m"
	@read -p "Select Gstreamer (1-2)?" GSTREAMER; \
	GSTREAMER=$${GSTREAMER}; \
	case "$$GSTREAMER" in \
		1) echo "GSTREAMER=gstreamer" >> .config;; \
		2|*) echo "GSTREAMER=" >> .config;; \
	esac;
	@echo ""
# python
	@echo -e "\npython plugins support in neutrino2 (experimental and only for mipsel / arm)?:"
	@echo "   1)  yes"
	@echo -e "   \033[01;32m2)  no\033[00m"
	@read -p "Select python support (1-2)?" PYTHON; \
	PYTHON=$${PYTHON}; \
	case "$$PYTHON" in \
		1) echo "PYTHON=python" >> .config;; \
		2|*) echo "PYTHON=" >> .config;; \
	esac;
	@echo ""
# GraphLCD
	@echo -e "\nGraphLCD (neutrino2 / neutrino-DDT):"
	@echo -e "   \033[01;32m1)  yes\033[00m"
	@echo "   2) no"
	@read -p "Select  GraphLCD (1-2)?" GRAPHLCD; \
	GRAPHLCD=$${GRAPHLCD}; \
	case "$$GRAPHLCD" in \
		1) echo "GRAPHLCD=graphlcd" >> .config;; \
		2) echo "GRAPHLCD=" >> .config;; \
		*) echo "GRAPHLCD=graphlcd" >> .config;; \
	esac;
	@echo ""
# LCD4Linux
	@echo -e "\nLCD4linux (neutrino-DDT):"
	@echo -e "   \033[01;32m1)  no\033[00m"
	@echo "   2) yes"
	@read -p "Select  LCD4Linux (1-2)?" LCD4LINUX; \
	LCD4LINUX=$${LCD4LINUX}; \
	case "$$LCD4LINUX" in \
		1) echo "LCD4LINUX=" >> .config;; \
		2) echo "LCD4LINUX=lcd4linux" >> .config;; \
		*) echo "LCD4LINUX=" >> .config;; \
	esac;
	@echo ""	
#	
	@echo ""
	@make printenv

config-clean:
	rm -f .config
	
defconfig:
	echo "BOXTYPE?=generic" > .config

include make/buildenv.mk

PARALLEL_JOBS := $(shell echo $$((1 + `getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1`)))
override MAKE = make $(if $(findstring j,$(filter-out --%,$(MAKEFLAGS))),,-j$(PARALLEL_JOBS))

#
#  A print out of environment variables
#
printenv:
	@echo
	@echo '================================================================================'
	@echo "Build Environment Variables:"
	@echo "PATH             : `type -p fmt>/dev/null&&echo $(PATH)|sed 's/:/ /g' |fmt -65|sed 's/ /:/g; 2,$$s/^/                 : /;'||echo $(PATH)`"
	@echo "ARCHIVE_DIR      : $(ARCHIVE)"
	@echo "BASE_DIR         : $(BASE_DIR)"
	@echo "TOOLS_DIR        : $(TOOLS_DIR)"
ifeq ($(BOXARCH), sh4)
	@echo "DRIVER_DIR       : $(DRIVER_DIR)"
endif
	@echo "IMAGE_DIR        : $(IMAGE_DIR)"
	@echo "PKGS_DIR         : $(PKGS_DIR)"
	@echo "CROSS_DIR        : $(CROSS_DIR)"
	@echo "RELEASE_DIR      : $(RELEASE_DIR)"
	@echo "HOST_DIR         : $(HOST_DIR)"
	@echo "TARGET_DIR       : $(TARGET_DIR)"
	@echo "KERNEL_DIR       : $(KERNEL_DIR)"
	@echo "MAINTAINER       : $(MAINTAINER)"
	@echo "BUILD            : $(BUILD)"
ifeq ($(BOXTYPE),)
	@echo -e "\033[00;31mBOXTYPE		 :specify a valid BOXTYPE please run 'make config' or 'make'\033[0m"
else
	@echo "BOXTYPE          : $(BOXTYPE)"
endif
	@echo "BOXARCH          : $(BOXARCH)"
	@echo "TARGET           : $(TARGET)"
	@echo "GCC              : $(GCC_VER)"
	@echo "KERNEL_VERSION   : $(KERNEL_VER)"
	@echo "PARALLEL_JOBS    : $(PARALLEL_JOBS)"
	@echo '================================================================================'
	@echo "Neutrino2 extra configuration:"
	@echo "Gstreamer        :$(GSTREAMER)"
	@echo "Python           :$(PYTHON)"
	@echo "Graphlcd         :$(GRAPHLCD)"
	@echo
	@echo "Neutrino-DDT extra configuration:"
	@echo "Graphlcd         :$(GRAPHLCD)"
	@echo "LCD4Linux        :$(LCD4LINUX)"
	@echo
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), bre2ze4k e4hdultra h7 h9combo hd51 protek4k))
	@echo -e "\033[01;33mDefault Flash LAYOUT is standard if you want multiboot layout set LAYOUT := multiboot in config.local\033[0m"
endif
	@echo
	@echo '================================================================================'
	@make --no-print-directory toolcheck
ifeq ($(MAINTAINER),)
	@echo "##########################################################################"
	@echo "# The MAINTAINER variable is not set. It defaults to your name from the  #"
	@echo "# passwd entry, but this seems to have failed. Please set it in '.config'.#"
	@echo "##########################################################################"
	@echo
endif
	@echo
	@echo -e "\033[01;33mIf you want to create or modify the configuration, run 'make config' or 'make'\033[0m"
	@echo
	@echo "Your next step could be:"
	@echo "  make image-neutrino2"
	@echo ""
	@echo "to build neutrino-DDT image"
	@echo "  make image-neutrino"
	@echo ""
	@echo "for more details:"
	@echo "  make help"

help:
	@echo "target configuration:"
	@echo " make config (or make)           - setup target configuration"
	@echo ""
	@echo "image:"
	@echo " make image-neutrino2            - build neutrino2 image"
	@echo " make image-neutrino             - build neutrino-DDT image"
	@echo ""
	@echo "show board configuration:"
	@echo " make printenv                   - show board build configuration"
	@echo ""
	@echo "show all supported boards:"
	@echo " make print-boards               - show all supported boards"
	@echo ""
	@echo "later, you might find these useful:"
	@echo " make update                     - update the buildsystem"
	@echo ""
	@echo "cleantargets:"
	@echo " make clean                      - clears everything except toolchain."
	@echo " make distclean                  - clears the whole construction."
	@echo " make neutrino2-distclean        - clears neutrino2 to invoke update neutrino2 sources"
	@echo " make neutrino-distclean         - clears neutrino to invoke update neutrino sources"
	@echo ""
	@echo "feed packages:"
	@echo " make package_name-ipk           - build package."
	@echo " make packages                   - build all feed packages."
	@echo " make packges-clean              - clean all packages."
	@echo ""
	@echo "optional (for developers):"
	@echo " make image                      - build base image without GUI."
	@echo " make release                    - build base release without GUI."
	@echo ""

ifeq ($(BOXARCH), sh4)
include make/crosstool-sh4.mk
else
include make/crosstool.mk
endif
include make/bootstrap.mk
include make/contrib-libs.mk
include make/contrib-apps.mk
include make/ffmpeg.mk
include make/gstreamer.mk
include make/root-etc.mk
include make/python.mk
include make/lua.mk
include make/graphic.mk
include make/tools.mk
include make/cleantargets.mk
include make/release.mk
include make/neutrino2.mk
include make/neutrino.mk
include make/packages.mk

update:
	git stash && git stash show -p > ./pull-stash-NeutrinoNG_$(shell date '+%d.%m.%Y-%H.%M').patch || true && git pull || true;
	@echo;
		
# print all supported boards ...
print-boards:
	@ls -1C machine | sed 's/.mk//g'
	
# print all builds
print-builds:
	@ls -1C builds

# for local extensions, e.g. special plugins or similar...
# put them into $(BASE_DIR)/local since that is ignored in .gitignore
-include ./Makefile.local

# debug target, if you need that, you know it. If you don't know if you need
# that, you don't need it.
.print-phony:
	@echo $(PHONY)

PHONY += all printenv .print-phony
PHONY += update
.PHONY: $(PHONY)

# this makes sure we do not build top-level dependencies in parallel
# (which would not be too helpful anyway, running many configure and
# downloads in parallel...), but the sub-targets are still built in
# parallel, which is useful on multi-processor / multi-core machines
.NOTPARALLEL:

