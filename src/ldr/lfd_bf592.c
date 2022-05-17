/*
 * File: lfd_bf592.c
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
 * Format handlers for LDR files on the BF592.
 */

#define __LFD_INTERNAL
#include "ldr.h"

static const char * const bf592_aliases[] = { "BF592", NULL };
static const struct lfd_target bf592_lfd_target = {
	.name = "BF592",
	.description = "Blackfin LDR handler for BF592",
	.aliases = bf592_aliases,
	.uart_boot = true,
	.iovec = {
		.read_block_header = bf54x_lfd_read_block_header,
		.display_dxe = bf54x_lfd_display_dxe,
		.write_block = bf54x_lfd_write_block,
		.dump_block = bf54x_lfd_dump_block,
	},
	.em = EM_BLACKFIN,
	.dyn_sections = false,
};

__attribute__((constructor))
static void bf592_lfd_target_register(void)
{
	lfd_target_register(&bf592_lfd_target);
}
