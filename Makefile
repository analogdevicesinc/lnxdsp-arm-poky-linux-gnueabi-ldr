# Makefile for the Analog Devices ARM GNU Toolchain

# Clear BSD license
# 
# Copyright (c) 2013-2022, Analog Devices, Inc.  All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the
# disclaimer below) provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the
#    distribution.
# 
# * Neither the name of Analog Devices, Inc.  nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
# 
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
# GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
# HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# See README.BUILDING for a description of basic build commands

# Structure:
# build/                                // build area
# dl/                                   // download area for tarballs
# Makefile
# output/                               // final staging/prefix/output area
# patches/{package}-{version}/*.patch   // patches to be applied to...
# src/{package}                         // the unpacked sources


# Build configuration

OBTAIN_SOURCES=yes
SUB_MAKE_OPTS=-j 1

# User specific customisations
-include ./user.mk
# Configuration for a local mirror of sources.
# It will set USE_SRC_MIRROR=yes if you have a local mirror of
# all the source zip files.
# MIRROR_PATH will be set to an ssh path where the zips can be pulled from
-include ./mirror.mk

# If you set CREATE_GIT_SRC=yes, when you unpack the srcs, each
# module will be added to its own local git repo.
# Any patches will then be checked in as individual commits too.
ifeq ($(CREATE_GIT_SRC),yes)
PATCHER_OPT=-add-to-git 
endif

# Common env vars
BUILD=$(shell uname -m)-pc-linux-gnu
ARCH=arm

ifeq ($(BUILD_WINDOWS_CROSS),yes)
HOST?=i686-w64-mingw32
NEWLIB_HOST_FLAG=-D__WIN32_HOST
CROSS_ID=_win
SUFFIX=.exe
else
HOST=$(shell uname -m)-pc-linux-gnu
SUFFIX=
endif

# The installation directory inside CCES
CCES_ARCH_DIR=ARM
TD=$(CURDIR)
SCRIPTS_DIR=$(TD)/scripts
ARCHDEF_DIR=$(TD)/src/proc-defs/XML/ArchDef

# Define this as yes to do a git pull on any remote repo sources you use
UPDATE_SRCS_FROM_REMOTE_REPOS=yes

GCC_MAJOR_VERSION=10.2
GCC_MINOR_VERSION=0

# Define common folders for the build.
BUILDROOT=$(TD)/build/$(GCC_MAJOR_VERSION)/$(TARGET)$(CROSS_ID)
TOOLCHAIN=$(TD)/output/toolchain_$(ARCH)$(CROSS_ID)/$(GCC_MAJOR_VERSION)/$(CCES_ARCH_DIR)
LINUX_TOOLCHAIN=$(TD)/output/toolchain_$(ARCH)/$(GCC_MAJOR_VERSION)/$(CCES_ARCH_DIR)
GCC_REQS_DIR=$(TD)/build/$(HOST)
# Set to yes if you want to auto-download the sources as part of your build.
MAKE=make $(SUB_MAKE_OPTS)

STRIP=strip

# Do we want to enable multi-lib
MULTILIB_CONFIG_FLAG=--enable-multilib

# Add native-hosted build directory to PATH.
# Note we cannot use "+=" as that would also add a preceding space.
# The DEFAULT_PATH definition with ":=" is used to avoid a circular
# definition of PATH.
DEFAULT_PATH:=$(PATH)
PATH=$(LINUX_TOOLCHAIN)/$(TARGET)/bin:$(DEFAULT_PATH)

# ADI_CHANGES macro set in builds
ADI_CFLAGS=-DADI_CHANGES -O2
# -fdata-sections -ffunction-sections allows garbage collection.
ADI_LIB_CFLAGS=$(ADI_CFLAGS) -fdata-sections -ffunction-sections

# Configure the checking that we build into GCC
ENABLE_CHECKING=--enable-checking=release

# Top level lib files to be removed
TOP_LEVEL_LIBS_TO_REMOVE= *.a *.o *.ld *.la *.py

# Shell and environment
MKDIR=mkdir -p
SHELL=/bin/bash
LD_LIBRARY_PATH=$(GCC_REQS_DIR)/lib

# ADI Project name, used to configure the GCC/binutils sources for a specific
# project
ADI_PROJECT_NAME=CCES

include ./source_config.mk

# Determine if we run the configure script. This should always be set to yes, and only
# passed in on the command line when you're confident that it doesn't need to be run.
DO_BUILD?=yes
DO_CONFIG?=yes

# Automake should be version 1.11 or earlier
# For more information see https://sourceware.org/newlib/README
# Newlib really doesn't like it if you use a newer version of automake
AUTOMAKE=automake-1.11

-include ./ldr.mk

# ###################### BUILD RULES #############################################################
# Default
.PHONY: default
default: all

.PHONY: all
all: install_arm_none_eabi install_arm_linux_gnueabi install_aarch64_none_elf

.PHONY: remove_gcc_lib_links
remove_gcc_lib_links:
	if [ -e $(GCC_SRC)/newlib ] ; then \
	  rm -f $(GCC_SRC)/newlib; \
	fi
	if [ -e $(GCC_SRC)/libgloss ] ; then \
	  rm -f $(GCC_SRC)/libgloss; \
	fi

# arm-linux-eabi rules

.PHONY: install_arm_linux_gnueabi
install_arm_linux_gnueabi%: TARGET=arm-linux-gnueabi
install_arm_linux_gnueabi%: BUILDROOT=$(TD)/build/$(GCC_MAJOR_VERSION)/$(TARGET)$(CROSS_ID)
install_arm_linux_gnueabi%: PREFIX=$(TOOLCHAIN)/$(TARGET)
install_arm_linux_gnueabi%: PATH+=$(PREFIX)/bin
install_arm_linux_gnueabi%: SYSROOT=$(PREFIX)/sysroot

install_arm_linux_gnueabi: TARGET=arm-linux-gnueabi
install_arm_linux_gnueabi: remove_arm_tables_opt_file \
			install_arm_linux_gnueabi_check \
			install_gcc_prereqs \
			install_arm_linux_gnueabi_binutils \
			install_arm_linux_gnueabi_gdb \
			install_arm_linux_gnueabi_kernel_headers \
			install_arm_linux_gnueabi_gcc_stage1 \
			install_arm_linux_gnueabi_glibc \
			install_arm_linux_gnueabi_gcc_stage2 \
			install_arm_linux_gnueabi_adi_headers \
			remove_toolchain_top_level_libs_arm_linux

install_arm_linux_gnueabi_toolchain_release: STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/bin $(TOOLCHAIN)/$(TARGET)/$(TARGET)/bin
install_arm_linux_gnueabi_toolchain_release: LIB_STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION) $(TOOLCHAIN)/$(TARGET)/$(TARGET)/lib
install_arm_linux_gnueabi_toolchain_release: remove_arm_tables_opt_file \
			install_arm_linux_gnueabi_check \
			install_gcc_prereqs \
			install_arm_linux_gnueabi_binutils \
			install_arm_linux_gnueabi_gdb \
			install_arm_linux_gnueabi_kernel_headers \
			install_arm_linux_gnueabi_gcc_stage1 \
			install_arm_linux_gnueabi_glibc \
			install_arm_linux_gnueabi_gcc_stage2 \
			install_arm_linux_gnueabi_adi_headers \
			remove_toolchain_top_level_libs_arm_linux_release \
			strip_binaries \
			strip_libraries

install_arm_linux_gnueabi_adi_headers: HEADER_INSTALL_DIR=$(PREFIX)/$(TARGET)/include/adi
install_arm_linux_gnueabi_adi_headers: HEADER_LIST=$(ARM_LINUX_GNUEABI_ADI_INCLUDES)
install_arm_linux_gnueabi_adi_headers: CORTEX_DIR=cortex-a5
install_arm_linux_gnueabi_adi_headers: really_install_adi_headers_arm_linux_gnueabi

install_arm_linux_gnueabi_gdb_release: STRIP_PATHS="$(TOOLCHAIN)/$(TARGET)/bin $(TOOLCHAIN)/$(TARGET)/$(TARGET)/bin"
install_arm_linux_gnueabi_gdb_release: install_arm_linux_gnueabi_gdb strip_binaries

.PHONY: install_arm_linux_gnueabi_check
install_arm_linux_gnueabi_check: check_native_arm_linux_gnueabi

.PHONY: install_arm_linux_gnueabi_binutils
install_arm_linux_gnueabi_binutils: BUILD_DESC="ARM Linux Binutils"
install_arm_linux_gnueabi_binutils: CONFIG_FLAGS= \
					CFLAGS="$(ADI_CFLAGS)" \
					--disable-nls \
					--disable-werror \
					--with-gmp=$(GCC_REQS_DIR) \
					--with-mpfr=$(GCC_REQS_DIR) \
					--with-mpc=$(GCC_REQS_DIR) \
					--with-sysroot=$(SYSROOT)
install_arm_linux_gnueabi_binutils: install_binutils_arm_linux

.PHONY: install_arm_linux_gnueabi_kernel_headers
ifeq ($(KERNEL_TYPE),linaro)
install_arm_linux_gnueabi_kernel_headers: URL=$(KERNEL_URL)
install_arm_linux_gnueabi_kernel_headers: SERVER=$(KERNEL_SERVER)
install_arm_linux_gnueabi_kernel_headers: TARBALL=$(KERNEL_TAR)
install_arm_linux_gnueabi_kernel_headers: PKG=linux
install_arm_linux_gnueabi_kernel_headers: VER=$(KERNEL_VERSION)
install_arm_linux_gnueabi_kernel_headers: prep_src_kernel
else ifeq ($(KERNEL_TYPE),adi)
install_arm_linux_gnueabi_kernel_headers: GIT_MODULE_DIR=$(KERNEL_LOCAL_MODULE)
install_arm_linux_gnueabi_kernel_headers: GIT_REMOTE_MODULE=$(KERNEL_REMOTE_MODULE)
install_arm_linux_gnueabi_kernel_headers: GIT_BRANCH=$(KERNEL_BRANCH)
install_arm_linux_gnueabi_kernel_headers: GIT_VERSION=$(KERNEL_VERSION)
install_arm_linux_gnueabi_kernel_headers: prep_gitsrc_kernel
else ifeq ($(KERNEL_TYPE),custom)
#ensure appropriate variables have been set in user.mk
ifeq ($(strip $(KERNEL_SRC_DIR)),)
$(error For Custom kernels, please ensure KERNEL_SRC_DIR is set in user.mk))
endif
ifeq ($(strip $(KERNEL_MAJOR_VERSION)),)
$(error For Custom kernels, please ensure KERNEL_MAJOR_VERSION is set in user.mk))
endif
else
$(error Please ensure KERNEL_TYPE is set to something sensible and not: $(KERNEL_TYPE))
endif
install_arm_linux_gnueabi_kernel_headers: SRC_DIR=$(KERNEL_SRC_DIR)
install_arm_linux_gnueabi_kernel_headers:
	cd $(SRC_DIR) ; \
		$(MAKE) mrproper CC=$(PREFIX)/bin/$(TARGET)-gcc ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- ; \
		$(MAKE) INSTALL_HDR_PATH=$(SYSROOT)/usr ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- headers_install

.PHONY: install_arm_linux_gnueabi_gcc_stage1
install_arm_linux_gnueabi_gcc_stage1: BUILD_DIR=$(GCC_BUILD1)
install_arm_linux_gnueabi_gcc_stage1: BUILD_DESC="ARM Linux GCC Stage1"
install_arm_linux_gnueabi_gcc_stage1: GCC_BUILD_TARGET=all-gcc all-target-libgcc
install_arm_linux_gnueabi_gcc_stage1: GCC_INSTALL_TARGET=install-gcc install-target-libgcc
install_arm_linux_gnueabi_gcc_stage1: CONFIG_FLAGS= --enable-languages=c \
					--with-gmp=$(GCC_REQS_DIR) \
					--with-mpfr=$(GCC_REQS_DIR) \
					--with-mpc=$(GCC_REQS_DIR) \
					--with-cloog=$(GCC_REQS_DIR) \
					$(ENABLE_CHECKING) \
					--disable-shared \
					--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -lstdc++" \
					--without-headers --with-newlib \
					--disable-nls \
					$(MULTILIB_CONFIG_FLAG) \
					--disable-decimal-float \
					--disable-threads \
					--disable-libmudflap \
					--disable-libssp \
					--disable-libgomp \
					--without-ppl \
					--with-sysroot=$(SYSROOT) \
					--enable-languages=c \
					lt_cv_shlibpath_overrides_runpath=yes
install_arm_linux_gnueabi_gcc_stage1: remove_gcc_lib_links \
					install_gcc_build_stage1_arm_linux \
					install_arm_linux_dummy_libgcc_eh \
					remove_toolchain_top_level_libs_linux_gnueabi_gcc1

.PHONY: install_arm_linux_dummy_libgcc_eh
install_arm_linux_dummy_libgcc_eh:
# Create a dummy copy of libgcc_eh for now
	rm -f $(PREFIX)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION)/libgcc_eh.a
	rm -f `$(TARGET)-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`
	ln -vs $(PREFIX)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION)/libgcc.a \
	`$(TARGET)-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`


.PHONY: install_arm_linux_gnueabi_glibc
install_arm_linux_gnueabi_glibc: BUILD_DESC="ARM Linux Glibc"
install_arm_linux_gnueabi_glibc: CONFIG_FLAGS=--prefix=/usr \
					--with-gmp=$(GCC_REQS_DIR) \
					--with-mpfr=$(GCC_REQS_DIR) \
					--with-mpc=$(GCC_REQS_DIR) \
					--disable-profile \
					--enable-add-ons \
					$(MULTILIB_CONFIG_FLAG) \
					--enable-kernel=$(KERNEL_MAJOR_VERSION) \
					libc_cv_forced_unwind=yes \
					libc_cv_c_cleanup=yes
install_arm_linux_gnueabi_glibc: install_glibc_arm_linux_gnueabi_stage1 \
					adjust_gcc_specs_file install_toolchain_inclib_links \
					remove_toolchain_top_level_libs_arm_linux_glibc 

.PHONY: adjust_gcc_specs_file
adjust_gcc_specs_file:
	$(SCRIPTS_DIR)/update_gcc_specs.sh $(TARGET)-gcc

.PHONY: install_arm_linux_gnueabi_gcc_stage2
# Secondary build of GCC does require --host when cross-compiling.
install_arm_linux_gnueabi_gcc_stage2: ARCH=arm
install_arm_linux_gnueabi_gcc_stage2: BUILD_DIR=$(GCC_BUILD2)
install_arm_linux_gnueabi_gcc_stage2: BUILD_DESC="ARM Linux GCC Stage2"
install_arm_linux_gnueabi_gcc_stage2: GCC_BUILD_TARGET=all
install_arm_linux_gnueabi_gcc_stage2: GCC_INSTALL_TARGET=install
install_arm_linux_gnueabi_gcc_stage2: CONFIG_FLAGS= \
				$(MULTILIB_CONFIG_FLAG) \
				$(ENABLE_CHECKING) \
				--with-gmp=$(GCC_REQS_DIR) \
				--with-mpfr=$(GCC_REQS_DIR) \
				--with-mpc=$(GCC_REQS_DIR) \
				--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -static-libstdc++ -static-libgcc -lstdc++" \
				--with-cloog=$(GCC_REQS_DIR) \
				--with-isl=$(GCC_REQS_DIR) \
				--enable-clocale=gnu \
				--enable-shared --enable-threads=posix \
				--enable-__cxa_atexit --enable-languages=c,c++ \
				--disable-libstdcxx-pch  \
				--without-ppl \
				--with-sysroot=$(SYSROOT)
install_arm_linux_gnueabi_gcc_stage2: install_gcc_build_stage2_arm_linux \
				remove_toolchain_top_level_libs_arm_linux_gcc2

.PHONY: install_toolchain_inclib_links
install_toolchain_inclib_links:
	cd $(PREFIX)/$(TARGET) ; \
	rm -fr include lib ; \
	ln -s ../include . ; \
	ln -s ../lib .

.PHONY: install_arm_linux_gnueabi_gdb
install_arm_linux_gnueabi_gdb: BUILD_DESC="ARM Linux GDB"
install_arm_linux_gnueabi_gdb: CONFIG_FLAGS= \
				--with-gmp=$(GCC_REQS_DIR) \
				--with-mpfr=$(GCC_REQS_DIR) \
				--with-mpc=$(GCC_REQS_DIR) \
				--with-expat=$(GCC_REQS_DIR) \
				--with-sysroot=$(SYSROOT) \
				--disable-sim \
				--disable-nls
install_arm_linux_gnueabi_gdb: install_gdb_prereqs install_gdbtool_arm_linux install_gdbserver_arm_linux


# arm-none-eabi rules

include ./arm-none-eabi-source.mk

.PHONY: install_arm_none_eabi
install_arm_none_eabi%: TARGET=arm-none-eabi
install_arm_none_eabi%: BUILDROOT=$(TD)/build/$(GCC_MAJOR_VERSION)/$(TARGET)$(CROSS_ID)
install_arm_none_eabi%: PREFIX=$(TOOLCHAIN)/$(TARGET)

install_arm_none_eabi: TARGET=arm-none-eabi
install_arm_none_eabi: remove_arm_tables_opt_file \
			install_arm_none_eabi_check \
			install_gcc_prereqs \
			install_arm_none_eabi_gdb \
			install_arm_none_eabi_adi_headers \
			install_arm_none_eabi_binutils \
			install_arm_none_eabi_gcc_stage1 \
			install_arm_none_eabi_gcc_stage2 \
			remove_toolchain_top_level_libs_arm_none_eabi \
			remove_tmp_includes

install_arm_none_eabi_toolchain_release: STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/bin $(TOOLCHAIN)/$(TARGET)/$(TARGET)/bin
install_arm_none_eabi_toolchain_release: LIB_STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION) $(TOOLCHAIN)/$(TARGET)/$(TARGET)/lib
install_arm_none_eabi_toolchain_release: \
		remove_arm_tables_opt_file \
		install_arm_none_eabi_check \
		install_gcc_prereqs \
		install_arm_none_eabi_gdb \
		install_arm_none_eabi_adi_headers \
		install_arm_none_eabi_binutils \
		install_arm_none_eabi_gcc_stage1 \
		install_arm_none_eabi_gcc_stage2 \
		remove_toolchain_top_level_libs_arm_none_eabi_toolchain_release \
		remove_unwanted_crts \
		install_arm_none_eabi_additional_files \
		remove_dummy_libs \
		remove_tmp_includes \
		strip_binaries \
		strip_libraries

install_arm_none_eabi_adi_headers: HEADER_INSTALL_DIR=$(PREFIX)/$(TARGET)/include/adi
install_arm_none_eabi_adi_headers: HEADER_LIST=$(ARM_NONE_EABI_ADI_INCLUDES)
install_arm_none_eabi_adi_headers: CORTEX_DIR=cortex-a5
install_arm_none_eabi_adi_headers: really_install_adi_headers_arm_none_eabi

.PHONY: install_arm_none_eabi_check
install_arm_none_eabi_check: check_native_arm_none_eabi

.PHONY: install_arm_none_eabi_binutils
install_arm_none_eabi_binutils: BUILD_DESC="Bare Metal Binutils"
install_arm_none_eabi_binutils: CONFIG_FLAGS=--enable-interwork $(MULTILIB_CONFIG_FLAG) --disable-nls \
				--disable-werror --with-gmp=$(GCC_REQS_DIR) --with-mpfr=$(GCC_REQS_DIR) \
				--with-mpc=$(GCC_REQS_DIR) \
				CFLAGS="-I$(GCC_REQS_DIR) $(ADI_CFLAGS)"
install_arm_none_eabi_binutils: install_binutils_arm_none_initial

.PHONY: install_arm_none_eabi_gcc_stage1
install_arm_none_eabi_gcc_stage1: BUILD_DIR=$(GCC_BUILD1)
install_arm_none_eabi_gcc_stage1: GCC_BUILD_TARGET=all-gcc
install_arm_none_eabi_gcc_stage1: GCC_INSTALL_TARGET=install-gcc
install_arm_none_eabi_gcc_stage1: BUILD_DESC="Bare Metal GCC - Stage 1"
install_arm_none_eabi_gcc_stage1: CONFIG_FLAGS=--enable-interwork \
			--disable-multilib \
			$(ENABLE_CHECKING) \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-cloog=$(GCC_REQS_DIR) \
			--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -lstdc++" \
			--with-mpc=$(GCC_REQS_DIR) \
			--enable-languages="c,c++" \
			--with-newlib \
			--with-gnu-as \
			--with-gnu-ld \
			--disable-threads \
			--disable-decimal-float \
			--disable-nls \
			--disable-plugin
install_arm_none_eabi_gcc_stage1: remove_gcc_lib_links \
			install_gcc_build_arm_none_eabi_stage1 \
			remove_toolchain_top_level_libs_arm_none_eabi_gcc_stage1

.PHONY: create_arm_none_eabi_gcc_newlib_links
create_arm_none_eabi_gcc_newlib_links:
	ln -sf $(NEWLIB_SRC)/newlib $(GCC_SRC)
	ln -sf $(NEWLIB_SRC)/libgloss $(GCC_SRC)

.PHONY: install_arm_none_eabi_gcc_stage2
install_arm_none_eabi_gcc_stage2: BUILD_DIR=$(GCC_BUILD2)
install_arm_none_eabi_gcc_stage2: GCC_BUILD_TARGET=all
install_arm_none_eabi_gcc_stage2: GCC_INSTALL_TARGET=install
install_arm_none_eabi_gcc_stage2: BUILD_DESC="Bare Metal GCC - Stage 2"
install_arm_none_eabi_gcc_stage2: CONFIG_FLAGS=--enable-interwork \
			$(MULTILIB_CONFIG_FLAG)  \
			$(ENABLE_CHECKING) \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-mpc=$(GCC_REQS_DIR) \
			--with-isl=$(GCC_REQS_DIR) \
			--with-cloog=$(GCC_REQS_DIR) \
			--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic" \
			--enable-languages="c,c++" \
			--with-newlib \
			--with-gnu-as \
			--with-gnu-ld \
			--enable-newlib-reent-small \
			--with-headers=$(GCC_SRC)/newlib/libc/include \
			--disable-decimal-float \
			--disable-nls \
			--disable-plugin
install_arm_none_eabi_gcc_stage2: remove_gcc_lib_links \
			create_arm_none_eabi_gcc_newlib_links \
			install_arm_none_eabi_build_headers \
			install_gcc_build_arm_none_eabi_stage2 \
			remove_toolchain_top_level_libs_arm_none_eabi_gcc_stage2 \
			generate_dummy_libs \
			remove_toolchain_sys_include

# aarch64-none-elf rules

include ./aarch64-none-elf-source.mk

.PHONY: install_aarch64_none_elf
install_aarch64_none_elf%: ARCH=aarch64
install_aarch64_none_elf%: TARGET=aarch64-none-elf
install_aarch64_none_elf%: BUILDROOT=$(TD)/build/$(GCC_MAJOR_VERSION)/$(TARGET)$(CROSS_ID)
install_aarch64_none_elf%: PREFIX=$(TOOLCHAIN)/$(TARGET)

install_aarch64_none_elf: TARGET=aarch64-none-elf
install_aarch64_none_elf: remove_arm_tables_opt_file \
			install_aarch64_none_elf_check \
			install_gcc_prereqs \
			install_aarch64_none_elf_gdb \
			install_aarch64_none_elf_adi_headers \
			install_aarch64_none_elf_binutils \
			install_aarch64_none_elf_gcc_stage1 \
			install_aarch64_none_elf_gcc_stage2 \
			remove_toolchain_top_level_libs_aarch64_none_elf \
			remove_tmp_includes

install_aarch64_none_elf_toolchain_release: STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/bin $(TOOLCHAIN)/$(TARGET)/$(TARGET)/bin
install_aarch64_none_elf_toolchain_release: LIB_STRIP_PATHS=$(TOOLCHAIN)/$(TARGET)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION) $(TOOLCHAIN)/$(TARGET)/$(TARGET)/lib
install_aarch64_none_elf_toolchain_release: \
		remove_arm_tables_opt_file \
		install_aarch64_none_elf_check \
		install_gcc_prereqs \
		install_aarch64_none_elf_gdb \
		install_aarch64_none_elf_adi_headers \
		install_aarch64_none_elf_binutils \
		install_aarch64_none_elf_gcc_stage1 \
		install_aarch64_none_elf_gcc_stage2 \
		remove_toolchain_top_level_libs_aarch64_none_elf_toolchain_release \
		remove_unwanted_crts \
		install_aarch64_none_elf_additional_files \
		remove_dummy_libs \
		remove_tmp_includes \
		strip_binaries \
		strip_libraries

install_aarch64_none_elf_adi_headers: HEADER_INSTALL_DIR=$(PREFIX)/$(TARGET)/include/adi
install_aarch64_none_elf_adi_headers: HEADER_LIST=$(AARCH64_NONE_ELF_ADI_INCLUDES)
install_aarch64_none_elf_adi_headers: CORTEX_DIR=cortex-a55
install_aarch64_none_elf_adi_headers: really_install_adi_headers_aarch64_none_elf

.PHONY: install_aarch64_none_elf_check
install_aarch64_none_elf_check: check_native_aarch64_none_elf

.PHONY: install_aarch64_none_elf_binutils
install_aarch64_none_elf_binutils: BUILD_DESC="Bare Metal Binutils"
install_aarch64_none_elf_binutils: CONFIG_FLAGS=--enable-interwork $(MULTILIB_CONFIG_FLAG) --disable-nls \
				--disable-werror --with-gmp=$(GCC_REQS_DIR) --with-mpfr=$(GCC_REQS_DIR) \
				--with-mpc=$(GCC_REQS_DIR) \
				CFLAGS="-I$(GCC_REQS_DIR) $(ADI_CFLAGS)"
install_aarch64_none_elf_binutils: install_binutils_aarch64_none_initial

.PHONY: install_aarch64_none_elf_gcc_stage1
install_aarch64_none_elf_gcc_stage1: BUILD_DIR=$(GCC_BUILD1)
install_aarch64_none_elf_gcc_stage1: GCC_BUILD_TARGET=all-gcc
install_aarch64_none_elf_gcc_stage1: GCC_INSTALL_TARGET=install-gcc
install_aarch64_none_elf_gcc_stage1: BUILD_DESC="Bare Metal GCC - Stage 1"
install_aarch64_none_elf_gcc_stage1: CONFIG_FLAGS=--enable-interwork \
			--disable-multilib \
			$(ENABLE_CHECKING) \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-cloog=$(GCC_REQS_DIR) \
			--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -lstdc++" \
			--with-mpc=$(GCC_REQS_DIR) \
			--enable-languages="c,c++" \
			--without-long-double-128 \
			--with-newlib \
			--with-gnu-as \
			--with-gnu-ld \
			--disable-threads \
			--disable-decimal-float \
			--disable-libquadmath \
			--disable-nls \
			--disable-plugin
install_aarch64_none_elf_gcc_stage1: remove_gcc_lib_links \
			install_gcc_build_aarch64_none_elf_stage1 \
			remove_toolchain_top_level_libs_aarch64_none_elf_gcc_stage1

.PHONY: create_aarch64_none_elf_gcc_newlib_links
create_aarch64_none_elf_gcc_newlib_links:
	ln -sf $(NEWLIB_SRC)/newlib $(GCC_SRC)
	ln -sf $(NEWLIB_SRC)/libgloss $(GCC_SRC)

.PHONY: install_aarch64_none_elf_gcc_stage2
install_aarch64_none_elf_gcc_stage2: BUILD_DIR=$(GCC_BUILD2)
install_aarch64_none_elf_gcc_stage2: GCC_BUILD_TARGET=all
install_aarch64_none_elf_gcc_stage2: GCC_INSTALL_TARGET=install
install_aarch64_none_elf_gcc_stage2: BUILD_DESC="Bare Metal GCC - Stage 2"
install_aarch64_none_elf_gcc_stage2: CONFIG_FLAGS=--enable-interwork \
			$(MULTILIB_CONFIG_FLAG)  \
			$(ENABLE_CHECKING) \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-mpc=$(GCC_REQS_DIR) \
			--with-isl=$(GCC_REQS_DIR) \
			--with-cloog=$(GCC_REQS_DIR) \
			--with-stage1-libs="-L$(GCC_REQS_DIR)/lib -lexpat -static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic" \
			--enable-languages="c,c++" \
			--without-long-double-128 \
			--with-newlib \
			--with-gnu-as \
			--with-gnu-ld \
			--enable-newlib-reent-small \
			--with-headers=$(GCC_SRC)/newlib/libc/include \
			--disable-decimal-float \
			--disable-libquadmath \
			--disable-nls \
			--disable-plugin
install_aarch64_none_elf_gcc_stage2: remove_gcc_lib_links \
			create_aarch64_none_elf_gcc_newlib_links \
			install_aarch64_none_elf_build_headers \
			install_gcc_build_aarch64_none_elf_stage2 \
			remove_toolchain_top_level_libs_aarch64_none_elf_gcc_stage2 \
			generate_dummy_libs \
			remove_toolchain_sys_include

# ADI Headers required to build components
.PHONY: install_arm_none_eabi_build_headers
install_arm_none_eabi_build_headers:
	cp ${ADI_INCLUDE_DIR}/cortex-a5/adi_osal.h ${GCC_SRC}/libgcc/adi_osal.h
	cp ${ADI_INCLUDE_DIR}/cortex-a5/adi_osal_arch.h ${GCC_SRC}/libgcc/adi_osal_arch.h
	cp ${ADI_INCLUDE_DIR}/cortex-a5/sys/adi_mt_interface.h ${GCC_SRC}/libgcc/adi_mt_interface.h
	cp ${ADI_INCLUDE_DIR}/fatal_error_code.h ${GCC_SRC}/libgcc/fatal_error_code.h
	cp ${ADI_INCLUDE_DIR}/cortex-a5/adi_osal.h ${NEWLIB_SRC}/newlib/libc/sys/arm/adi/adi_osal.h
	cp ${ADI_INCLUDE_DIR}/cortex-a5/adi_osal_arch.h ${NEWLIB_SRC}/newlib/libc/sys/arm/adi/adi_osal_arch.h
	cp ${ADI_INCLUDE_DIR}/cortex-a5/sys/adi_mt_interface.h ${NEWLIB_SRC}/newlib/libc/sys/arm/adi/adi_mt_interface.h
	cp ${ADI_INCLUDE_DIR}/fatal_error_code.h ${NEWLIB_SRC}/newlib/libc/sys/arm/adi/fatal_error_code.h

.PHONY: install_aarch64_none_elf_build_headers
install_aarch64_none_elf_build_headers:
	cp ${ADI_INCLUDE_DIR}/cortex-a55/adi_osal.h ${GCC_SRC}/libgcc/adi_osal.h
	cp ${ADI_INCLUDE_DIR}/cortex-a55/adi_osal_arch.h ${GCC_SRC}/libgcc/adi_osal_arch.h
	cp ${ADI_INCLUDE_DIR}/cortex-a55/sys/adi_mt_interface.h ${GCC_SRC}/libgcc/adi_mt_interface.h
	cp ${ADI_INCLUDE_DIR}/fatal_error_code.h ${GCC_SRC}/libgcc/fatal_error_code.h
	cp ${ADI_INCLUDE_DIR}/cortex-a55/adi_osal.h ${NEWLIB_SRC}/newlib/libc/include
	cp ${ADI_INCLUDE_DIR}/cortex-a55/adi_osal_arch.h ${NEWLIB_SRC}/newlib/libc/include
	cp ${ADI_INCLUDE_DIR}/cortex-a55/sys/adi_mt_interface.h ${NEWLIB_SRC}/newlib/libc/include
	cp ${ADI_INCLUDE_DIR}/fatal_error_code.h ${NEWLIB_SRC}/newlib/libc/include

.PHONY: remove_dummy_headers
remove_dummy_headers:
ifeq ($(DO_BUILD),yes)
	find $(TOOLCHAIN)/ -name "adi_osal.h" -print -exec rm {} \;
	find $(TOOLCHAIN)/ -name "adi_osal_arch.h" -print -exec rm {} \;
endif

# GDB
.PHONY: install_arm_none_eabi_gdb
install_arm_none_eabi_gdb: BUILD_DESC="Bare Metal GDB"
install_arm_none_eabi_gdb: TARGET=arm-none-eabi
install_arm_none_eabi_gdb: CONFIG_FLAGS= \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-mpc=$(GCC_REQS_DIR) \
			--with-expat=$(GCC_REQS_DIR)/lib \
			--with-libexpat-prefix=$(GCC_REQS_DIR) \
			--without-python \
			--disable-sim \
			--disable-nls
install_arm_none_eabi_gdb: install_gdb_prereqs install_gdbtool_arm_baremetal

.PHONY: install_aarch64_none_elf_gdb
install_aarch64_none_elf_gdb: BUILD_DESC="Bare Metal GDB"
install_aarch64_none_elf_gdb: TARGET=aarch64-none-elf
install_aarch64_none_elf_gdb: CONFIG_FLAGS= \
			--with-gmp=$(GCC_REQS_DIR) \
			--with-mpfr=$(GCC_REQS_DIR) \
			--with-mpc=$(GCC_REQS_DIR) \
			--with-expat=$(GCC_REQS_DIR)/lib \
			--with-libexpat-prefix=$(GCC_REQS_DIR) \
			--without-python \
			--disable-sim \
			--disable-nls
install_aarch64_none_elf_gdb: install_gdb_prereqs install_gdbtool_arm_baremetal

# Source Prep

.PHONY: prep_gitsrc_%
prep_gitsrc_%: prep_gitsrc_dl prep_gitsrc_src
	@echo "git source prepared: $(GIT_MODULE_DIR)"

.PHONY: prep_gitsrc_dl
prep_gitsrc_dl: DIR=dl
prep_gitsrc_dl: GIT_REPO=$(GIT_REMOTE_MODULE)
prep_gitsrc_dl: gitsrc_clone_dl gitsrc_update_dl
	@echo "dl dir prepared."

.PHONY: prep_gitsrc_src
prep_gitsrc_src: DIR=src
prep_gitsrc_src: GIT_REPO=$(TD)/dl/$(GIT_MODULE_DIR)
prep_gitsrc_src: gitsrc_clone_src gitsrc_update_src
	@echo "src dir prepared."

.PHONY: gitsrc_clone_%
gitsrc_clone_%:
	@if [ ! -d $(TD)/$(DIR)/$(GIT_MODULE_DIR) ] ; then \
	  echo "Cloning: $(GIT_REPO)"; \
	  echo "into: $(DIR)/$(GIT_MODULE_DIR)"; \
	  cd $(TD)/$(DIR); \
	  git clone $(GIT_REPO) $(GIT_MODULE_DIR); \
	else \
	  echo "Repo exists in: $(DIR)/$(GIT_MODULE_DIR)"; \
	fi

.PHONY: gitsrc_update_%
gitsrc_update_%: BR=$(shell cd $(TD)/$(DIR)/$(GIT_MODULE_DIR); git rev-parse --abbrev-ref HEAD)
gitsrc_update_%:
	@if [ "$(UPDATE_SRCS_FROM_REMOTE_REPOS)" = "yes" ] ; then \
	  echo "Pulling latest sources from upstream."; \
	  cd $(TD)/$(DIR)/$(GIT_MODULE_DIR); \
	  git pull; \
	else \
	  echo "WARNING: Sources may not be up to date."; \
	fi
	@cd $(TD)/$(DIR)/$(GIT_MODULE_DIR); \
	if [ "$(BR)" != "$(GIT_BRANCH)" ]; then \
	  echo "Checking out branch: $(GIT_BRANCH)"; \
	  if [ -n $(GIT_BRANCH) ]; then \
	    if [ `git branch | grep --count ".* $(GIT_BRANCH)$$"` -eq 1 ]; then \
	      echo "Found local branch $(GIT_BRANCH), updating..."; \
	      git checkout $(GIT_BRANCH); \
	      git pull; \
	    else \
	      echo "No local branch '$(GIT_BRANCH)', creating..."; \
	      git checkout -b $(GIT_BRANCH) origin/$(GIT_BRANCH); \
	    fi \
	  else \
	    if [ -n $(GIT_VERSION) ]; then \
	      git checkout $(GIT_VERSION); \
	    fi \
	  fi \
	else \
	  echo "Already on branch: $(GIT_BRANCH)"; \
	fi

.PHONY: prep_src_%
ifeq ($(USE_SRC_MIRROR),yes)
prep_src_%: PREP_COPY_COMMAND=wget $(MIRROR_PATH)/$(SERVER)/$(TARBALL)
else
prep_src_%: PREP_COPY_COMMAND=wget --no-check-certificate $(URL)
endif
prep_src_%:
	echo "$(TARBALL)"
	if  [ ! -e $(TD)/dl/$(TARBALL) ] && [ ! -e $(TD)/src/$(PKG)-$(VER) ] ; then \
	  echo "Downloading $(PKG)-$(VER)"; \
	  mkdir -p $(TD)/dl; \
	  cd $(TD)/dl; $(PREP_COPY_COMMAND); \
	fi
	if [ ! -e $(TD)/src/$(PKG)-$(VER) ] ; then \
	  echo "Unpacking $(PKG)-$(VER)"; \
	  mkdir -p $(TD)/src; \
	  cd $(TD)/src; \
	  tar -xf $(TD)/dl/$(TARBALL); \
	fi
	if [ "${CREATE_GIT_SRC}" = "yes" ] ; then \
	  if [ ! -d ${SRC_DIR}/.git ] ; then \
            echo "Creating GIT Repo in ${SRC_DIR}"; \
	    cd ${SRC_DIR} ; \
	    git init ; \
	    git add -A ; \
	    echo "Adding all srcs" ; \
	    git commit -q -m "Initial revision based on tar file" ; \
	  fi \
	fi
	echo "Patching $(PKG)-$(VER)"
	$(SCRIPTS_DIR)/patcher $(PATCHER_OPT) $(PKG) $(VER) $(ADDITIONAL_PARTS)
	echo "Sources Prepared"

# Remove top level libraries. We don't ship these. Users should be using the -mproc switch to select a part specific CRT.
.PHONY: remove_toolchain_top_level_libs_%
remove_toolchain_top_level_libs_%:
	@echo "Removing top level libraries and CRTs"
ifeq ($(DO_BUILD),yes)
	@echo "In $(TOOLCHAIN)/$(TARGET)/$(TARGET)/lib"
	cd $(TOOLCHAIN)/$(TARGET)/$(TARGET)/lib && rm -rf $(TOP_LEVEL_LIBS_TO_REMOVE)
	@echo "In $(TOOLCHAIN)/$(TARGET)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION)"
	cd $(TOOLCHAIN)/$(TARGET)/lib/gcc/$(TARGET)/$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION) &&  rm -rf $(TOP_LEVEL_LIBS_TO_REMOVE)
endif


# Create dummy libs
.PHONY: generate_dummy_libs
ifeq ($(BUILD_WINDOWS_CROSS),yes)
generate_dummy_libs: TEMPCC=$(TARGET)-gcc
generate_dummy_libs: TEMPAR=$(TARGET)-ar
else
generate_dummy_libs: TEMPCC=$(TOOLCHAIN)/$(TARGET)/bin/$(TARGET)-gcc
generate_dummy_libs: TEMPAR=$(TOOLCHAIN)/$(TARGET)/bin/$(TARGET)-ar
endif
generate_dummy_libs:
	@echo "Generating dummy libraries:"
ifeq ($(DO_BUILD),yes)
	echo "void _adi_dummy(){}" | $(TEMPCC) -c -xc -o $(BUILDROOT)/dummy.o -
	$(TEMPAR) -rcs $(BUILDROOT)/dummy.a $(BUILDROOT)/dummy.o
	find $(TOOLCHAIN)/$(TARGET)/ -iname "libm.a" -execdir cp $(BUILDROOT)/dummy.a ./libssl.a \;
	find $(TOOLCHAIN)/$(TARGET)/ -iname "libm.a" -execdir cp $(BUILDROOT)/dummy.a ./libdrv.a \;
	find $(TOOLCHAIN)/$(TARGET)/ -iname "libm.a" -execdir cp $(BUILDROOT)/dummy.a ./libosal.a \;
	find $(TOOLCHAIN)/$(TARGET)/ -iname "libm.a" -execdir cp $(BUILDROOT)/dummy.a ./libfftacc.a \;
	$(TEMPCC) -c $(TD)/src/support_files/adi_mmu_Init.S -o $(BUILDROOT)/adi_mmu_Init.o
	$(TEMPCC) -c $(TD)/src/support_files/adi_cache_Init.c -o $(BUILDROOT)/adi_cache_Init.o
	$(TEMPAR) -rcs $(BUILDROOT)/dummy.a $(BUILDROOT)/adi_mmu_Init.o $(BUILDROOT)/adi_cache_Init.o
	find $(TOOLCHAIN)/$(TARGET)/ -iname "libm.a" -execdir cp $(BUILDROOT)/dummy.a ./librtadi.a \;
endif

# Remove dummy libs
.PHONY: remove_dummy_libs
remove_dummy_libs:
	@echo "Remove dummy libraries:"
ifeq ($(DO_BUILD),yes)
	find $(TOOLCHAIN)/ -name "libssl.a" -print -exec rm {} \;
	find $(TOOLCHAIN)/ -name "libosal.a" -print -exec rm {} \;
	find $(TOOLCHAIN)/ -name "libdrv.a" -print -exec rm {} \;
	find $(TOOLCHAIN)/ -name "libfftacc.a" -print -exec rm {} \;
	find $(TOOLCHAIN)/ -name "librtadi.a" -print -exec rm {} \;
endif

# Remove temporary includes
.PHONY: remove_tmp_includes
remove_tmp_includes: HEADER_INSTALL_DIR=$(PREFIX)/$(TARGET)/include/adi
remove_tmp_includes: HEADER_DIR_LIST=$(ADI_INCLUDE_TMP_SUB_DIRS)
remove_tmp_includes: HEADER_LIST=$(ADI_TMP_INCLUDES)
remove_tmp_includes:
	@echo "Removing temporary includes:"
ifeq ($(DO_BUILD),yes)
	for f in $(HEADER_LIST) ;\
	do \
		rm -f $(HEADER_INSTALL_DIR)/$$f ; \
	done
	for d in $(HEADER_DIR_LIST) ;\
	do \
		rm -rf $(HEADER_INSTALL_DIR)/$$d ; \
	done
endif

# Remove contents of sys-include for newlib.  It's populated with cruft.
.PHONY: remove_toolchain_sys_include
remove_toolchain_sys_include:
	@echo "Removing contents of sys-include"
	rm -rf $(TOOLCHAIN)/$(TARGET)/$(TARGET)/sys-include/*

# Remove unwanted CRT objects from baremetal toolchain
.PHONY: remove_unwanted_crts
remove_unwanted_crts:
	@echo "Remove unwanted CRT objects:"
	find $(TOOLCHAIN)/$(TARGET) -name "crt0.o" -print -exec rm {} \;

# Strip binaries
.PHONY: strip_binaries
strip_binaries:
	@echo "Stripping binaries in $(STRIP_PATHS)"
	for f in $(STRIP_PATHS)  ; \
	do \
	  echo "Stripping files in $${f}" ; \
	  for i in $${f}/* ; \
	  do \
	    echo $${i} ; \
	    $(STRIP) $${i} ; \
	  done \
	done

# Strip debug information from libraries and objects.
# Skips stripping libc.a though as fatal error output relies on
# adi_fatal_error_data.c being built debug.
# Note that libg.a is a hard link to libc.a so we also skip stripping it.
.PHONY: strip_libraries
strip_libraries:
	@echo "Stripping libraries (except libc.a) in $(LIB_STRIP_PATHS)"
	for f in $(LIB_STRIP_PATHS) ; \
	do \
	  echo "Stripping files in sub-directories of $${f}" ; \
	  for i in $$(find $${f} -mindepth 2 -maxdepth 2 -name "*.[ao]" ! -name "lib[cg].a") ; \
	  do \
	    echo $${i} ; \
	    $(TARGET)-strip -g $${i} ; \
	  done \
	done

# General rules 

.PHONY: distclean
distclean: clean clean_dl
	rm -rf output/*
	rm -rf src/*

.PHONY: clean
clean: clean_build clean_gcc_prereqs clean_ldr clean_pthread

.PHONY: clean_all
clean_all: clean_build clean_sources

.PHONY: clean_sources
clean_sources: clean_source_glibc clean_source_gdb clean_source_gmp clean_source_mpfr clean_source_mpc clean_source_expat

.PHONY: clean_gcc_reqs
clean_gcc_reqs:
	$(RM) -rf $(GCC_REQS_DIR)

.PHONY: clean_build
clean_build:
	$(RM) -rf $(TD)/build/*

.PHONY: clean_dl
clean_dl:
	$(RM) -rf $(TD)/dl/*

# ############################# BUILD RULES ####################################

# Check that there is a native cross compiler for Canadian Cross.
# If this has failed, you haven't built it, or it isn't in your PATH.
ifeq ($(BUILD_WINDOWS_CROSS),yes)
check_native_%:	; which $(TARGET)-gcc > /dev/null
else
check_native_%: ;
endif

# GCC Prerequisites

install_gcc_prereqs: install_gmp install_mpfr install_mpc install_isl install_cloog install_expat
install_gdb_prereqs: install_gmp install_mpfr install_mpc install_expat

clean_gcc_prereqs: clean_gmp clean_mpfr clean_mpc
	@rm -rf $(GCC_REQS_DIR)

# Generate adi-processors.def for GCC
# Don't call this directly. Must be called via install_gcc_*
generate_adi_part_specific_files:
ifeq ($(DO_BUILD),yes)
	@echo "Generating ADI Part Specific Files"
	$(SCRIPTS_DIR)/generate_adi_part_files.php \
		-target $(TARGET) \
		-config $(SCRIPTS_DIR)/adi_parts_config/$(ADI_PROJECT_NAME) \
		-xml $(ARCHDEF_DIR) \
		-newlib $(NEWLIB_SRC) \
		-gcc $(GCC_SRC) \
		-binutils $(BINUTILS_SRC) \
		-toolchain $(TOOLCHAIN)
endif

# ADI Headers

really_install_adi_headers_%: HEADER_DIR_LIST=$(ADI_INCLUDE_SUB_DIRS)
really_install_adi_headers_%:
	@echo "Installing ADI proprietary header files"
	for d in $(HEADER_DIR_LIST) ;\
	do \
		mkdir -p $(HEADER_INSTALL_DIR)/$$d ; \
	done
	for f in $(HEADER_LIST) ;\
	do \
		cp $(ADI_INCLUDE_DIR)/$$f $(HEADER_INSTALL_DIR)/$$f ; \
	done

# GCC Rules
install_gcc_build_%: URL=$(GCC_URL)
install_gcc_build_%: SERVER=$(GCC_SERVER)
install_gcc_build_%: TARBALL=$(GCC_TAR)
install_gcc_build_%: PKG=gcc
install_gcc_build_%: VER=$(GCC_VERSION)
install_gcc_build_%: SRC_DIR=$(GCC_SRC)
# Just apply additional part support patches, if any
install_gcc_build_%: PATCHER_OPT=-p
install_gcc_build_%: CREATE_GIT_SRC=no
install_gcc_build_%: prep_src_gcc
install_gcc_build_%: generate_adi_part_specific_files
	echo "]0;Building GCC ($(BUILD_DESC))"
	
	$(MKDIR) $(BUILD_DIR)
ifeq ($(DO_CONFIG),yes)
	cd $(BUILD_DIR) ; \
	  $(CONFIG_ENV) $(SRC_DIR)/configure $(GCC_COMMON_CONFIG_OPTS) \
	  --target=$(TARGET) --host=$(HOST) --build=$(BUILD) --prefix=$(PREFIX) \
	  	  $(CONFIG_FLAGS) CFLAGS="$(ADI_CFLAGS)" CXXFLAGS="$(ADI_CFLAGS)" \
		NEWLIB_CFLAGS="$(ADI_LIB_CFLAGS)" \
		CFLAGS_FOR_TARGET="$(ADI_LIB_CFLAGS) $(NEWLIB_HOST_FLAG) "
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(BUILD_DIR) $(GCC_BUILD_TARGET)
	$(MAKE) -C $(BUILD_DIR) $(GCC_INSTALL_TARGET)
endif
remove_arm_tables_opt_file:
	rm -f $(GCC_SRC)/gcc/config/arm/arm-tables.opt

update_newlib_makefiles: generate_adi_part_specific_files
	cd $(NEWLIB_SRC)/newlib/libc/sys/arm && $(AUTOMAKE) --cygnus
	cd $(NEWLIB_SRC)/newlib/libc/sys && $(AUTOMAKE) --cygnus
	cd $(NEWLIB_SRC)/newlib/libc && $(AUTOMAKE) --cygnus
	cd $(NEWLIB_SRC)/newlib && $(AUTOMAKE) --cygnus

clean_gcc_build_%:
	rm -rf $(BUILD_DIR)

# GLIBC Rules
install_glibc_%: URL=$(GLIBC_URL)
install_glibc_%: SERVER=$(GLIBC_SERVER)
install_glibc_%: TARBALL=$(GLIBC_TAR)
install_glibc_%: PKG=glibc
install_glibc_%: VER=$(GLIBC_VERSION)
install_glibc_%: SRC_DIR=$(GLIBC_SRC)

install_glibc_%: prep_src_glibc
	echo "]0;Building GLIBC ($(BUILD_DESC))"
	$(MKDIR) $(GLIBC_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(GLIBC_BUILD) ; \
	$(SRC_DIR)/configure --build=$(BUILD) --host=$(TARGET) \
		--enable-add-ons=nptl  \
		$(CONFIG_FLAGS) \
		CFLAGS="$(ADI_LIB_CFLAGS)"
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(GLIBC_BUILD)
	$(MAKE) -C $(GLIBC_BUILD) install install_root="${SYSROOT}"
endif

clean_glibc_%:
	rm -rf $(GLIBC_BUILD)
	
clean_source_glibc:
	rm -rf $(SRC_DIR)

# Generate adi-processors.def for GAS
create_gas_adi_processors_def: generate_adi_part_specific_files

# Binutils Rules
%_binutils: URL=$(BINUTILS_URL)
%_binutils: SERVER=$(BINUTILS_SERVER)
%_binutils: TARBALL=$(BINUTILS_TAR)
%_binutils: PKG=binutils
%_binutils: VER=$(BINUTILS_VERSION)
%_binutils: SRC_DIR=$(BINUTILS_SRC)

install_binutils_%: create_gas_adi_processors_def
	echo "]0;Building Binutils ($(BUILD_DESC))"
	$(MKDIR) $(BINUTILS_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(BINUTILS_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --target=$(TARGET) --prefix=$(PREFIX) $(CONFIG_FLAGS)
	$(MAKE) -C $(BINUTILS_BUILD) configure-host
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(BINUTILS_BUILD) all
	$(MAKE) -C $(BINUTILS_BUILD) install
endif

clean_binutils:
	rm -rf $(BINUTILS_BUILD)

# GDB Rules
%_gdb: URL=$(GDB_URL)
%_gdb: SERVER=$(GDB_SERVER)
%_gdb: TARBALL=$(GDB_TAR)
%_gdb: PKG=gdb
%_gdb: VER=$(GDB_VERSION)
%_gdb: SRC_DIR=$(GDB_SRC)

install_gdbtool_%: prep_src_gdb 
	echo "]0;Building GDB ($(BUILD_DESC))"
	$(MKDIR) $(GDB_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(GDB_BUILD) ; \
	$(CONFIG_ENV) $(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --target=$(TARGET) --prefix=$(PREFIX) $(CONFIG_FLAGS)
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(GDB_BUILD)
	$(MAKE) -C $(GDB_BUILD) install
endif

clean_gdb:
	rm -rf $(GDB_BUILD)

clean_source_gdb:
	rm -rf $(SRC_DIR)


install_gdbserver_%: prep_src_gdb 
	echo "]0;Building GDB Server ($(BUILD_DESC))"
	$(MKDIR) $(GDBSERVER_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(GDBSERVER_BUILD) ; \
	$(CONFIG_ENV) $(SRC_DIR)/gdb/gdbserver/configure --host=$(TARGET) --build=$(BUILD) --target=$(TARGET) --prefix=$(PREFIX) $(CONFIG_FLAGS)
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(GDBSERVER_BUILD)
	$(MAKE) -C $(GDBSERVER_BUILD) install
endif

clean_gdbserver:
	rm -rf $(GDBSERVER_BUILD)

clean_source_gdbserver:
	rm -rf $(SRC_DIR)

# GMP Rules
%_gmp: URL=$(GMP_URL)
%_gmp: SERVER=$(GMP_SERVER)
%_gmp: TARBALL=$(GMP_TAR)
%_gmp: PKG=gmp
%_gmp: VER=$(GMP_VERSION)
%_gmp: SRC_DIR=$(GMP_SRC)

.PHONY: install_gmp
install_gmp: prep_src_gmp
	echo "]0;Building GMP"
	$(MKDIR) $(GMP_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(GMP_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(GMP_BUILD)
	$(MAKE) -C $(GMP_BUILD) install
endif

clean_gmp:
	rm -rf $(GMP_BUILD)

clean_source_gmp:
	rm -rf $(SRC_DIR)

# MPFR Rules
%_mpfr: URL=$(MPFR_URL)
%_mpfr: SERVER=$(MPFR_SERVER)
%_mpfr: TARBALL=$(MPFR_TAR)
%_mpfr: PKG=mpfr
%_mpfr: VER=$(MPFR_VERSION)
%_mpfr: SRC_DIR=$(MPFR_SRC)

.PHONY: install_mpfr
install_mpfr: prep_src_mpfr
	echo "]0;Building MPFR"
	$(MKDIR) $(MPFR_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(MPFR_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) \
		--with-gmp=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(MPFR_BUILD)
	$(MAKE) -C $(MPFR_BUILD) install
endif

clean_mpfr:
	rm -rf $(MPFR_BUILD)

clean_source_mpfr:
	rm -rf $(SRC_DIR)

# ISL Rules
%_isl: URL=$(ISL_URL)
%_isl: SERVER=$(ISL_SERVER)
%_isl: TARBALL=$(ISL_TAR)
%_isl: PKG=isl
%_isl: VER=$(ISL_VERSION)
%_isl: SRC_DIR=$(ISL_SRC)

.PHONY: install_isl
install_isl: prep_src_isl
	echo "]0;Building ISL"
	$(MKDIR) $(ISL_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(ISL_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) \
		--with-gmp-prefix=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(ISL_BUILD)
	$(MAKE) -C $(ISL_BUILD) install
endif

clean_isl:
	rm -rf $(ISL_BUILD)

clean_source_isl:
	rm -rf $(SRC_DIR)

# CLOOG Rules
%_cloog: URL=$(CLOOG_URL)
%_cloog: SERVER=$(CLOOG_SERVER)
%_cloog: TARBALL=$(CLOOG_TAR)
%_cloog: PKG=cloog
%_cloog: VER=$(CLOOG_VERSION)
%_cloog: SRC_DIR=$(CLOOG_SRC)

.PHONY: install_cloog
install_cloog: prep_src_cloog
	echo "]0;Building CLOOG"
	$(MKDIR) $(CLOOG_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(CLOOG_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) \
		--with-gmp-prefix=$(GCC_REQS_DIR) --with-isl-prefix=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(CLOOG_BUILD)
	$(MAKE) -C $(CLOOG_BUILD) install
endif

clean_cloog:
	rm -rf $(CLOOG_BUILD)

clean_source_cloog:
	rm -rf $(SRC_DIR)

# MPC Rules
%_mpc: URL=$(MPC_URL)
%_mpc: SERVER=$(MPC_SERVER)
%_mpc: TARBALL=$(MPC_TAR)
%_mpc: PKG=mpc
%_mpc: VER=$(MPC_VERSION)
%_mpc: SRC_DIR=$(MPC_SRC)

.PHONY: install_mpc
install_mpc: prep_src_mpc
	echo "]0;Building MPC"
	$(MKDIR) $(MPC_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(MPC_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) \
		--with-gmp=$(GCC_REQS_DIR) \
		--with-mpfr=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(MPC_BUILD)
	$(MAKE) -C $(MPC_BUILD) install
endif

clean_mpc:
	rm -rf $(MPC_BUILD)

clean_source_mpc:
	rm -rf $(SRC_DIR)

# EXPAT Rules
%_expat: URL=$(EXPAT_URL)
%_expat: SERVER=$(EXPAT_SERVER)
%_expat: TARBALL=$(EXPAT_TAR)
%_expat: PKG=expat
%_expat: VER=$(EXPAT_VERSION)
%_expat: SRC_DIR=$(EXPAT_SRC)

.PHONY: install_expat
install_expat: prep_src_expat
	echo "]0;Building expat"
	$(MKDIR) $(EXPAT_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(EXPAT_BUILD) ; \
	$(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) \
		--prefix=$(GCC_REQS_DIR) --disable-shared
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(EXPAT_BUILD) all
	$(MAKE) -C $(EXPAT_BUILD) install
endif

clean_expat:
	rm -rf $(EXPAT_BUILD)

clean_source_expat:
	rm -rf $(SRC_DIR)

# ADI Specific rules for packaging products. Nothing to do with building the product.
-include packaging.mk
