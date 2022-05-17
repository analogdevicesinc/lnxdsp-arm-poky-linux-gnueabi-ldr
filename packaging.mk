#!/bin/bash
#      Copyright (c) 2014-2022, Analog Devices, Inc.  All rights reserved.
#      
#      Redistribution and use in source and binary forms, with or without
#      modification, are permitted (subject to the limitations in the
#      disclaimer below) provided that the following conditions are met:
#      
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the
#        distribution.
#      
#      * Neither the name of Analog Devices, Inc.  nor the names of its
#        contributors may be used to endorse or promote products derived
#        from this software without specific prior written permission.
#      
#      NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
#      GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
#      HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
#      WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#      MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#      DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#      CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#      SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#      BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#      WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#      OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#      IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Script to package up all sources used in the production of the
# Analog Devices GNU ARM Toolchain.
# This script creates an archive containing all sources and build scripts
# used in the production of the toolchain as required by the GNU Public
# License.
# Tar balls will be archived off and preserved according to the lifetime 
# mentioned in the GPL - 25 years.
# Analog Devices is obliged to provide the sources for a given release of
# the GNU ARM Toolchain to any owner of the binaries as provided by Analog
# Devices.

TOOLZIP_archiveFile=gnu_arm_archive

TOOLZIP_makefilesToArchive= \
	Makefile \
	adi_include.mk \
	arm-none-eabi-source.mk \
	aarch64-none-elf-source.mk \
	ldr.mk \
	packaging.mk \
	source_config.mk \
	README.BUILDING

TOOLZIP_sourcesToArchive= \
	src/proc-defs \
	src/adi_includes \
	src/support_files \
	src/binutils \
	src/cloog-$(CLOOG_VERSION) \
	src/expat-$(EXPAT_VERSION) \
	src/gcc \
	src/gdb-$(GDB_VERSION) \
	src/gmp-$(GMP_VERSION) \
	src/isl-$(ISL_VERSION) \
	src/mpc-$(MPC_VERSION) \
	src/mpfr-$(MPFR_VERSION) \
	src/newlib \
	--exclude src/gcc/newlib \
	--exclude src/gcc/libgloss

TOOLZIP_scriptsToArchive= \
	scripts/apt_check.php \
	scripts/auto_gen_header \
	scripts/clear_bsd.txt \
	scripts/generate_adi_part_files.php \
	scripts/install_packages_ubuntu.sh \
	scripts/licenser.sh \
	scripts/patcher \
	scripts/update_gcc_specs.sh \
	scripts/adi_parts_config/CCES

# Items to archive:
# Specific sources, patches, top level Makefiles, specific scripts

create_toolchain_archive:
	@echo "Creating Toolchain archive"
	rm -f $(TOOLZIP_archiveFile).tar $(TOOLZIP_archiveFile).tar.gz
	tar czf $(TOOLZIP_archiveFile).tar.gz $(TOOLZIP_makefilesToArchive) \
		$(TOOLZIP_sourcesToArchive) $(TOOLZIP_scriptsToArchive)
