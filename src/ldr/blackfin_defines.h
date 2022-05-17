/*
 * File: blackfin_defines.h
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
 * Misc defines ripped out of Blackfin headers.
 */

#ifndef __BLACKFIN_DEFINES__
#define __BLACKFIN_DEFINES__

/* common stuff */
#define LO(x) ((x) & 0xFFFF)
#define HI(x) (((x) >> 16) & 0xFFFF)

#define GET_1ST_NIBBLE(x) ((x & 0x000000FF) >> 0)
#define GET_2ND_NIBBLE(x) ((x & 0x0000FF00) >> 8)
#define GET_3RD_NIBBLE(x) ((x & 0x00FF0000) >> 16)
#define GET_4TH_NIBBLE(x) ((x & 0xFF000000) >> 24)

#define FILL_ADDR_16(var, val, idx1, idx2) \
	do { \
		var[idx1] = GET_1ST_NIBBLE(val); \
		var[idx2] = GET_2ND_NIBBLE(val); \
	} while (0)
#define FILL_ADDR_32(var, val, idx1, idx2, idx3, idx4) \
	do { \
		var[idx1] = GET_1ST_NIBBLE(val); \
		var[idx2] = GET_2ND_NIBBLE(val); \
		var[idx3] = GET_3RD_NIBBLE(val); \
		var[idx4] = GET_4TH_NIBBLE(val); \
	} while (0)

#endif
