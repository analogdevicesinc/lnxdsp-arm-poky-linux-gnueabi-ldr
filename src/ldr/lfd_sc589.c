/*
 * File: lfd_sc589.c
 *
 * Copyright (c) 2006-2022, Analog Devices, Inc.  All rights reserved.

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
 * Format handlers for ADSP-SC5xx LDR files.
 */

#define __LFD_INTERNAL
#include "ldr.h"

/* TODO: update ref 16-byte block header; See page 19-13 of SC589 HRM */
#define LDR_BLOCK_HEADER_LEN (16)
typedef struct {
	uint8_t raw[LDR_BLOCK_HEADER_LEN];        /* buffer for following members ... needs to be first */
	uint32_t block_code;                      /* flags to control behavior */
	uint32_t target_address;                  /* arm memory address to load block */
	uint32_t byte_count;                      /* number of bytes in block */
	uint32_t argument;                        /* misc extraneous data (like CRC) */
} BLOCK_HEADER;

/* block flags */
#define BFLAG_BCODE             0x0000000F
#define BFLAG_SAFE              0x00000010
#define BFLAG_AUX               0x00000020
#define BFLAG_FORWARD           0x00000080
#define BFLAG_FILL              0x00000100
#define BFLAG_QUICKBOOT         0x00000200
#define BFLAG_CALLBACK          0x00000400
#define BFLAG_INIT              0x00000800
#define BFLAG_IGNORE            0x00001000
#define BFLAG_INDIRECT          0x00002000
#define BFLAG_FIRST             0x00004000
#define BFLAG_FINAL             0x00008000
#define BFLAG_HDRCHK_MASK       0x00FF0000
#define BFLAG_HDRCHK_SHIFT      16
#define BFLAG_HDRSIGN_MASK      0xFF000000
#define BFLAG_HDRSIGN_SHIFT     24
#define BFLAG_HDRSIGN_MAGIC(X)  ({ \
									int ret; \
									switch (X) { \
										case 0: ret = 0xAD; break; \
										case 1: ret = 0xAC; break; \
										case 2: ret = 0xAB; break; \
										case 3: ret = 0xAA; break; \
										default: ret = 0xAD; break; \
									} \
									ret; \
								})
#define BFLAG_HDRSIGN_MAGIC_DECODE(X) ({ \
									int ret; \
									switch (X) { \
										case 0xAD: ret = 0; break; \
										case 0xAC: ret = 1; break; \
										case 0xAB: ret = 2; break; \
										case 0xAA: ret = 3; break; \
										default: ret = -1; break; \
									} \
									ret; \
								})

static const struct lfd_flag sc5xx_lfd_flags[] = {
	{ BFLAG_SAFE,        "safe"      },
	{ BFLAG_AUX,         "aux"       },
	{ BFLAG_FORWARD,     "forward"   },
	{ BFLAG_FILL,        "fill"      },
	{ BFLAG_QUICKBOOT,   "quickboot" },
	{ BFLAG_CALLBACK,    "callback"  },
	{ BFLAG_INIT,        "init"      },
	{ BFLAG_IGNORE,      "ignore"    },
	{ BFLAG_INDIRECT,    "indirect"  },
	{ BFLAG_FIRST,       "first"     },
	{ BFLAG_FINAL,       "final"     },
	{ 0, 0 }
};

/**
 *	sc5xx_lfd_read_block_header - read in the SC5xx block header
 *
 * The format of each block header:
 * [4 bytes for block codes]
 * [4 bytes for address]
 * [4 bytes for byte count]
 * [4 bytes for arguments]
 */
void *sc5xx_lfd_read_block_header(LFD *alfd, bool *ignore, bool *fill, bool *final, size_t *header_len, size_t *data_len)
{
	FILE *fp = alfd->fp;
	BLOCK_HEADER *header = xmalloc(sizeof(*header));
	if (fread(header->raw, 1, LDR_BLOCK_HEADER_LEN, fp) != LDR_BLOCK_HEADER_LEN)
		return NULL;
	memcpy(&(header->block_code), header->raw, sizeof(header->block_code));
	memcpy(&(header->target_address), header->raw+4, sizeof(header->target_address));
	memcpy(&(header->byte_count), header->raw+8, sizeof(header->byte_count));
	memcpy(&(header->argument), header->raw+12, sizeof(header->argument));
	ldr_make_little_endian_32(header->block_code);
	ldr_make_little_endian_32(header->target_address);
	ldr_make_little_endian_32(header->byte_count);
	ldr_make_little_endian_32(header->argument);
	*ignore = !!(header->block_code & BFLAG_IGNORE);
	*fill = !!(header->block_code & BFLAG_FILL);
	*final = !!(header->block_code & BFLAG_FINAL);
	*header_len = LDR_BLOCK_HEADER_LEN;
	*data_len = header->byte_count;
	return header;
}

bool sc5xx_lfd_display_dxe(LFD *alfd, size_t d)
{
	LDR *ldr = alfd->ldr;
	size_t i, b;
	uint32_t block_code;
	int32_t tmp;

	if (quiet)
		printf("              Offset      BlockCode  Address    Bytes      Argument\n");
	for (b = 0; b < ldr->dxes[d].num_blocks; ++b) {
		BLOCK *block = &(ldr->dxes[d].blocks[b]);
		BLOCK_HEADER *header = block->header;
		if (quiet)
			printf("    Block %2zu 0x%08zX: ", b+1, block->offset);
		else
			printf("    Block %2zu at 0x%08zX\n", b+1, block->offset);

		if (quiet) {
			printf("0x%08X 0x%08X 0x%08X 0x%08X ( ", header->block_code, header->target_address, header->byte_count, header->argument);
		} else if (verbose) {
			printf("\t\tTarget Address: 0x%08X ( %s )\n", header->target_address,
				(header->target_address > 0x80000000 ? "DDR" : "L2"));
			printf("\t\t    Block Code: 0x%08X\n", header->block_code);
			printf("\t\t    Byte Count: 0x%08X ( %u bytes )\n", header->byte_count, header->byte_count);
			printf("\t\t      Argument: 0x%08X ( ", header->argument);
		} else {
			printf("         Addr: 0x%08X BCode: 0x%08X Bytes: 0x%08X Args: 0x%08X ( ",
				header->target_address, header->block_code, header->byte_count, header->argument);
		}

		block_code = header->block_code;

		/* address and byte count need to be 4 byte aligned, although
		   ignore the LSB (mode-bit). */
		if (((header->target_address>>1)<<1) % 4)
			printf("!!addralgn!! ");
		if (header->byte_count % 4)
			printf("!!cntalgn!! ");

		/* hdrsign should always be set to 0xAD */
		tmp = (header->block_code & BFLAG_HDRSIGN_MASK) >> BFLAG_HDRSIGN_SHIFT;
		tmp = BFLAG_HDRSIGN_MAGIC_DECODE(tmp);
		if (tmp == -1)
			printf("!!hdrsign!! ");
		else
			printf("Core%d ", tmp);

		/* hdrchk is a simple XOR of the block header.
		 * Since the XOR value exists inside of the block header, the XOR
		 * checksum of the actual block should always come out to be 0x00.
		 * This is because the XOR byte is 0x00 when first computed, but
		 * when added to the actual data, the result cancels out the input.
		 */
		tmp = (header->block_code & BFLAG_HDRCHK_MASK) >> BFLAG_HDRCHK_SHIFT;
		if (compute_hdrchk(header->raw, LDR_BLOCK_HEADER_LEN))
			printf("!!hdrchk!! ");

		tmp = block_code & BFLAG_BCODE;
		switch (tmp) {
			case  0: break;
			default: printf("non-zero-bcode "); break;
		}

		for (i = 0; sc5xx_lfd_flags[i].desc; ++i)
			if (block_code & sc5xx_lfd_flags[i].flag)
				printf("%s ", sc5xx_lfd_flags[i].desc);

		printf(")\n");
	}

	return true;
}

/*
 * ldr_create()
 *
 * XXX: no way for user to set "argument" or block_code fields ...
 */
static bool _sc5xx_lfd_write_header(FILE *fp, uint32_t block_code, uint32_t addr,
                                    uint32_t count, uint32_t argument)
{
	uint8_t header[LDR_BLOCK_HEADER_LEN];

	uint8_t pad_size = count % 4;
	if (((addr>>1)<<1) % 4)
		warn("address is not 4 byte aligned (0x%X %% 4 = %i)", addr, addr % 4);
	if (pad_size) {
		warn("count is not 4 byte aligned (0x%X %% 4 = %i)", count, pad_size);
		warn("going to pad the end with zeros, but you should fix this");
		count += (4 - pad_size);
	}

	ldr_make_little_endian_32(block_code);
	ldr_make_little_endian_32(addr);
	ldr_make_little_endian_32(count);
	ldr_make_little_endian_32(argument);
	memcpy(header+ 0, &block_code, sizeof(block_code));
	memcpy(header+ 4, &addr, sizeof(addr));
	memcpy(header+ 8, &count, sizeof(count));
	memcpy(header+12, &argument, sizeof(argument));
	ldr_make_little_endian_32(block_code);
	block_code |= (compute_hdrchk(header, LDR_BLOCK_HEADER_LEN) << BFLAG_HDRCHK_SHIFT);
	ldr_make_little_endian_32(block_code);
	memcpy(header+ 0, &block_code, sizeof(block_code));
	return (fwrite(header, sizeof(uint8_t), LDR_BLOCK_HEADER_LEN, fp) == LDR_BLOCK_HEADER_LEN ? true : false);
}
static uint32_t last_dxe_pos = 0;

/*
 *	At the end of each application we need to update the first block to point
 *	to the byte after the end of the application.  This is either done when
 *	we're adding a new FIRST block or when we're putting the FINAL block on
 *	the end.
 */
static bool sc5xx_lfd_update_first_block(FILE *fp, uint32_t block_code_base){
	uint32_t block_code, argument, addr;
	bool ret = true;
	argument = ftell(fp);
	fseek(fp, (last_dxe_pos+4), SEEK_SET);
	ret &= (fread(&addr, sizeof(addr), 1, fp) == 1 ? true : false);
	ldr_make_little_endian_32(addr);
	fseek(fp, last_dxe_pos, SEEK_SET);
	block_code = block_code_base | BFLAG_IGNORE | BFLAG_FIRST;
	ret &= _sc5xx_lfd_write_header(fp, block_code, addr, 0, argument);
	fseek(fp, 0, SEEK_END);
	return ret;
}

bool sc5xx_lfd_write_block(struct lfd *alfd, uint8_t dxe_flags,
                                  const void *void_opts, uint32_t addr,
                                  uint32_t count, void *src)
{
	const struct ldr_create_options *opts = void_opts;
	FILE *fp = alfd->fp;
	uint32_t block_code_base, block_code, argument;
	bool ret = true;

	argument = 0xDEADBEEF;
	block_code_base = \
		(BFLAG_HDRSIGN_MAGIC(opts->cur_core) << BFLAG_HDRSIGN_SHIFT) \
		| opts->bcode;

	block_code = block_code_base;

	if ((dxe_flags & DXE_BLOCK_FIRST)) {
		block_code |= BFLAG_IGNORE | BFLAG_FIRST;
		if (ftell(fp))
			ret &= sc5xx_lfd_update_first_block(fp, block_code_base);
		last_dxe_pos = ftell(fp);
	}
	if (dxe_flags & DXE_BLOCK_INIT) {
		if (!count)
			block_code |= BFLAG_INIT;
	}
	if (dxe_flags & DXE_BLOCK_FINAL) {
		block_code |= BFLAG_FINAL;
		argument = 0;
	}
	if (dxe_flags & DXE_BLOCK_JUMP) {
		/* We don't require a jump block for ARM. */
		return true;
	}
	if (dxe_flags & DXE_BLOCK_FILL && opts->fill_blocks) {
		block_code |= BFLAG_FILL;
		argument = 0;
	}

	/* Punch a hole in the middle of this block if requested.
	 * This means the block we're punching just got split ... so if
	 * you're punching a hole in a block that by nature shouldn't be
	 * split, we'll just error out rather than trying to figure out
	 * how exactly to safely split it.  Also might be worth noting
	 * that while in master boot modes the address of the ignore
	 * block is irrelevant, in slave boot modes we need to actually
	 * read in the ignore data and put it somewhere, so we need to
	 * assume address 0 is suitable for this.
	 */
	if (opts->hole.offset) {
		size_t off = ftello(fp);
		uint32_t disk_count = (src ? count : 0);
		if (opts->hole.offset > off && opts->hole.offset < off + LDR_BLOCK_HEADER_LEN + disk_count) {
			uint32_t hole_count = opts->hole.length;

			if (dxe_flags & DXE_BLOCK_INIT)
				err("Punching holes in init blocks is not supported");

			/* fill up what we can to the punched location */
			ssize_t ssplit_count = opts->hole.offset - off - LDR_BLOCK_HEADER_LEN * 2;
			if (ssplit_count < LDR_BLOCK_HEADER_LEN) {
				/* leading hole is wicked small, so just expand the ignore block a bit */
				if (opts->hole.offset - off < LDR_BLOCK_HEADER_LEN)
					err("Unable to punch a hole soon enough");
				else
					hole_count += (opts->hole.offset - off - LDR_BLOCK_HEADER_LEN);
			} else if (src) {
				/* squeeze out a little of this block first */
				uint32_t split_count = ssplit_count;
				ret &= _sc5xx_lfd_write_header(fp, block_code, addr, split_count, argument);
				ret &= (fwrite(src, 1, split_count, fp) == split_count ? true : false);
				src += split_count;
				addr += split_count;
				count -= split_count;
			} else
				err("Punching holes with fill blocks?");

			/* finally write out hole */
			ret &= _sc5xx_lfd_write_header(fp, block_code | BFLAG_IGNORE, 0, hole_count, 0xBAADF00D);
			if (opts->hole.filler_file) {
				FILE *filler_fp = fopen(opts->hole.filler_file, "rb");
				if (filler_fp) {
					size_t bytes, filled = 0;
					uint8_t filler_buf[8192];	/* random size */
					while (!feof(filler_fp)) {
						bytes = fread(filler_buf, 1, sizeof(filler_buf), filler_fp);
						filled += bytes;
						ret &= (fwrite(filler_buf, 1, bytes, fp) == bytes ? true : false);
					}
					if (ferror(filler_fp))
						ret &= false;
					if (filled > hole_count)
						err("filler file was bigger than the requested hole size");
					if (filled < hole_count)
						fseeko(fp, hole_count - filled, SEEK_CUR);
				} else
					ret &= false;
			} else
				fseeko(fp, hole_count, SEEK_CUR);
		}
	}

	ret &= _sc5xx_lfd_write_header(fp, block_code, addr, count, argument);
	if (src)
		ret &= (fwrite(src, 1, count, fp) == count ? true : false);
	else if (dxe_flags & DXE_BLOCK_FILL && !opts->fill_blocks)
		ret &= fseek(fp, count, SEEK_CUR);
	if (count % 4) /* skip a few trailing bytes */
		fseek(fp, 4 - (count % 4), SEEK_CUR);

	if (dxe_flags & DXE_BLOCK_FINAL) {
		/* we need to set the argument in the first block header to point here*/
		ret &= sc5xx_lfd_update_first_block(fp, block_code_base);
	}

	return ret;
}

uint32_t sc5xx_lfd_dump_block(BLOCK *block, FILE *fp, bool dump_fill)
{
	BLOCK_HEADER *header = block->header;
	uint32_t wrote;

	if (!(header->block_code & BFLAG_FILL))
		wrote = fwrite(block->data, 1, header->byte_count, fp);
	else if (dump_fill) {
		/* cant use memset() here as it's a 32bit fill, not 8bit */
		void *filler;
		uint32_t *p = filler = xmalloc(header->byte_count);
		while ((void*)p < (void*)(filler + header->byte_count))
			*p++ = header->argument;
		wrote = fwrite(filler, 1, header->byte_count, fp);
		free(filler);
	} else
		wrote = header->byte_count;

	if (wrote != header->byte_count)
		warnf("unable to write out");

	return header->target_address;
}

static const char * const sc589_aliases[] = {
	"SC570", "SC571", "SC572", "SC573",
	"SC582", "SC583", "SC584", "SC587",
	"SC591", "SC591W", "SC592", "SC592W", "SC593W", "SC594", "SC594W",
	NULL
};
static const struct lfd_target sc589_lfd_target = {
	.name  = "SC589",
	.description = "ARM LDR handler for SC5xx",
	.aliases = sc589_aliases,
	.uart_boot = true,
	.iovec = {
		.read_block_header = sc5xx_lfd_read_block_header,
		.display_dxe = sc5xx_lfd_display_dxe,
		.write_block = sc5xx_lfd_write_block,
		.dump_block = sc5xx_lfd_dump_block,
	},
	.em = EM_ARM,
	.dyn_sections = true,
};

static const char * const sc598_aliases[] = {
	"SC595", "SC595W", "SC596", "SC596W", "SC598W",
	NULL
};
static const struct lfd_target sc598_lfd_target = {
	.name  = "SC598",
	.description = "AArch64 LDR handler for SC59x",
	.aliases = sc598_aliases,
	.uart_boot = true,
	.iovec = {
		.read_block_header = sc5xx_lfd_read_block_header,
		.display_dxe = sc5xx_lfd_display_dxe,
		.write_block = sc5xx_lfd_write_block,
		.dump_block = sc5xx_lfd_dump_block,
	},
	.em = EM_AARCH64,
	.dyn_sections = true,
};

__attribute__((constructor))
static void sc5xx_lfd_target_register(void)
{
	lfd_target_register(&sc589_lfd_target);
	lfd_target_register(&sc598_lfd_target);
}
