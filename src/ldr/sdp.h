/*
 * File: sdp.h
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
 * View LDR contents; based on the "Visual DSP++ 4.0 Loader Manual"
 * and misc Blackfin HRMs
 */

#ifndef __SDP_H__
#define __SDP_H__

#define ADI_SDP_USB_VID                0x0456
#define ADI_SDP_USB_PID                0xb630

#define ADI_SDP_WRITE_ENDPOINT         0x06
#define ADI_SDP_READ_ENDPOINT          0x05

#define ADI_SDP_CMD_GROUP_BASE         0xCA000000
#define ADI_SDP_CMD_FLASH_LED          (ADI_SDP_CMD_GROUP_BASE | 0x01)
#define ADI_SDP_CMD_GET_FW_VERSION     (ADI_SDP_CMD_GROUP_BASE | 0x02)
#define ADI_SDP_CMD_SDRAM_PROGRAM_BOOT (ADI_SDP_CMD_GROUP_BASE | 0x03)
#define ADI_SDP_CMD_READ_ID_EEPROMS    (ADI_SDP_CMD_GROUP_BASE | 0x04)
#define ADI_SDP_CMD_RESET_BOARD        (ADI_SDP_CMD_GROUP_BASE | 0x05)
#define ADI_SDP_CMD_READ_MAC_ADDRESS   (ADI_SDP_CMD_GROUP_BASE | 0x06)
#define ADI_SDP_CMD_STOP_STREAM        (ADI_SDP_CMD_GROUP_BASE | 0x07)

#define ADI_SDP_CMD_GROUP_USER         0xF8000000
#define ADI_SDP_CMD_USER_GET_GUID      (ADI_SDP_CMD_GROUP_USER | 0x01)
#define ADI_SDP_CMD_USER_MAX           (ADI_SDP_CMD_GROUP_USER | 0xFF)

#define ADI_SDP_SDRAM_PKT_MIN_LEN      512
#define ADI_SDP_SDRAM_PKT_MAX_CNT      0x400
#define ADI_SDP_SDRAM_PKT_MAX_LEN      0x10000

struct sdp_header {
	u32 cmd;         /* ADI_SDP_CMD_XXX */
	u32 out_len;     /* number bytes we transmit to sdp */
	u32 in_len;      /* number bytes sdp transmits to us */
	u32 num_params;  /* num params we're passing */
	u32 params[124]; /* params array */
};

struct sdp_version {
	struct rev {
		u16 major;
		u16 minor;
		u16 host;
		u16 bfin;
	} rev;
	u8 datestamp[12];
	u8 timestamp[8];
	u16 bmode;
	u16 flags;
};

#endif
