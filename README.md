# Analog Devices loader tool for ADSP-SCxxx devices

This repository contains the source code and build scripts for generating the loader tool used to create LDR files.
LDR files are the executable format for the ADSP-SCxxx on-chip Boot ROM.  We need to handle this format for initial booting of the processor (so boot loaders or bare metal applications).

To put it simply, LDRs are just a container format for DXEs (which are just a fancy name for programs in the Blackfin binary object code format).  A single LDR is made up of an arbitrary number of DXEs and a single DXE is made up of an arbitrary number of blocks (each block contains starting address and some flags).

## Getting Started

* To build the Linux-hosted bare metal toolchain:
    make install_arm_none_eabi_toolchain_release

* To build the Windows-hosted bare metal toolchain:
    make install_arm_none_eabi_toolchain_release BUILD_WINDOWS_CROSS=yes

* To build the Linux-hosted Linux-targeting toolchain:
  You will need to ensure that the kernel sources that you use can be
  downloaded into the gnu-arm/src directory in order for the toolchain to build

    make install_arm_linux_gnueabi_toolchain_release

* Building the Linux-targeting toolchain on Windows is not supported.

## License
See the [LICENSE](./LICENSE) file for details.
