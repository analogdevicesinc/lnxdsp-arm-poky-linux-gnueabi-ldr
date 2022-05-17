# Copyright (c) 2014-2018, Analog Devices, Inc.  All rights reserved.
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

# LDR
%_ldr: PKG=ldr
%_ldr: SRC_DIR=$(LDR_SRC)

.phony: install_ldr
ifeq ($(BUILD_WINDOWS_CROSS),yes)
install_ldr: install_libusb
endif
install_ldr: get_elf
	echo "]0;Building ldr"
ifeq ($(DO_CONFIG),yes)
	$(MKDIR) $(LDR_BUILD)
ifeq ($(BUILD_WINDOWS_CROSS),yes)
	cd $(LDR_BUILD) && \
	$(SRC_DIR)/configure --host=$(HOST) --prefix=$(LDR_BUILD) PKG_CONFIG_LIBDIR=$(GCC_REQS_DIR)/lib/pkgconfig LDFLAGS=-static
else
	cd $(LDR_BUILD) && \
	$(SRC_DIR)/configure --host=$(HOST) --prefix=$(LDR_BUILD)
endif
endif
ifeq ($(DO_BUILD),yes)
	make -C $(LDR_BUILD) CFLAGS="-DADI_CHANGES"
	make -C $(LDR_BUILD) install
	! test -d $(TOOLCHAIN)/arm-none-eabi/bin || cp $(LDR_BUILD)/bin/ldr${SUFFIX} $(TOOLCHAIN)/arm-none-eabi/bin/arm-none-eabi-ldr${SUFFIX}
	! test -d $(TOOLCHAIN)/aarch64-none-elf/bin || cp $(LDR_BUILD)/bin/ldr${SUFFIX} $(TOOLCHAIN)/aarch64-none-elf/bin/aarch64-none-elf-ldr${SUFFIX}
	! test -d $(TOOLCHAIN)/arm-linux-gnueabi/bin || cp $(LDR_BUILD)/bin/ldr${SUFFIX} $(TOOLCHAIN)/arm-linux-gnueabi/bin/arm-linux-gnueabi-ldr${SUFFIX}
endif

.phony: clean_ldr
clean_ldr:
	! test -f $(LDR_BUILD)/Makefile || make -C $(LDR_BUILD) clean

# Currently, all of the following are only configured for Windows Canadian
# Cross builds.  Some of the packages can potentially be used on Linux, but
# we can look in to that should the need ever arise.

# Glibc for a valid elf.h
get_elf: URL=$(GLIBC_URL)
get_elf: SERVER=$(GLIBC_SERVER)
get_elf: TARBALL=$(GLIBC_TAR)
get_elf: PKG=glibc
get_elf: VER=$(GLIBC_VERSION)
get_elf: SRC_DIR=$(GLIBC_SRC)
get_elf: prep_src_glibc
	echo "]0;Prepping glibc"

# LIBUSB Rules
%_libusb: URL=$(LIBUSB_URL)
%_libusb: SERVER=$(LIBUSB_SERVER)
%_libusb: TARBALL=$(LIBUSB_TAR)
%_libusb: PKG=libusb
%_libusb: VER=$(LIBUSB_VERSION)
%_libusb: SRC_DIR=$(LIBUSB_SRC)

.PHONY: install_libusb
install_libusb: prep_src_libusb
	echo "]0;Building libusb"
	$(MKDIR) $(LIBUSB_BUILD)
ifeq ($(DO_CONFIG),yes)
	cd $(LIBUSB_BUILD) ; \
	CFLAGS=-I$(GCC_REQS_DIR)/include  CPPFLAGS=-I$(GCC_REQS_DIR)/include  LDFLAGS=-L$(GCC_REQS_DIR)/lib $(SRC_DIR)/configure --host=$(HOST) --build=$(BUILD) --prefix=$(GCC_REQS_DIR) --disable-shared --enable-static
endif
ifeq ($(DO_BUILD),yes)
	$(MAKE) -C $(LIBUSB_BUILD)
	$(MAKE) -C $(LIBUSB_BUILD) install
endif

clean_libusb:
	! test -d $(SRC_DIR) || $(MAKE) -C $(LIBUSB_BUILD) clean

clean_source_libusb:
	rm -rf $(SRC_DIR)
