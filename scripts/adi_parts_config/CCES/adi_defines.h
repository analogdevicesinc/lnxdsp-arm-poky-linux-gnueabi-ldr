/* 
 * Copyright (c) 2014-2020, Analog Devices, Inc.  All rights reserved.

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
 */

/* This file is imported into the GCC sources from the
** ADI configurations folders. Please edit the master version of the 
** file or your changes may be overwritten.
*/

#if !defined(_ADI_DEFINES_H)
#define _ADI_DEFINES_H

/* Define the default processor and silicon revision for the toolchain.
** These will be selected if the -mproc and -msi-revision switch are not
** provided on the command line.
*/
#define ADI_DEFAULT_PROC adi_proc_SC589
#define ADI_DEFAULT_MPROC_SPECS \
  "%{!mproc=*:%{!march=*:%{!mcpu=*:-mproc=ADSP-SC589}}}", \
  "%{mproc=ADSP-SC5*:%{!mcpu=*:-mcpu=cortex-a5}}", \
  "%{mproc=ADSP-SC5*:%{!marm:%{!mthumb:-mthumb}}}"

/* ADSP-SC57x and ADSP-SC58x parts are subject to anomaly 20000082 that means
** unaligned ldrh instructions can malfunction. So disable unaligned accesses.
*/
#define CC1_SPEC " \
  %{!munaligned-access: \
      %{mproc=ADSP-SC57*: -mno-unaligned-access}\
      %{mproc=ADSP-SC58*: -mno-unaligned-access}\
   } "
#define CC1PLUS_SPEC " \
  %{!munaligned-access: \
      %{mproc=ADSP-SC57*: -mno-unaligned-access}\
      %{mproc=ADSP-SC58*: -mno-unaligned-access}\
   } "

/* Set ADI_HAS_BUILTIN_IRQ_FUNCS if the toolchain supports the 
** interrupt enable/disable builtins for the supported processors.
*/

#define ADI_HAS_BUILTIN_IRQ_FUNCS 1

#endif /* _ADI_DEFINES_H */
