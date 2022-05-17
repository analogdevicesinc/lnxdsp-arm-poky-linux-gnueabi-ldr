/*
 * File: dxe_jump.h
 *
 * Copyright (c) 2006-2014, Analog Devices, Inc.  All rights reserved.

 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted (subject to the limitations in the
 * disclaimer below) provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 * * Neither the name of Analog Devices, Inc.  nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
 * GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
 * HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Description:
 * Binary code for doing a "jump <address>"
 */

#ifndef __DXE_JUMP__
#define __DXE_JUMP__

#include "blackfin_defines.h"

/* for debugging purposes:
 * $ bfin-uclinux-gcc -x assembler-with-cpp -c dxe_jump.h -o dxe_jump.o
 * $ bfin-uclinux-objdump -d dxe_jump.o
 * $ bfin-uclinux-objcopy -I elf32-bfin -O binary dxe_jump.o dxe_jump.bin
 *
 * $ bfin-uclinux-gcc -x assembler-with-cpp -S -o - dxe_jump.h
 */
# ifdef __ASSEMBLER__

	P0.L = LO(ADDRESS);
	P0.H = HI(ADDRESS);
	jump (P0);

# else

#define DXE_JUMP_CODE_SIZE 12
static inline uint8_t *dxe_jump_code(const uint32_t address)
{
	static uint8_t jump_buf[DXE_JUMP_CODE_SIZE] = {
		[0] 0x08, [1] 0xE1, [2] 0xFF, [3] 0xFF, /* P0.L = LO(address); */
		[4] 0x48, [5] 0xE1, [6] 0xFF, [7] 0xFF, /* P0.H = HI(address); */
		[8] 0x50, [9] 0x00,                     /* jump (P0); */
		    0x00,     0x00                      /* nop; (pad to align to 32bits) */
	};

	FILL_ADDR_32(jump_buf, address, 2, 3, 6, 7);

	return jump_buf;
}

# endif

#endif
