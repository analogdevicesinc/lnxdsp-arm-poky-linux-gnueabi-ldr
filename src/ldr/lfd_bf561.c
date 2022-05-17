/*
 * File: lfd_bf561.c
 *
 * Copyright (c) 2006-2021, Analog Devices, Inc.  All rights reserved.

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
 * Format handlers for LDR files on the BF561.
 */

#define __LFD_INTERNAL
#include "ldr.h"

/* flags for 4 byte global header; VDSP 4.0 Loader Manual page 2-39
 *   1   0   1   0   0   0   0   0 <- first byte should be 0xA0
 *||              ||              ||              ||              ||
 * [31  30  29  28][27  26  25  24  23  22  21  20  19  18  17  16]
 *   signature                        reserved
 *||              ||              ||              ||              ||
 * [15  14  13  12  11][10   9   8][ 7   6][ 5][ 4   3   2   1][ 0]
 *      reserved         spi baud   hold t   x    wait time       16bit
 */
#define LDR_FLAG_16BIT_FLASH   0x00000001
#define LDR_FLAG_WAIT_MASK     0x0000001E
#define LDR_FLAG_WAIT_SHIFT    1
#define LDR_FLAG_HOLD_MASK     0x000000C0
#define LDR_FLAG_HOLD_SHIFT    6
#define LDR_FLAG_SPI_MASK      0x00000700
#define LDR_FLAG_SPI_SHIFT     8
#define LDR_FLAG_SPI_500K      0x0
#define LDR_FLAG_SPI_1M        0x1
#define LDR_FLAG_SPI_2M        0x2
#define LDR_FLAG_SIGN_MASK     0xFF000000
#define LDR_FLAG_SIGN_SHIFT    28
#define LDR_FLAG_SIGN_MAGIC    0xA

/*
 * bf561_lfd_read()
 * Translate the ADI visual dsp ldr binary format into our ldr structure.
 *
 * The BF561 format is just like the BF537 except it has a 4 byte global header.
 */
static void *bf561_lfd_read_ldr_header(LFD *alfd, size_t *header_size)
{
	uint32_t *header;
	*header_size = 4;
	header = xmalloc(*header_size);
	if (fread(header, *header_size, 1, alfd->fp) != 1)
		return NULL;
	ldr_make_little_endian_32(*header);
	return header;
}

static bool bf561_lfd_display_ldr(LFD *alfd)
{
	LDR *ldr = alfd->ldr;
	uint32_t header = *((uint32_t*)ldr->header);

	printf("  LDR header: %08X ( %s-bit-flash wait:%i hold:%i ", header,
		(header & LDR_FLAG_16BIT_FLASH ? "16" : "8"),
		(header & LDR_FLAG_WAIT_MASK) >> LDR_FLAG_WAIT_SHIFT,
		(header & LDR_FLAG_HOLD_MASK) >> LDR_FLAG_HOLD_SHIFT);

	switch ((header & LDR_FLAG_SPI_MASK) >> LDR_FLAG_SPI_SHIFT) {
		case LDR_FLAG_SPI_500K: printf("spi:500K "); break;
		case LDR_FLAG_SPI_1M:   printf("spi:1M ");   break;
		case LDR_FLAG_SPI_2M:   printf("spi:2M ");   break;
		default:                printf("spi:?? ");   break;
	}

	if ((header & LDR_FLAG_SIGN_MASK) >> LDR_FLAG_SIGN_SHIFT != LDR_FLAG_SIGN_MAGIC)
		printf("!!hdrsign!! ");

	printf(")\n");

	return true;
}

static bool bf561_lfd_write_ldr(LFD *alfd, const void *void_opts)
{
	const struct ldr_create_options *opts = void_opts;
	uint32_t header = \
		(LDR_FLAG_SIGN_MAGIC << LDR_FLAG_SIGN_SHIFT) | \
		(opts->wait_states << LDR_FLAG_WAIT_SHIFT) | \
		(opts->flash_holdtimes << LDR_FLAG_HOLD_SHIFT);
	if (opts->flash_bits == 16)
		header |= LDR_FLAG_16BIT_FLASH;
	switch (opts->spi_baud) {
		case  500: header |= (LDR_FLAG_SPI_500K << LDR_FLAG_SPI_SHIFT); break;
		case 1000: header |= (LDR_FLAG_SPI_1M << LDR_FLAG_SPI_SHIFT);   break;
		case 2000: header |= (LDR_FLAG_SPI_2M << LDR_FLAG_SPI_SHIFT);   break;
	}
	ldr_make_little_endian_32(header);
	return (fwrite(&header, sizeof(header), 1, alfd->fp) == 1 ? true : false);
}

static const char * const bf561_aliases[] = { "BF561", NULL };
static const struct lfd_target bf561_lfd_target = {
	.name = "BF561",
	.description = "Blackfin LDR handler for BF561",
	.aliases = bf561_aliases,
	.uart_boot = false,
	.iovec = {
		.read_ldr_header = bf561_lfd_read_ldr_header,
		.read_block_header = bf53x_lfd_read_block_header,
		.display_ldr = bf561_lfd_display_ldr,
		.display_dxe = bf53x_lfd_display_dxe,
		.write_ldr = bf561_lfd_write_ldr,
		.write_block = bf53x_lfd_write_block,
		.dump_block = bf53x_lfd_dump_block,
	},
	.em = EM_BLACKFIN,
	.dyn_sections = false,
};

__attribute__((constructor))
static void bf561_lfd_target_register(void)
{
	lfd_target_register(&bf561_lfd_target);
}
