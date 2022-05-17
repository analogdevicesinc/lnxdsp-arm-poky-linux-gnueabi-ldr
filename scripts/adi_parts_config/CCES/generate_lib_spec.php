<?php
/* 
 * Copyright (c) 2014-2022, Analog Devices, Inc.  All rights reserved.

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

  global $arch;

  fputs($f,"#undef  LIB_SPEC\n");
  fputs($f,"#define LIB_SPEC \" \\\n");
  fputs($f,"  %{!nostdlib: \\\n");
  if ($arch == "aarch64") {
    /* For ARM, the group brackets are included by default in unknown-elf.h */
    fputs($f, "    --start-group \\\n");
  }
  fputs($f,"    %{!mno-adi-sys-libs: \\\n");
  foreach ( $crtLdData as $part => $data ) {
    if ( $data['apt'] != NULL )
      fputs($f,"      %{mproc=$part: ".$data['apt'].".o%s} \\\n");
  }
  if ($arch == "arm") {
    fputs($f,"      %{mproc=ADSP-SC58*: -lfftacc} \\\n");
  }
  fputs($f,"      %{mproc=ADSP*: -ldrv -lssl -losal -lrtadi} \\\n");
  fputs($f,"      %{mproc=AD*: -lm} \\\n");
  fputs($f,"    } \\\n");
  fputs($f,"    -lc \\\n");
  if ($arch == "aarch64") {
    fputs($f, "    --end-group \\\n");
  }
  fputs($f,"  } \\\n");
  fputs($f,"  %{!T*: \\\n");
  foreach ( $crtLdData as $part => $data ) {
    fputs($f,"  %{mproc=$part:-T ".$data['ld']."%s} \\\n");
  }
  if ($arch == "arm") {
    fputs($f,"    %{mproc=ADSP-SC570: -T adsp-sc57x-common-l2.ld%s} \\\n");
    fputs($f,"    %{mproc=ADSP-SC571: -T adsp-sc57x-common-l2.ld%s} \\\n");
    fputs($f,"    %{mproc=ADSP-SC572: -T adsp-sc57x-common.ld%s} \\\n");
    fputs($f,"    %{mproc=ADSP-SC573: -T adsp-sc57x-common.ld%s} \\\n");
    fputs($f,"    %{mproc=ADSP-SC58*: -T adsp-sc58x-common.ld%s} \\\n");
  }
  fputs($f,"    %{mproc=ADSP-SC59*: -T adsp-sc59x-common.ld%s} \\\n");
  fputs($f,"  } \"\n");
  fputs($f,"\n\n");

?>
