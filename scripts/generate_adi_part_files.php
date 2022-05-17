#!/usr/bin/env php
<?php
/* 
 * Copyright (c) 2014-2022, Analog Devices, Inc.  All rights reserved.
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

/* Script to generate the Analog specific files required to build the toolchain.
** This script consumes the -compiler.xml files located in current directory
** that are listed in the $xmlFiles variable below.
** Currently we produce the following files:
**    gcc/config/arm/adi-processors.def
**    binutils/gas/config/adi-processors-asm.def
**    gcc/config/arm/adi_crt_spec.h
**        - Contains a list of crt files to be included for specific parts.
**    gcc/config/arm/adi_lib_spec.h
**        - Contains a list of .ld files and libraries to link against for
**          each processor.
**    concatenated ld files
**        - We concatenate each part's ld file with the l2 and l3 common
**          files, to produce an ld file for the CCES Linker Files Add-In to copy.
**    newlib/libc/sys/arm/adi_crt.mk
**        - Contains a list of the processor specific objects and rules
**          for compiling them.
*/


function help() {
  echo "-target <target> - target triple, e.g. arm-none-eabi\n";
  echo "-config <conf> - pass a configuration directory to the script\n";
  echo "-xml <dir> - directory containing the processor XML files\n";
  echo "-newlib <dir> - top level of the newlib sources\n";
  echo "-gcc <dir> - top level of the GCC sources\n";
  echo "-binutils <dir> - top level of the binutils sources\n";
  echo "-toolchain <dir> - directory for the toolchain build\n";
  echo "-v - be a bit more verbose\n";
  exit(-1);
}

$xmlDir = false;
$newlibDir = false;
$gccDir = false;
$binutilsDir = false;
$configDir = false;
$toolchainDir = false;
$verbose = false;
$target = false;

$i = 1;
while ( $i < $argc ) {
  switch ($argv[$i]) {
    case "-v":
      $verbose = true;
      $i++;
    break;
    case "-target":
      $target = $argv[$i+1];
      $arch = preg_replace("/-.*/", "", $target);
      $i+=2;
    break;
    case "-config":
      $configDir = $argv[$i+1];
      $i+=2;
    break;
    case "-xml":
      $xmlDir = $argv[$i+1];
      $i+=2;
    break;
    case "-newlib":
      $newlibDir = $argv[$i+1];
      $i+=2;
    break;
    case "-gcc":
      $gccDir = $argv[$i+1];
      $i+=2;
    break;
    case "-binutils":
      $binutilsDir = $argv[$i+1];
      $i+=2;
    break;
    case "-toolchain":
      $toolchainDir = $argv[$i+1];
      $i+=2;
    break;
    default:
      echo "Unknown option: ".$argv[$i]."\n";
      exit(-1);
  }
}
if ( $target == false ) {
  echo "error: no target\n";
  help();
}
if ( $xmlDir == false ) {
  echo "error: no xml dir\n";
  help();
}
if ( $gccDir == false ) {
  echo "error: no gcc dir\n";
  help();
}
if ( $binutilsDir == false ) {
  echo "error: no binutils dir\n";
  help();
}
if ( $newlibDir == false ) {
  echo "error: no newlib dir\n";
  help();
}
if ( $configDir == false ) {
  echo "error: Please provide a configuration directory\n";
  help();
}
if ( $toolchainDir == false ) {
  echo "error: no toolchain dir\n";
  help();
}


/* List of the processors we support. The xml files below
** will be consumed in the production of the toolchain sources.
*/
include_once("$configDir/processor_xml_list.php");
include_once("$configDir/toolchain_config.php");

$macroName = "ADI_PROC";

/* Structure used in the production of the adi-processors.def using the 
** compilation of GCC.
*/

$macroDefinitions = array (
  'fields' => array (
    'stringName' => array (
      'name' => "String name",
      'quoted' => true,
    ),
    'gccProcEnum' => array (
      'name' => "GCC Processor Enumeration",
      'quoted' => false,
    ),
    'gccCpuName' => array (
      'name' => "GCC CPU Name",
      'quoted' => true,
    ),
    'gccCpuEnum' => array (
      'name' => "GCC CPU Enumeration",
      'quoted' => false,
    ),
    'gccFpuName' => array (
      'name' => "FPU Name",
      'quoted' => true,
    ),
    'gccFpuABI' => array (
      'name' => "FPU ABI",
      'quoted' => false,
    ),
    'siliconRevisions' => array (
      'name' => "Silicon Revisions",
      'quoted' => true,
      'separator' => " ",
      'prefixSeparator' => true,
      'postSeparator' => true,
    ),
    'preProcessorMacros' => array (
      'name' => "Preprocessor Macros",
      'quoted' => true,
      'separator' => " ",
    ),
    'numCores' => array (
      'name' => "Number Of Cores",
      'quoted' => false,
    ),
    'defaultLD' => array (
      'name' => "Default LD file",
      'quoted' => true,
    ),
    'defaultSiliconRevision' => array (
      'name' => "Default Silicon Revision",
      'quoted' => true,
    ),
    'hidden' => array (
      'name' => "Hidden (accepted but does not appear in list of processors in help)",
      'quoted' => false,
    ),
  ),
);

/* **************************************************************************** */
/* ******************* Functions to generate the crt and lib .h files ********* */
$crtLdData = array();
function generate_spec_files() {
  /* Generates the header files that define the crt and ld files for our supported
  ** processors.
  */
  global $crtLdData, $disclaimer, $disclaimerEnd, $gccDir, $gccOptions, $verbose,
	$configDir, $arch;
  $crtFileName = "$gccDir/gcc/config/".$arch."/adi_crt_spec.h";
  $libFileName = "$gccDir/gcc/config/".$arch."/adi_lib_spec.h";

  /* Generate the crt file */
  if ( file_exists($crtFileName) ) {
    if ( $verbose ) {
      echo "Removing existing $crtFileName\n";
    }
    unlink($crtFileName);
  }
  echo "  Creating: $crtFileName...";
  $f = fopen($crtFileName,"w");
  if ( $f === false ) {
    echo "Error: Failed to open $crtFileName for writing\n";
    exit(-1);
  }
  fputs($f,$disclaimer);
  fputs($f,"#undef  STARTFILE_SPEC\n");
  fputs($f,"#define STARTFILE_SPEC \"\\\n");
  fputs($f,"crti%O%s crtbegin%O%s \\\n");
  fputs($f,"%{msys-crt=*:%*} \\\n");
  fputs($f,"%{!msys-crt*: \\\n");
  foreach ( $crtLdData as $part => $data ) {
    fputs($f,"%{mproc=$part:".$data['crt']."%O%s} \\\n");
  }
  fputs($f,"} \\\n");
  fputs($f,"  \"\n");
  fputs($f,"\n\n");
  fputs($f,"#undef  ENDFILE_SPEC\n");
  fputs($f,"#define ENDFILE_SPEC \"crtend%O%s crtn%O%s\"\n\n");
  fputs($f,$disclaimerEnd);
  fclose($f);
  echo "Done\n"; 
  /* Generate the ld file */
  if ( file_exists($libFileName) ) {
    if ( $verbose ) {
      echo "Removing existing $libFileName\n";
    }
    unlink($libFileName);
  }
  echo "  Creating: $libFileName...";
  $f = fopen($libFileName,"w");
  if ( $f === false ) {
    echo "Error: Failed to open $libFileName for writing\n";
    exit(-1);
  }
  fputs($f,$disclaimer);
  include_once("$configDir/generate_lib_spec.php");
  fputs($f,$disclaimerEnd);
  fclose($f);
  echo "Done\n";
}

/* **************************************************************************** */
/* ** Functions to generate the concatenated ld files for a given memory type * */
function generate_concatenated_ld_files($memory, $commonSuffix) {
  /* Create concatenated ld files for all parts with the given memory type.
  */
  global $crtLdData, $newlibDir, $toolchainDir, $arch, $target;

  foreach ( $crtLdData as $part => $data ) {
    $partLdName = $data['ld'];
    $commonLdName = preg_replace("/(5[789]).(fpga)?\.ld/", "$1x-common$commonSuffix.ld", $partLdName);

    /* If there are no MEM_L3 sections in the part-specific ld file, don't
    ** create an -l3 variant.
    */
    if ($memory == 'l3') {
      $partLd = fopen("$newlibDir/libgloss/$arch/$partLdName", "r");
      $hasL3 = strpos(file_get_contents("$newlibDir/libgloss/$arch/$partLdName"), "MEM_L3") !== false;
      if (!$hasL3) {
        echo "  Skipping concatenation of $partLdName and $commonLdName as $part has no $memory memory\n";
        continue;
      }
    }

    $concatLdName = strtolower($part) . "-$memory.ld";
    $partLd = fopen("$newlibDir/libgloss/$arch/$partLdName", "r");
    $commonLd = fopen("$newlibDir/libgloss/$arch/$commonLdName", "r");
    $concatDest = "$toolchainDir/$target/$target/lib/ldscripts";
    echo "  Creating: $concatDest/$concatLdName from $partLdName and $commonLdName";
    if (!is_dir($concatDest))
    {
      mkdir($concatDest, 0755, true);
    }
    $concatLd = fopen("$concatDest/$concatLdName", "w");

    /* Take the license from the common ld file, since that has a RedHat license.
    */
    $year = date("Y");
    while ($line = fgets($commonLd)) {
      /* Update copyright date. First check for files that just have one year,
      ** rather than a range, and that year isn't the current one.
      */
      if (!preg_match("/(Portions Copyright \(c\) $year)(,? Analog Devices)/", $line)) {
        $line = preg_replace("/(Portions Copyright \(c\) 20\d\d)(,? Analog Devices)/", "$1-$year$2", $line);
      }
      /* Next replace the year at the end of the range.
      */
      $line = preg_replace("/(Portions Copyright \(c\) 20\d\d)-20\d\d(,? Analog Devices)/", "$1-$year$2", $line);
      fprintf($concatLd, $line);
      if (preg_match("/\*\//", $line)) {
        break;
      }
    }

    /* Add some comments to the file for the user.
    */
    fprintf($concatLd, "\n");
    fprintf($concatLd, "/* This file is copied into your project by the Linker Files Add-In.\n");
    fprintf($concatLd, " * The default target for code and data is " . strtoupper($memory) . " memory. Please modify it\n");
    fprintf($concatLd, " * as required for your project.\n");
    fprintf($concatLd, " *\n");
    fprintf($concatLd, " * If you change settings within the Linker Files Add-In, the file will\n");
    fprintf($concatLd, " * be regenerated, and your modified copy will be preserved with the\n");
    fprintf($concatLd, " * .backup file extension.\n");
    fprintf($concatLd, " *\n");
    fprintf($concatLd, " * This file was created by CrossCore Embedded Studio %s for %s.\n", getenv("CCES_VERSION"), $part);
    fprintf($concatLd, " */\n");
    $in_license = 1;
    /* Skip the license in the part-specific ld file.
    */
    while ($line = fgets($partLd)) {
      if ($in_license && preg_match("/IMPORTANT:/", $line)) {
        /* This is a comment, following directly on from the license, that
        ** we want to keep from the part-specific file.
        */
        $in_license = 0;
        fprintf($concatLd, "\n/*\n"); 
      }
      if (!$in_license) {
        fprintf($concatLd, $line);
      }
      if (preg_match("/\*\//", $line)) {
        $in_license = 0;
      }
    }
    while ($line = fgets($commonLd)) {
      fprintf($concatLd, $line);
    }

    fclose($partLd);
    fclose($commonLd);
    fclose($concatLd);
    echo "...Done\n";
  }

  echo "Done\n";
}

function generate_all_concatenated_ld_files() {
  /* Takes each ld file and concatenates the common and common-l2 ld files to it.
  ** Removes the duplicate copyright and adds some information about the CCES
  ** version used.
  */
  generate_concatenated_ld_files("l2", "-l2");
  generate_concatenated_ld_files("l3", "");
}

function generate_newlib_makefiles() {
  global $newlibDir;
  global $arch;
  if ($arch == "arm") {
    generate_newlib_makefile($newlibDir."/newlib","newlib");
    generate_newlib_makefile($newlibDir."/newlib/libc","libc");
    generate_newlib_makefile($newlibDir."/newlib/libc/sys","sys");
    generate_newlib_makefile($newlibDir."/newlib/libc/sys/arm","arch");
  }
  else if ($arch == "aarch64") {
    generate_newlib_makefile($newlibDir."/libgloss/aarch64","arch");
    touch($newlibDir."/newlib/adi_crt.mk");
    touch($newlibDir."/newlib/libc/adi_crt.mk");
    touch($newlibDir."/newlib/libc/sys/adi_crt.mk");
  }
}

class sub_inf_files {
  public $crt;
  public $apt;
}
function generate_newlib_makefile($newlibPath,$kind) {
  global $crtLdData, $verbose, $arch;

  $makefileName = "${newlibPath}/adi_crt.mk";

  if ( file_exists($makefileName) ) {
    if ( $verbose ) {
      echo "Removing existing $makefileName\n";
    }
    unlink($makefileName);
  }
  echo "Generating: $makefileName...";
  if (!copy(dirname(__FILE__)."/auto_gen_header", $makefileName)) {
     echo "error: failed to create $makefileName\n";
     exit(-1);
  }
  $makefile = fopen($makefileName,"a+");
  if ( $makefile == NULL ) {
    echo "error: failed to open $makefileName\n";
    exit(-1);
  }
  # first find the list of inflection points
  $infPoints = array();
  foreach ( $crtLdData as $part => $data ) {
    if ( !isset($data['infpt'])) {
      echo "Error: XML file for $part has no inflection point information\n";
      exit(-1);
    }
    $tmp = new sub_inf_files();
    $tmp->crt = $data['crt'];
    $tmp->apt = $data['apt'];
    $infPoints[$data['infpt']][$part] = $tmp;
  }
  # newlib needs to copy in processor specific files (CRTs and Abstract Page
  # Tables).
  if ( $kind != "arch") {
    if ( $kind == "newlib" )
      $subdir = "$(CRT0_DIR)";
    else if ( $kind == "libc" )
      $subdir = "sys/";
    else if ( $kind == "sys" )
      $subdir = "$(sys_dir)/";
    else {
      echo "error: unknown newlib subdir.\n";
      exit(-1);
    }

    fputs($makefile,"# Copy up the processor specific files.\n");
    fputs($makefile,"install_adi_files_%: ".$subdir."$(SUBINF_NAME)\n");
    fputs($makefile,"\trm -f $(SUBINF_NAME)\n");
    fputs($makefile,"\tln ".$subdir."$(SUBINF_NAME) $(SUBINF_NAME) >/dev/null 2>/dev/null \\\n");
    fputs($makefile,"\t|| cp ".$subdir."$(SUBINF_NAME) $(SUBINF_NAME)\n");
  }

  fputs($makefile,"\nADI_SUB_INFLECTION_FILES =\n\n");

  $overrides = "";
  foreach ( $infPoints as $infpt => $adi_files ) {
    $infList = array();
    fputs($makefile,"ifneq (,\$(findstring -mproc=ADSP-".$infpt.",\$(CFLAGS)))\n");
    foreach ( $adi_files as $part => $adi_file ) {
      $crt = $adi_file->crt;
      $addCrt = in_array($crt, $infList)===FALSE;
      $apt = $adi_file->apt;
      $addApt = $apt != NULL && in_array($apt, $infList)===FALSE;
      if ( $kind != "arch" ) {
        if ( $addCrt ) {
          fputs($makefile, $crt.".o: SUBINF_NAME=".$crt.".o\n");
          fputs($makefile, $crt.".o: install_adi_files_".$crt."\n");
        }
        if ( $addApt ) {
          fputs($makefile, $apt.".o: SUBINF_NAME=".$apt.".o\n");
          fputs($makefile, $apt.".o: install_adi_files_".$apt."\n");
        }
      } else {
        if ( $addCrt ) {
          if ($arch == "aarch64") {
            # CRTs for Aarch64 are built with $(CC)
            $overrides .= $crt.".o: override CCFLAGS := $(patsubst -mproc=%,-mproc=$part,\$(CCFLAGS))\n";
            $overrides .= $crt.".o: override CC := $(patsubst -mproc=%,-mproc=$part,\$(CC))\n";
          } else {
            # CRTS for ARM are built with $(CCAS)
            $overrides .= $crt.".o: override CCASFLAGS := $(patsubst -mproc=%,-mproc=$part,\$(CCASFLAGS))\n";
            $overrides .= $crt.".o: override CCAS := $(patsubst -mproc=%,-mproc=$part,\$(CCAS))\n";
          }
        }
        if ( $addApt ) {
          # Abstract Page Tables are C files.
          $overrides .= $apt.".o: override CFLAGS := $(patsubst -mproc=%,-mproc=$part,\$(CFLAGS))\n";
          $overrides .= $apt.".o: override CC := $(patsubst -mproc=%,-mproc=$part,\$(CC))\n";
        }
      }
      if ( $addCrt )
        $infList[] = $crt;
      if ( $addApt )
        $infList[] = $apt;
    }
    # ADI_SUB_INFLECTION_FILES list
    fputs($makefile,"\n");
    fputs($makefile,"ADI_SUB_INFLECTION_FILES =");
    foreach ( $infList as $i => $file )
      fputs($makefile, " \\\n  ".$file.".o");
    fputs($makefile,"\nendif\n\n");
  }
  if ( $kind == "arch" ) {
    fputs($makefile,$overrides);
  }
  fclose($makefile);
  echo "Done\n";
}

/* **************************************************************************** */
/* ******************* Functions to generate the processor.def files ********** */
function generate_processor_defs() {
  global $gccDir, $binutilsDir, $verbose;
  $outputFiles = array (
    "asm" => "$binutilsDir/gas/config/adi-processors-asm.def",
    "gcc" => "$gccDir/gcc/adi-processors.def",
  );
  foreach ( $outputFiles as $mode => $file ) {
    generate_processor_def($file,$mode);
  }
}

function reset_data() {
  global $macroDefinitions;

  $macroDefinitions['fields']['stringName']['data'] = false;
  $macroDefinitions['fields']['gccProcEnum']['data'] = false;
  $macroDefinitions['fields']['gccCpuName']['data'] = false;
  $macroDefinitions['fields']['gccCpuEnum']['data'] = false;
  $macroDefinitions['fields']['gccFpuName']['data'] = false;
  $macroDefinitions['fields']['gccFpuABI']['data'] = false;
  $macroDefinitions['fields']['siliconRevisions']['data'] = false;
  $macroDefinitions['fields']['preProcessorMacros']['data'] = false;
  $macroDefinitions['fields']['numCores']['data'] = false;
  $macroDefinitions['fields']['defaultLD']['data'] = false;
  $macroDefinitions['fields']['defaultSiliconRevision']['data'] = false;
  $macroDefinitions['fields']['hidden']['data'] = false;

}

function generate_processor_def($outputFile,$mode) {
  global $disclaimer, $disclaimerEnd, $macroDefinitions, $macroName, $xmlFiles,
         $crtLdData, $verbose, $arch;
  if ( file_exists($outputFile) ) {
    if ( $verbose ) {
      echo "Removing existing $outputFile\n";
    }
    unlink($outputFile);
  }

  echo "Generating: $outputFile...";
  $f = fopen($outputFile,"w");
  fwrite($f,$disclaimer);

  /* Put out a brief description of the macro */
  fwrite($f,"/* The ".$macroName.
            " macro is defined as follows:\n** $macroName(\n");
  foreach ( $macroDefinitions['fields'] as $fieldID => $data ) {
    fwrite($f,"**   ");
    $quoted = false;
    $separator = false;
    if ( isset($data['quoted']) && $data['quoted'] == true ) {
      $quoted = true;
      fwrite($f,"\"");
    }
    if ( isset($data['separator']) ) {
      $separator = $data['separator'];
      if ( $quoted  === false ) {
        echo "Error: field $fieldID expected multiple ".
             "values but isn't quoted.\n";
        exit(-1);
      }
      if ( isset($data['prefixSeparator']) && 
           $data['prefixSeparator'] == true ) {
        fwrite($f,$separator);
      }
    } 
    fwrite($f,$data['name']);
    if ( $separator !== false ) {
      fwrite($f," [".$separator.$data['name']."]");
    }
    if ( $separator !== false ) {
      if ( isset($data['postSeparator']) && $data['postSeparator'] == true ) {
        fwrite($f,$separator);
      }
    }
    if ( $quoted !== false ) {
      fwrite($f,"\"");
    }
    fwrite($f,",\n");
  }
  fwrite($f,"** )\n*/\n\n");


  /* Load up the XML files and get to work! */
  foreach ( $xmlFiles as $x => $xmf ) {
    global $xmlDir;
    reset_data();
    $xmlFile = "$xmlDir/$xmf";
    if ( $verbose )
      echo "Parsing $xmlFile\n";
    $xml = simplexml_load_file($xmlFile); 
    if ( $xml === false ) {
      echo "Error: Failed to load $xmlFile\n";
      exit(-1);
    }
    $macroDefinitions['fields']['hidden']['data'] = isset($xml['hidden']) ? $xml['hidden'] : 0;
    /* The XML file should contain a <core> directive for the ARM core at the 
    ** top level.
    */
    if ( !isset($xml->core)) {
      echo "Error: No top-level <core> directive found in $xmlFile\n";
      exit(-1);
    }
    if ( $verbose )
      echo "Cores recorded in the XML:\n";
    $matchingCore = false;
    foreach ( $xml->core as $idx => $coreData ) {
      $att = $coreData->attributes();
      if ( $verbose )
        echo "    ".$att['id']." => ".$att['family'];
      if ( $att['family'] == "ARM" ) {
        if ( $verbose )
          echo "  *";
        $matchingCore = $coreData;
      }
      if ( $verbose )
        echo "\n";
    }
    if ( $matchingCore === false ) {
      echo "Error: No ARM core information found in $xmlFile\n";
      exit(-1);
    }
    $xml = $matchingCore;
    /* Basic part info */
    $att = $xml->architecture[0]->attributes();
    if ( !isset($att['name'])) {
      echo "Error: name attribute not set in $xmlFile\n";
      exit(-1);
    }
    $name = (string)$att['name'];
    if ( !isset($att['fpu-name'])) {
      echo "Error: fpu-name attribute not set in $xmlFile\n";
      exit(-1);
    }
    $gccFpuName = (string)$att['fpu-name'];
    if ( !isset($att['fpu-abi'])) {
      echo "Error: fpu-abi attribute not set in $xmlFile\n";
      exit(-1);
    }
    $gccFpuABI = (string)$att['fpu-abi'];
    if ( !isset($att['default-ldf'])) {
      echo "Error: default-ldf attribute not set in $xmlFile\n";
      exit(-1);
    }
    $defaultLD = (string)$att['default-ldf'];
    if ( !isset($att['default-crt'])) {
      echo "Error: default-crt attribute not set in $xmlFile\n";
      exit(-1);
    }
    $defaultCRT = (string)$att['default-crt'];
    if ( !isset($att['default-apt'])) {
      $defaultAPT = NULL;
    } else {
      $defaultAPT = (string)$att['default-apt'];
    }
    if ( !isset($att['inflection-point'])) {
      echo "Error: inflection-point attribute not set in $xmlFile\n";
      exit(-1);
    }
    $inflectionPoint = (string)$att['inflection-point'];
    if ( !isset($att['maps-to'])) {
      echo "Error: maps-to attribute not set in $xmlFile\n";
      exit(-1);
    }
    $armCPU = (string)$att['maps-to'];
    if ( !isset($att['num-cores'])) {
      echo "Error: num-cores attribute not set in $xmlFile\n";
      exit(-1);
    }
    $numCores = (string)$att['num-cores'];

    if ( $arch=="aarch64" && !(isset($att['is-64bit']) && $att['is-64bit'] == 1 )) {
      echo "\nSkipping non 64-bit processor ".$name." for aarch64\n";
      continue;
    }

    if ( $arch=="arm" && (isset($att['is-64bit']) && $att['is-64bit'] == 1 )) {
      echo "\nSkipping 64-bit processor ".$name." for 32-bit ARM\n";
      continue;
    }

    if ( $verbose ) {
      echo "       Processor: $name\n";
      echo "        FPU Name: $gccFpuName\n";
      echo "         FPU ABI: $gccFpuABI\n";
      echo "     Default CRT: $defaultCRT\n";
      echo "     Default APT: $defaultAPT\n";
      echo "      Default LD: $defaultLD\n";
      echo "Inflection Point: $inflectionPoint\n";
      echo "             CPU: $armCPU\n";
      echo "           Cores: $numCores\n";
    }
    $macroDefinitions['fields']['stringName']['data'] = $name;
    $proc_name = str_replace("ADSP-","",$name);
    $proc_name = str_replace("-","_",$proc_name);
    $macroDefinitions['fields']['gccProcEnum']['data'] = "adi_proc_".$proc_name;
    $macroDefinitions['fields']['gccCpuName']['data'] = $armCPU;
    $macroDefinitions['fields']['gccCpuEnum']['data'] =
      preg_replace('/-|\+.*/','',$armCPU);
    $macroDefinitions['fields']['gccFpuName']['data'] = $gccFpuName;
    $macroDefinitions['fields']['gccFpuABI']['data'] = $gccFpuABI;
    $macroDefinitions['fields']['defaultLD']['data'] = $defaultLD;
    $macroDefinitions['fields']['numCores']['data'] = $numCores;
    /* Record the CRT and LD data to later produce the def headers for those */
    $crtLdData[$name]['crt'] = $defaultCRT;
    $crtLdData[$name]['apt'] = $defaultAPT;
    $crtLdData[$name]['ld'] = $defaultLD;
    $crtLdData[$name]['infpt'] = $inflectionPoint;
  
    /* Default silicon revisions */
    $att = $xml->{'silicon-revisions'}->attributes();
    $defaultSiRev = (string)$att['command-line-default'];
    $macroDefinitions['fields']['defaultSiliconRevision']['data'] = $defaultSiRev;
    $sirevs = $xml->{'silicon-revisions'}[0];
    $revisions = array();
    if ($arch == "arm") {
      /* No legacy "-msi-revision=none" support for AArch64 */
      if ( $verbose ) {
        echo "           Rev: none (implicit, deprecated) => no lib path\n";
      }
      $revisions[] = "none";
    }
    foreach ( $sirevs as $idx => $revData ) {
      $revision = array();
      $att = $revData->attributes();
      $revision['name'] = (string)$att['revision'];
      $revision['path'] = (string)$att['lib-path'];
      if ( $verbose ) {
        echo "           Rev: ".$revision['name']." => ".$revision['path']."\n";
      }
      // Don't add 'path'. That's controlled by the multilib support.
      $revisions[] = $revision['name'];
    }
    $macroDefinitions['fields']['siliconRevisions']['data'] = $revisions;
  
    /* Processor macros */
    $macroData = $xml->{'feature-macros'}[0];
    $macros = array();
    foreach ( $macroData as $idx => $data ) {
      $macro = array();
      $att = $data->attributes();
      $macro['name'] = (string)$att['name'];
      $macro['value'] = (string)$att['value'];
      if ( $verbose ) {
        echo "         Macro: ".$macro['name']." => ".$macro['value']."\n";
      }
      $macros[] = $macro['name']."=".$macro['value'];
    }
    $macroDefinitions['fields']['preProcessorMacros']['data'] = $macros;
  
    /* Put out the data as a list of pre-processor macros */
    fwrite($f,"$macroName(");
    $fieldCount = 0;
    foreach ( $macroDefinitions['fields'] as $fieldID => $data ) {
      if ( $fieldCount != 0 ) {
        fwrite($f,", ");
      }
      $fieldCount++;
      if ( $data['data'] === false ) {
        echo "Error: Failed to extract data for $fieldID\n";
        exit(-1);
      }
      $quoted = false;
      $separator = false;
      if ( isset($data['quoted']) && $data['quoted'] === true ) {
        $quoted = true;
        fwrite($f,"\"");
      }
      if ( isset($data['separator']) ) {
        $separator = $data['separator'];
      }
      if ( $separator !== false && isset($data['prefixSeparator']) &&
                                         $data['prefixSeparator'] === true ) {
        fwrite($f,"$separator");
      }
      if ( !is_array($data['data'])) {
        fwrite($f,$data['data']);
      } else {
        if ( $separator === false ) {
          echo "Error: For field $fieldID, multiple data elements ".
               "encountered but no spearator!\n";
          exit(-1);
        }
        $entryCount = 0;
        foreach ( $data['data'] as $idx => $element ) {
          if ( $entryCount > 0 ) {
            fwrite($f,$separator);
          }
          $entryCount++;
          fwrite($f,$element);
        }
      }
      if ( $separator !== false && isset($data['postSeparator']) &&
                                         $data['postSeparator'] === true ) {
        fwrite($f,"$separator");
      }
      if ( $quoted !== false ) {
        fwrite($f,"\"");
      }
    }
    fwrite($f,")\n");
    if ( $verbose ) {
      echo "-----------------------------------------------------------\n\n";
    }
  }
  fputs($f,$disclaimerEnd);
  fclose($f);
  echo "Done\n";
}

function install_multilib_files()
{
  /* Copy multilib configuration files from configDir into gcc sources.
   * Ideally these would be generated from the compiler.xmls as well.
   */

  global $configDir, $gccDir;

  $components = array(
    't-arm-elf' => array(
    'optional' => false,
    'sourceFile' => "$configDir/t-arm-elf",
    'destFile' =>"$gccDir/gcc/config/arm/t-arm-elf",
    ),
    'adi_defines.h' => array(
      'optional' => false,
      'sourceFile' => "$configDir/adi_defines.h",
      'destFile' => "$gccDir/gcc/config/arm/adi_defines.h",
    ),
    'adi_multilib_defaults' => array(
      'optional' => false,
      'sourceFile' => "$configDir/adi_multilib_default.h",
      'destFile' => "$gccDir/gcc/config/arm/adi_multilib_default.h",
    ),
    'adi_linux_multilib_defaults' => array(
      'optional' => true,
      'sourceFile' => "$configDir/adi_linux_multilib_default.h",
      'destFile' => "$gccDir/gcc/config/arm/adi_linux_multilib_default.h",
    ),
    't-linux-eabi' => array(
      'optional' => true,
      'sourceFile' => "$configDir/t-linux-eabi",
      'destFile' => "$gccDir/gcc/config/arm/t-linux-eabi",
    ),
  );

  foreach ($components as $component => $data ) {
    echo "Installing: ".$data['destFile']."...";
    if ( !file_exists($data['sourceFile'])) {
      if ( $data['optional'] == true ) {
        echo "Warning: NOT installing $component as the source file doesn't exist\n";
      } else {
        echo "Error: Source file ".$data['sourceFile']." does not exist.\n";
        exit(-1);
      }
    } else {
      $command = "cp ".$data['sourceFile']." ".$data['destFile'];
      $res = 0;
      $out = array();
      exec($command,$out,$res);
      if ( $res != 0 ) {
        echo "Error: Failed to install $component:\n";
        print_r($command);
        print_r($out);
        exit(-1);
      }
      echo "Done\n";
    }
  }
  return;
}

/* Multilib files are in-tree for AArch64 */
if ($arch == "arm")
  install_multilib_files();

generate_processor_defs();
generate_spec_files();
generate_newlib_makefiles();
generate_all_concatenated_ld_files();
echo "All done\n";

?>
