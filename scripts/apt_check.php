#!/usr/bin/env php

<?php

/* Script to examine an executable and validate that symbols are placed into 
** accessible RW locations in the absract page table.
** Copyright (C). Analog Devices 2015. All rights reserved.
** Author: David Gibson (david.gibson@analog.com)
** Usage: <script> executable
** Ensure that the path to the CCES installation at the top of the script is correct.
*/
$CCES = "/c/analog/cces2.0.0";
$CCESAN= "$CCES/ARM/arm-none-eabi/bin/arm-none-eabi-";

if ( $argc != 2 ) {
  die("Error: application requires an executable to analyse\n");
}
$EXE = $argv[1];
if ( !file_exists($EXE) ) {
  die("Error: Could not open $EXE for parsing\n");
}

// Get the symbol table
$outfile = "apt_check.out";
if (file_exists($outfile))
  unlink($outfile);
$command = "${CCESAN}nm $EXE | sort > $outfile";
exec("c:/cygwin/bin/bash -c \"$command\"",$out,$res);
if ( $res != 0 ) {
  echo "Error: Failed to nm the executable";
  echo "\n";
  print_r($out);
  echo "\n";
}
$f = file_get_contents($outfile);
$e = explode("\r\n",$f);
// Find the addresses for _adi_mmu_absPageTable and _adi_mmu_absPageTableSize
$pageTableAddr = false;
$pageTableSizeAddr = false;
$pageTableSym = "_adi_mmu_absPageTable";
$pageTableSizeSym = "_adi_mmu_absPageTableSize";
echo "Finding address of APT and APT size\n";
reset($e);
$syms = array();
// Save all the syms and their start address. We'll use these later
// to ensure that they're placed within a page table range.

do {
  $e2 = explode(" ",current($e));
  $entry = array();
  if ( count($e2) != 3 ) {
    // Usually special symbols so ignore them
    //echo "Don't know how to add entry for ".current($e)."\n";
  } else {
    $entry['sym'] = $e2[2];
    $entry['addr'] = $e2[0];
    $entry['type'] = $e2[1];
    $syms[] = $entry;
  }
  if ( strcmp($e2[count($e2)-1],$pageTableSym) == 0 ){
    $pageTableAddr = $e2[0];
    echo "Found page table. It is located at $pageTableAddr\n";
  } 
  if ( strcmp($e2[count($e2)-1],$pageTableSizeSym) == 0 ) {
    $pageTableSizeAddr = $e2[0];
    echo "Found page table size. It is located at $pageTableSizeAddr\n";
  } 
} while ( next($e) );
if ( $pageTableAddr == false || $pageTableSizeAddr == false ) {
  echo "Error: Failed to find location and size of page table.\n";
  exit(-1);
}

// Get the page table size
$stop = "0x".$pageTableSizeAddr;
$stop = $stop + 0x4;
$command = "${CCESAN}objdump -s ${EXE} --start-address=0x$pageTableSizeAddr --stop-address=0x".dechex($stop)." | tail -1 > $outfile";
exec("c:/cygwin/bin/bash -c \"$command\"",$out,$res);
if ( $res != 0 ) {
  echo "Error: Failed to objdump the executable";
  echo "\n";
  print_r($out);
  echo "\n";
}
$f = file_get_contents($outfile);
$e = explode(" ",$f);
$tableEntries = hexdec(deword($e[2]));
// Size of a table entry in bytes
$entrySize = 12;
echo "Table size  = $tableEntries entries \n";

$stop = "0x".$pageTableAddr;
$stop = $stop + ($entrySize*$tableEntries);
$command = "${CCESAN}objdump -s ${EXE} --start-address=0x$pageTableAddr --stop-address=0x".dechex($stop)." | tail -n +5  > $outfile";
exec("c:/cygwin/bin/bash -c \"$command\"",$out,$res);
if ( $res != 0 ) {
  echo "Error: Failed to objdump (2) the executable";
  echo "\n";
  print_r($out);
  echo "\n";
}
$f = file_get_contents($outfile);
$e = explode("\r\n",$f);
$vals = array();
foreach ( $e as $idx => $line ) {
  $e2 = explode(" ",$line);
  if ( !isset($e2[2]) || !isset($e2[3]) || !isset($e2[4]) || !isset($e2[5]) ) {
  } else {
    $vals[] = deword($e2[2]);
    $vals[] = deword($e2[3]);
    $vals[] = deword($e2[4]);
    $vals[] = deword($e2[5]);
  }
}
$tEntries = count($vals)/3;
echo count($vals)." entries in vals. That's good for ".$tEntries." table entries\n";
if ( $tEntries != $tableEntries ) {
  echo "That's not equal to the no of predicted table entries. Something is wrong with the dump\n";
  exit(-1);
}
$pos = 0;
$aptEntries = array();
$entryCount = 0;
$ID_CORE0 = 0x1;
$ID_CORE1 = 0x2;
$ID_CORE2 = 0x4;
for ( $i = 0; $i < $tableEntries ; $i++ ) {
  $start = $vals[$pos];
  $pos++;
  $end = $vals[$pos];
  $pos++;
  $flags = $vals[$pos];
  $pos++;
  add_apt_entry($start,$end,$flags);

}


/* Iterate over the symbols and ensure that they're all covered by a valid 
** page table entry 
*/

echo "Checking placement of symbols\n";
$checkCount = 0;
foreach ( $syms as $idx => $sym ) {
  if ( !skip_sym($sym) ) {
    try {
      $aptID = find_aptEntry($sym);
      if ( !is_writeable_apt($aptEntries[$aptID]) )
      {
        echo "Error: ".$sym['sym']." at location ( 0x".$sym['addr'].") is located in a read-only APT entry\n";
      } else {
        $checkCount++;
      }
    }
    catch (Exception $e) {
      echo "Error: Failed to find page table entry for ".$sym['sym']." at 0x".$sym['addr']."\n";
    }
  } else {
    // echo "Ignoring ".$sym['sym']."\n";
  }
}
echo "$checkCount symbols checked\n";

function skip_sym($sym) {
  if ( $sym['addr'] == "0x00000000" )
    return true;
  // Typically linker planted start/end labels
  switch ( $sym['sym'] ) {
    case "__MCAPI_arm_end":
    case "__MCAPI_sharc1_start":
    case "__MCAPI_sharc1_end":
    case "__MCAPI_sharc0_start":
    case "__l2_cached_end":
    case "__l2_end":
      return true;
  }
  return false;
}

function is_writeable_apt($apt) {
  global $ID_CORE0;
  if ( !$apt['flagProperties']['core'] & $ID_CORE0 )
    return false;
  return ( !isset($apt['flagProperties']['readOnly']) );
}

function find_aptEntry($sym) {
  global $aptEntries;
  $trace = false;
  $addr = "0x".$sym['addr'];
  if ( $trace )
    echo "Trying to match sym at $addr\n";
  foreach ( $aptEntries as $idx => $apt ) {
    $start = "0x".$apt['start'];
    $end = "0x".$apt['end'];
    if ( $trace )
      echo "$start:$end\n";
    if ( $addr >= $start && $addr <= $end ) {
      if ( $trace )
        echo "        MATCH!!\n";
      return $idx;
    }
  }
  throw New Exception("Failed to find APT range");
}

function parse_flags($flags) {
  /* TODO : Parse the bits in the flags and work it out cleanly */
  global $ID_CORE0, $ID_CORE1, $ID_CORE2;
  $res = array();
  switch ( $flags ) {
    case "00000c04":
      $res['desc'] = "RW_DEVICE";
      $res['core'] = ($ID_CORE0 | $ID_CORE1 | $ID_CORE2);
    break;
    case "00000c00":
      $res['desc'] = "RW_STRONGLY_ORDERED";
      $res['core'] = ($ID_CORE0 | $ID_CORE1 | $ID_CORE2);
    break;
    case "00001c00":
      $res['desc'] = "RW_UNCACHED";
      $res['core'] = ($ID_CORE0);
    break;
    case "00009c00":
      $res['desc'] = "RO_UNCACHED";
      $res['core'] = ($ID_CORE1 | $ID_CORE2);
      $res['readOnly'] = 'y';
    break;
    case "00005c04":
      $res['desc'] = "WB_CACHED";
      $res['core'] = ($ID_CORE0);
    break;
    case "0000dc04":
      $res['desc'] = "RO_CACHED";
      $res['readOnly'] = 'y';
      $res['core'] = ($ID_CORE0);
    break;
    default:
      $res['readOnly'] = 'y';
      echo "Error: Unknown Flags: $flags\n";
      exit(-1);
    break;
  }
  return $res;
}

function get_accessible_cores($mask) {
  global $ID_CORE0, $ID_CORE1, $ID_CORE2;
  $str = "";
  if ( $mask & $ID_CORE0 )
    $str.= " ARM core ";
  if ( $mask & $ID_CORE1 )
    $str .= " SHARC core 1 ";
  if ( $mask & $ID_CORE2 )
    $str .= " SHARC core 2 ";
  return $str;
}

function  add_apt_entry($start, $end, $flags) {
  global $entryCount, $aptEntries;

  echo "[$entryCount] [ 0x$start - 0x$end ] ($flags) ";
  $flagProperties = parse_flags($flags);
  if ( isset($flagProperties['readOnly']))
    echo "Read-only";
  else
    echo "Read-write";
  echo ": ".get_accessible_cores($flagProperties['core'])."\n";
  $entry = array();
  $entry['start'] = $start;
  $entry['end'] = $end;
  $entry['flags'] = $flags;
  $entry['flagProperties'] = $flagProperties;
  $aptEntries[] = $entry;
  $entryCount++;
}

function deword($str) {
  $res = $str[6].$str[7].$str[4].$str[5].$str[2].$str[3].$str[0].$str[1];
  return $res;
}
?>
