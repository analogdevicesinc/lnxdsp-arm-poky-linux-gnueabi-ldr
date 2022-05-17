<?php
/* 
 * Copyright (c) 2014-2021, Analog Devices, Inc.  All rights reserved.
 *
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


/* Options that we have added to GCC that may need some additional configuration.
** NOTE: This is not all GCC options that we have added but rather the options
** that the generator script needs to know about for one reason or another.
*/

$gccOptions = array(
);


/* Disclaimer text put out in to any generated files in GCC/Binutils */
$disclaimer = 
"/* This file is auto-generated, please do not edit the contents directly.\n".
"**\n".
"** Copyright (c) 2014-2021, Analog Devices, Inc.  All rights reserved.\n".
"** \n".
"** Redistribution and use in source and binary forms, with or without\n".
"** modification, are permitted (subject to the limitations in the\n".
"** disclaimer below) provided that the following conditions are met:\n".
"** \n".
"** * Redistributions of source code must retain the above copyright\n".
"**    notice, this list of conditions and the following disclaimer.\n".
"** \n".
"** * Redistributions in binary form must reproduce the above copyright\n".
"**    notice, this list of conditions and the following disclaimer in the\n".
"**    documentation and/or other materials provided with the\n".
"**    distribution.\n".
"** \n".
"** * Neither the name of Analog Devices, Inc.  nor the names of its\n".
"**    contributors may be used to endorse or promote products derived\n".
"**    from this software without specific prior written permission.\n".
"** \n".
"** NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE\n".
"** GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT\n".
"** HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED\n".
"** WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF\n".
"** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n".
"** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE\n".
"** LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR\n".
"** CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF\n".
"** SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR\n".
"** BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,\n".
"** WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE\n".
"** OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN\n".
"** IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n".
"*/\n\n".
"#if !defined(ADI_CHANGES)\n".
"#error This file should only be included for ADI compilers\n".
"#else\n\n";
$disclaimerEnd =
"#endif\n\n";

?>
