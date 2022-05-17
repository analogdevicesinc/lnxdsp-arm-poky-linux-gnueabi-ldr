# Copyright (c) 2014-2020, Analog Devices, Inc.  All rights reserved.
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

# Configuration for downloading source

# GMP Package
GMP_VERSION=6.1.2
GMP_TAR=gmp-$(GMP_VERSION).tar.bz2
GMP_SRC=$(TD)/src/gmp-$(GMP_VERSION)
GMP_BUILD=$(BUILDROOT)/gmp_build
GMP_SERVER=gmplib.org
GMP_URL=https://$(GMP_SERVER)/download/gmp/$(GMP_TAR)

# MPFR Package
MPFR_VERSION=3.1.6
MPFR_TAR=mpfr-$(MPFR_VERSION).tar.bz2
MPFR_SRC=$(TD)/src/mpfr-$(MPFR_VERSION)
MPFR_BUILD=$(BUILDROOT)/mpfr_build
MPFR_SERVER=ftp.gnu.org
MPFR_URL=https://$(MPFR_SERVER)/gnu/mpfr/$(MPFR_TAR)

# CLooG Package
CLOOG_VERSION=0.18.4
CLOOG_TAR=cloog-$(CLOOG_VERSION).tar.gz
CLOOG_SRC=$(TD)/src/cloog-$(CLOOG_VERSION)
CLOOG_BUILD=$(BUILDROOT)/cloog_build
CLOOG_SERVER=www.bastoul.net
CLOOG_URL=https://$(CLOOG_SERVER)/cloog/pages/download/$(CLOOG_TAR)

# ISL Package
ISL_VERSION=0.18
ISL_TAR=isl-$(ISL_VERSION).tar.bz2
ISL_SRC=$(TD)/src/isl-$(ISL_VERSION)
ISL_BUILD=$(BUILDROOT)/isl_build
ISL_SERVER=sourceware.org
ISL_URL=https://$(ISL_SERVER)/pub/gcc/infrastructure/$(ISL_TAR)

# MPC Package
MPC_VERSION=1.0.3
MPC_TAR=mpc-$(MPC_VERSION).tar.gz
MPC_SRC=$(TD)/src/mpc-$(MPC_VERSION)
MPC_BUILD=$(BUILDROOT)/mpc_build
MPC_SERVER=ftp.gnu.org
MPC_URL=https://$(MPC_SERVER)/gnu/mpc/$(MPC_TAR)

# Binutils Package
BINUTILS_VERSION=2.35
BINUTILS_TAR=binutils-$(BINUTILS_VERSION).tar.xz
BINUTILS_SRC=$(TD)/src/binutils
BINUTILS_BUILD=$(BUILDROOT)/binutils_build
BINUTILS_SERVER=ftp.gnu.org
BINUTILS_URL=https://$(BINUTILS_SERVER)/gnu/binutils/$(BINUTILS_TAR)

# GCC Package
GCC_VERSION=$(GCC_MAJOR_VERSION).$(GCC_MINOR_VERSION)
GCC_SRC=$(TD)/src/gcc
GCC_TAR=gcc-$(GCC_VERSION).tar.xz
GCC_SERVER=ftp.gnu.org
GCC_URL=ftp://$(GCC_SERVER)/gnu/gcc/gcc-$(GCC_VERSION)/$(GCC_TAR)
GCC_BUILD1=$(BUILDROOT)/gcc_build1
GCC_BUILD2=$(BUILDROOT)/gcc_build2
GITLOG:=$(shell git log | head -1 | awk '{print $$2}')
NETWORK_HOSTNAME:=$(shell uname -n)
GCC_COMMON_CONFIG_OPTS=--with-pkgversion="Analog Devices Inc. ARM Tools (${GITLOG}). Distributed as part of CrossCore Embedded Studio and associated add-ins. ${BUILD_TAG} ${BUILD_ID} ${NETWORK_HOSTNAME}" --with-bugurl="processor.tools.support@analog.com"

# NEWLIB Package
NEWLIB_VERSION=3.0.0
NEWLIB_TAR=newlib-$(NEWLIB_VERSION).tar.gz
NEWLIB_SRC=$(TD)/src/newlib
NEWLIB_SERVER=sourceware.org
NEWLIB_URL=https://$(NEWLIB_SERVER)/pub/newlib/$(NEWLIB_TAR)
NEWLIB_BUILD=$(BUILDROOT)/newlib_build

# GLIBC Package
GLIBC_VERSION=2.27
GLIBC_TAR=glibc-$(GLIBC_VERSION).tar.gz
GLIBC_SRC=$(TD)/src/glibc-$(GLIBC_VERSION)
GLIBC_SERVER=ftp.gnu.org
GLIBC_URL=https://$(GLIBC_SERVER)/gnu/glibc/$(GLIBC_TAR)
GLIBC_BUILD=$(BUILDROOT)/glibc_build

# GDB Package
GDB_VERSION=8.1
GDB_TAR=gdb-$(GDB_VERSION).tar.xz
GDB_SRC=$(TD)/src/gdb-$(GDB_VERSION)
GDB_SERVER=ftp.gnu.org
GDB_URL=https://$(GDB_SERVER)/gnu/gdb/$(GDB_TAR)
GDB_BUILD=$(BUILDROOT)/gdb_build
GDBSERVER_BUILD=$(BUILDROOT)/gdbserver_build

# Kernel Package
# The following can be set to linaro, custom or adi.  The default is adi. 
# If you wish to change this, please set the variable in your user.mk file.
KERNEL_TYPE?=adi
ifeq ($(KERNEL_TYPE),linaro)
KERNEL_MAJOR_VERSION=3.6
KERNEL_RC=rc6
KERNEL_DATE=12.09
KERNEL_VERSION=linaro-$(KERNEL_MAJOR_VERSION)-$(KERNEL_RC)-20$(KERNEL_DATE)
KERNEL_TAR=linux-$(KERNEL_VERSION).tar.bz2
KERNEL_SRC_DIR=$(TD)/src/linux-$(KERNEL_VERSION)
KERNEL_SERVER=releases.linaro.org
KERNEL_URL=https://$(KERNEL_SERVER)/$(KERNEL_DATE)/components/kernel/linux-linaro/$(KERNEL_TAR)
else ifeq ($(KERNEL_TYPE),custom)
# When using a custom kernel, please ensure that KERNEL_SRC_DIR and 
# KERNEL_MAJOR_VERSION have been set in your user.mk
else ifeq ($(KERNEL_TYPE),adi)
KERNEL_MAJOR_VERSION=4.16
KERNEL_SRC_DIR=$(TD)/src/linux-kernel
KERNEL_REMOTE_MODULE=https://bitbucket.analog.com/scm/dte/linux.git
KERNEL_LOCAL_MODULE=linux-kernel
KERNEL_BRANCH=develop/linuxaddin-1.4.0
else
$(error Please ensure KERNEL_TYPE is set to something sensible and not: $(KERNEL_TYPE))
endif

# LDR Package
LDR_SRC=$(TD)/src/ldr
LDR_BUILD=$(BUILDROOT)/ldr_build

#EXPAT Package
EXPAT_VERSION=2.2.5
EXPAT_TAR=expat-$(EXPAT_VERSION).tar.bz2
EXPAT_SRC=$(TD)/src/expat-$(EXPAT_VERSION)
EXPAT_BUILD=$(BUILDROOT)/expat_build
EXPAT_SERVER=downloads.sourceforge.net
EXPAT_URL=https://$(EXPAT_SERVER)/expat/$(EXPAT_TAR)

# LIBUSB Package
LIBUSB_MAJOR_VERSION=1.0
LIBUSB_VERSION=$(LIBUSB_MAJOR_VERSION).18
LIBUSB_TAR=libusb-$(LIBUSB_VERSION).tar.bz2
LIBUSB_SRC=$(TD)/src/libusb-$(LIBUSB_VERSION)
LIBUSB_BUILD=$(BUILDROOT)/libusb_build
LIBUSB_SERVER=downloads.sourceforge.net
LIBUSB_URL=https://$(LIBUSB_SERVER)/libusb/libusb-$(LIBUSB_MAJOR_VERSION)/libusb-$(LIBUSB_VERSION)/$(LIBUSB_TAR)
