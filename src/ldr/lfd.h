/*
 * File: lfd.h
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
 * [L]DR File Descriptor Abstraction layer for handling different LDR formats.
 */

#ifndef __LDR_FORMAT_H__
#define __LDR_FORMAT_H__

#ifdef __LFD_INTERNAL

#include "dxes.h"
#include "ldr_elf.h"

struct lfd;
struct lfd_iovec;
struct lfd_target;

struct lfd_flag {
	uint16_t flag;
	const char *desc;
};

struct lfd_iovec {
	void*    (*read_ldr_header)   (struct lfd *alfd, size_t *header_size);
	void*    (*read_block_header) (struct lfd *alfd, bool *ignore, bool *fill, bool *final, size_t *header_len, size_t *data_len);
	bool     (*display_ldr)       (struct lfd *alfd);
	bool     (*display_dxe)       (struct lfd *alfd, const size_t dxe_idx);
	bool     (*write_ldr)         (struct lfd *alfd, const void *opts);
	bool     (*write_block)       (struct lfd *alfd, uint8_t dxe_flags, const void *opts, uint32_t addr, uint32_t count, void *src);
	uint32_t (*dump_block)        (BLOCK *block, FILE *fp, bool dump_fill);
};

struct lfd_target {
	const char *name;        /* unique short name */
	const char *description; /* description of target */
	const char * const *aliases;
	const bool uart_boot;

	struct lfd_iovec iovec;
	Elf32_Half em;           /* Elf machine architecture. */
	const bool dyn_sections; /* Whether or not this part accepts dynamic sections. */
};

typedef struct lfd {
	const struct lfd_target *target;
	LDR *ldr;

	char *dupped_mem;
	const char *filename;
	const char *selected_target;
	const char *selected_sirev;
	FILE *fp;
	bool is_open;
	struct stat st;
} LFD;

enum {
	DXE_BLOCK_FIRST = 0x01,
	DXE_BLOCK_INIT  = 0x02,
	DXE_BLOCK_JUMP  = 0x04,
	DXE_BLOCK_DATA  = 0x08,
	DXE_BLOCK_FILL  = 0x10,
	DXE_BLOCK_FINAL = 0x20,
};

void lfd_target_register(const struct lfd_target *target);
const struct lfd_target *lfd_target_find(const char *target);

#define target_is(alfd, target) (!strcasecmp(alfd->selected_target, target))

static inline bool family_is(LFD *alfd, const char *family)
{
	size_t i;
	const struct lfd_target *target = lfd_target_find(family);
	if (target == NULL)
		err("family '%s' is not supported", family);
	for (i = 0; target->aliases[i]; ++i)
		if (target_is(alfd, target->aliases[i]))
			return true;
	return false;
}

/**
 *	compute_hdrchk - compute 8bit XOR checksum of input
 */
static inline uint8_t compute_hdrchk(uint8_t *data, size_t len)
{
	size_t i;
	uint8_t ret = 0;
	for (i = 0; i < len; ++i)
		ret ^= data[i];
	return ret;
}

/* let the BF53x family share funcs for now */
bool bf53x_lfd_write_ldr(LFD *alfd, const void *void_opts);
void *bf53x_lfd_read_block_header(LFD *alfd, bool *ignore, bool *fill, bool *final, size_t *header_len, size_t *data_len);
bool bf53x_lfd_display_dxe(LFD *alfd, size_t d);
bool bf53x_lfd_write_block(LFD *alfd, uint8_t dxe_flags,
                           const void *void_opts, uint32_t addr,
                           uint32_t count, void *src);
uint32_t bf53x_lfd_dump_block(BLOCK *block, FILE *fp, bool dump_fill);

/* let the BF52x and BF54x family share funcs */
void *bf54x_lfd_read_block_header(LFD *alfd, bool *ignore, bool *fill, bool *final, size_t *header_len, size_t *data_len);
bool bf54x_lfd_display_dxe(LFD *alfd, size_t d);
bool bf54x_lfd_write_block(LFD *alfd, uint8_t dxe_flags,
                           const void *void_opts, uint32_t addr,
                           uint32_t count, void *src);
uint32_t bf54x_lfd_dump_block(BLOCK *block, FILE *fp, bool dump_fill);

/* Used to store a list of adi specific processors and their supported
 * silicon revisions.
 * The revisions string contains a list of supported silicon revisions
 * separated by leading and following spaces.
 * For example:
 *  " none any " or " none 0.1 any "
 * The macros field contains a list of space separated
 * compile-time macros.
 * If no value is provided, the macro is assumed to set a value of 1
 */
#define ADI_MAX_REVISIONS_LENGTH 256
struct adi_processors
{
  char *const name;
  char supportedRevisions[ADI_MAX_REVISIONS_LENGTH];
  int num_cores;
  char default_silicon_revision[ADI_MAX_REVISIONS_LENGTH];
};

#else

typedef struct lfd LFD;

#endif

void lfd_target_list(void);

LFD *lfd_malloc(const char *target, const char *sirev);
bool lfd_free(LFD *alfd);

bool lfd_open(LFD *alfd, const char *filename);
bool lfd_read(LFD *alfd);
bool lfd_display(LFD *alfd);
bool lfd_create(LFD *alfd, const void *opts);
bool lfd_dump(LFD *alfd, const void *opts);
bool lfd_load(LFD *alfd, const void *opts);
bool lfd_close(LFD *alfd);

#endif
