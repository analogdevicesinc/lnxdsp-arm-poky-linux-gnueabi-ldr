# Analog Devices loader tool for ADSP-SCxxx devices

This repository contains the source code and build scripts for generating the loader tool used to create LDR files.
LDR files are the executable format for the ADSP-SCxxx on-chip Boot ROM.  We need to handle this format for initial booting of the processor (so boot loaders or bare metal applications).

To put it simply, LDRs are just a container format for DXEs (which are just a fancy name for programs in the Blackfin binary object code format).  A single LDR is made up of an arbitrary number of DXEs and a single DXE is made up of an arbitrary number of blocks (each block contains starting address and some flags).

## Getting Started

To build and install the Linux-hosted bare metal toolchain:  
    cd src/ldr  
    ./configure  
    make  
    make install  

See the [INSTALL](./src/ldr/INSTALL) file for additional details.

## License
See the [LICENSE](./LICENSE) file for details.
