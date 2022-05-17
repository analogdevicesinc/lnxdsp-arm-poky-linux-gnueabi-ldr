/*
 * File: elf.h
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
 * Defines for internal ELF handling routines
 */

#ifndef __LDR_ELF_H__
#define __LDR_ELF_H__

#include "headers.h"

#ifndef EM_BLACKFIN
# define EM_BLACKFIN 106
#endif

/* only support 1 ELF at a time for now ... */
extern char do_reverse_endian;

typedef struct {
	void *ehdr;
	void *phdr;
	void *shdr;
	char *data, *data_end;
	char elf_class;
	off_t len;
	int fd;
	const char *filename;
} elfobj;

#define EGET(X) \
	(__extension__ ({ \
		uint32_t __res; \
		if (!do_reverse_endian) {    __res = (X); \
		} else if (sizeof(X) == 1) { __res = (X); \
		} else if (sizeof(X) == 2) { __res = bswap_16((X)); \
		} else if (sizeof(X) == 4) { __res = bswap_32((X)); \
		} else if (sizeof(X) == 8) { printf("64bit types not supported\n"); exit(1); \
		} else { printf("Unknown type size %i\n", (int)sizeof(X)); exit(1); } \
		__res; \
	}))

#define EHDR32(ptr) ((Elf32_Ehdr *)(ptr))
#define EHDR64(ptr) ((Elf64_Ehdr *)(ptr))
#define PHDR32(ptr) ((Elf32_Phdr *)(ptr))
#define PHDR64(ptr) ((Elf64_Phdr *)(ptr))
#define SHDR32(ptr) ((Elf32_Shdr *)(ptr))
#define SHDR64(ptr) ((Elf64_Shdr *)(ptr))
#define RELA32(ptr) ((Elf32_Rela *)(ptr))
#define RELA64(ptr) ((Elf64_Rela *)(ptr))
#define REL32(ptr) ((Elf32_Rel *)(ptr))
#define REL64(ptr) ((Elf64_Rel *)(ptr))
#define DYN32(ptr) ((Elf32_Dyn *)(ptr))
#define DYN64(ptr) ((Elf64_Dyn *)(ptr))
#define SYM32(ptr) ((Elf32_Sym *)(ptr))
#define SYM64(ptr) ((Elf64_Sym *)(ptr))

#define ELF_GET_EHDR_FIELD(elf, field) \
  (elf->elf_class == ELFCLASS32 \
   ? EGET(EHDR32(elf->ehdr)->field) \
   : EGET(EHDR64(elf->ehdr)->field))

#define ELF_GET_SHDR(elf, index) \
  (elf->elf_class == ELFCLASS32 \
   ? (void *)(SHDR32(elf->shdr) + (index)) \
   : (void *)(SHDR64(elf->shdr) + (index)))

#define ELF_GET_SHDR_FIELD(elf, shdr, field) \
  (elf->elf_class == ELFCLASS32 \
   ? EGET(SHDR32(shdr)->field) \
   : EGET(SHDR64(shdr)->field))

#define ELF_GET_PHDR(elf, index) \
  (elf->elf_class == ELFCLASS32 \
   ? (void *)(PHDR32(elf->phdr) + (index)) \
   : (void *)(PHDR64(elf->phdr) + (index)))

#define ELF_GET_PHDR_FIELD(elf, phdr, field) \
  (elf->elf_class == ELFCLASS32 \
   ? EGET(PHDR32(phdr)->field) \
   : EGET(PHDR64(phdr)->field))

#define ELF_GET_SYM(elf, symtab, index) \
  (elf->elf_class == ELFCLASS32 \
   ? (void *)(SYM32(symtab) + (index)) \
   : (void *)(SYM64(symtab) + (index)))

#define ELF_GET_SYM_FIELD(elf, sym, field) \
  (elf->elf_class == ELFCLASS32 \
   ? EGET(SYM32(sym)->field) \
   : EGET(SYM64(sym)->field))

extern elfobj *elf_open(const char *filename, Elf32_Half emach);
extern void elf_close(elfobj *elf);
extern void *elf_lookup_section(const elfobj *elf, const char *name);
extern void *elf_lookup_symbol(const elfobj *elf, const char *found_sym);

#endif
