/*
 * File: elf.c
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
 * Abstract away ELF details here
 *
 * TODO: this only handles 32bit ELFs
 * TODO: this only handles 1 ELF at a time (do_reverse_endian is per-process, not per-elf)
 */

#include "headers.h"
#include "helpers.h"
#include "ldr_elf.h"

#ifndef HAVE_MMAP
#define PROT_READ 0x1
#define MAP_SHARED 0x001
#define MAP_FAILED ((void *) -1)
static void *mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset)
{
	void *ret = xmalloc(length);

	assert(start == 0);
	assert(prot == PROT_READ);

	if (read_retry(fd, ret, length) != length) {
		free(ret);
		ret = MAP_FAILED;
	}

	return ret;
}
static int munmap(void *start, size_t length)
{
	free(start);
	return 0;
}
#endif

char do_reverse_endian;

/* valid elf buffer check */
#define IS_ELF_BUFFER(buff) \
	(buff[EI_MAG0] == ELFMAG0 && \
	 buff[EI_MAG1] == ELFMAG1 && \
	 buff[EI_MAG2] == ELFMAG2 && \
	 buff[EI_MAG3] == ELFMAG3)
/* for now, only handle little endian as it
 * simplifies the input code greatly */
#define DO_WE_LIKE_ELF(buff) \
	((buff[EI_CLASS] == ELFCLASS32 || buff[EI_CLASS] == ELFCLASS64) && \
	 (buff[EI_DATA] == ELFDATA2LSB /*|| buff[EI_DATA] == ELFDATA2MSB*/) && \
	 (buff[EI_VERSION] == EV_CURRENT))

elfobj *elf_open(const char *filename, Elf32_Half emach)
{
	elfobj *elf;
	struct stat st;

	elf = xmalloc(sizeof(*elf));

	elf->fd = open(filename, O_RDONLY | O_BINARY);
	if (elf->fd < 0)
		goto err_free;

	if (fstat(elf->fd, &st) == -1 || st.st_size < EI_NIDENT)
		goto err_close;
	elf->len = st.st_size;

	elf->data = mmap(0, elf->len, PROT_READ, MAP_SHARED, elf->fd, 0);
	if (elf->data == MAP_FAILED)
		goto err_close;
	elf->data_end = elf->data + elf->len;

	if (!IS_ELF_BUFFER(elf->data) || !DO_WE_LIKE_ELF(elf->data))
		goto err_munmap;

	elf->filename = filename;
	elf->elf_class = elf->data[EI_CLASS];
	do_reverse_endian = (ELF_DATA != elf->data[EI_DATA]);
	elf->ehdr = (void*)elf->data;

	/* lookup the program and section header tables */
	{
		if (ELF_GET_EHDR_FIELD(elf, e_machine) != emach)
			goto err_munmap;

		if (ELF_GET_EHDR_FIELD(elf, e_phnum) <= 0)
			elf->phdr = NULL;
		else
			elf->phdr = elf->data + ELF_GET_EHDR_FIELD(elf, e_phoff);
		if (ELF_GET_EHDR_FIELD(elf,e_shnum) <= 0)
			elf->shdr = NULL;
		else
			elf->shdr = elf->data + ELF_GET_EHDR_FIELD(elf, e_shoff);
	}

	return elf;

 err_munmap:
	munmap(elf->data, elf->len);
 err_close:
	close(elf->fd);
 err_free:
	free(elf);
	return NULL;
}

void elf_close(elfobj *elf)
{
	munmap(elf->data, elf->len);
	close(elf->fd);
	free(elf);
	return;
}

void *elf_lookup_section(const elfobj *elf, const char *name)
{
	unsigned int i;
	uint16_t shstrndx = ELF_GET_EHDR_FIELD(elf, e_shstrndx);
	uint16_t shnum = ELF_GET_EHDR_FIELD(elf, e_shnum);

	if (elf->shdr == NULL || shstrndx >= shnum)
		return NULL;

	void *strtab = ELF_GET_SHDR(elf, shstrndx);

	for (i = 0; i < shnum; ++i) {
		void *shdr = ELF_GET_SHDR(elf, i);
		Elf64_Off offset =
			ELF_GET_SHDR_FIELD(elf, strtab, sh_offset) +
			ELF_GET_SHDR_FIELD(elf, shdr, sh_name);
		const char *shdr_name = elf->data + offset;
		if (!strcmp(shdr_name, name))
			return shdr;
	}

	return NULL;
}

void *elf_lookup_symbol(const elfobj *elf, const char *found_sym)
{
	unsigned long i;
	void *symscn = elf_lookup_section(elf, ".symtab");
	void *strscn = elf_lookup_section(elf, ".strtab");

	if (!symscn || !strscn)
		return NULL;

	void *symtab = elf->data + ELF_GET_SHDR_FIELD(elf, symscn, sh_offset);

	unsigned long cnt = ELF_GET_SHDR_FIELD(elf, symscn, sh_entsize);
	if (cnt)
		cnt = ELF_GET_SHDR_FIELD(elf, symscn, sh_size) / cnt;

	for (i = 0; i < cnt; ++i) {
		void *sym = ELF_GET_SYM(elf, symtab, i);
		const char *symname =
			elf->data + ELF_GET_SHDR_FIELD(elf, strscn, sh_offset)
			          + ELF_GET_SYM_FIELD(elf, sym, st_name);
		if (!strcmp(symname, found_sym)) {
			void *shdr = ELF_GET_SHDR(elf, ELF_GET_SYM_FIELD(elf, sym, st_shndx));
			return elf->data + ELF_GET_SHDR_FIELD(elf, shdr, sh_offset)
			                 + ELF_GET_SYM_FIELD(elf, sym, st_value)
			                 - ELF_GET_SHDR_FIELD(elf, shdr, sh_addr);
		}
	}

	return NULL;
}
