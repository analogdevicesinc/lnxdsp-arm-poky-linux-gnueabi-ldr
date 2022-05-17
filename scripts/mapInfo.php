#!/usr/bin/env php
<?php

$isLinux = (strncasecmp(PHP_OS, "WIN", 3) != 0);

$i = 1;
$gcc = false;
$coreArg = false;
$procArg = false;
$revArg = false;
$testcase = false;
$cflags = "";
/* Set to true if you want to see all the stuff from NM */
$showAllSymbols = false;
$mapArg = false;
$exeArg = false;
$mapOnly = false;

while ( isset($argv[$i])  ) {
  switch ( $argv[$i] ) {
    case "-map":
      $i++;
      $mapArg = $argv[$i];
    break;
    case "-exe":
      $i++;
      $exeArg = $argv[$i];
    break;
    case "-gcc":
      $i++;
      $gcc = $argv[$i];
    break;
    case "-core":
      $i++;
      $coreArg = $argv[$i];
    break;
    case "-proc":
      $i++;
      $procArg = $argv[$i];
    break;
    case "-rev":
      $i++;
      $revArg =  $argv[$i];
    break;
    case "-testcase":
      $i++;
      $testcase = $argv[$i];
    break;
    case "-cflags":
      $i++;
      $cflags = $argv[$i];
    break;
    case "-maponly":
      $mapOnly = true;
    break;
    case "-nm":
      $showAllSymbols = true;
    break;
    default:
      echo "Unknown option ".$argv[$i]."\n";
      help();
    break;
  }
  $i++;
}

function help() {
  global $argv;
  echo $argv[0]." and switches\n";
  echo "-exe <executable>\n";
  echo "-map <Linker map file>\n";
  echo "-maponly  /* Don't display the stack/heap/ttbaddr checking */\n";
  echo "-gcc <compiler>\n";
  echo "-core <core>\n";
  echo "-proc <proc>\n";
  echo "-rev <rev>\n";
  echo "-cflags <cflags>\n";
  echo "-test <testcase>\n";
  echo "-nm     /* Shows all nm symbols from executable\n";
  echo "\n\n";
  echo "The script has a few ways of working. By default it will iterate over all\n";
  echo "the proc/revs and validate the mem sections in the ld scripts\n";
  echo "You can restrict this to a specific part, and compile a simple test using the\n";
  echo "-core, -proc and -rev switches\n";
  echo "Alternatively if you pass in a map file and executable, it'll take a look\n";
  echo "at those for you.\n";
  exit(-1);
}

if ( $exeArg != false || $mapArg != false ) {
  if ( $mapArg == false ) {
    echo "Examining an executable requires a map file\n";
    help();
  } else if ($exeArg == false ) {
    echo "Examining a map file requires an executable\n";
    help();
  }
  if ( $gcc == false ) {
    echo "GCC is required when passing an executable and map\n";
    help();
  }
} else {
  if ( $gcc == false ) {
    echo "Error: Requires gcc\n";
    help();
  }
  if ( $procArg != false && $coreArg == false ) {
    echo "Error: -proc requires -core\n";
    help();
  }
  if ( $revArg != false && $procArg == false ) {
    echo "Error: -rev requires -proc\n";
    help();
  }
  if ( $testcase == false ) {
    echo "Requires a testcase\n";
    help();
  }
}

function my_memcmp($a,$b) {
$res = ($a['start'] - $b['start']);
if ( $res < 0 )
  return -1;
else if  ( $res > 0 )
  return 1;
else return 0;
}

function read_mem_sections($mapfile) {
  global $isLinux;
  $f = file_get_contents($mapfile);
  $e = explode ($isLinux?"\n":"\r\n",$f);
  $memoryInfo = array();
  $memoryInfo['sections'] = array();
  $memoryInfo['hasOverlap'] = false;
  $memoryInfo['hasGaps'] = false;
  foreach ( $e as $idx => $line ) {
    if ( strncmp($line,"Memory Configuration",strlen("Memory Configuration")) == 0 ) {
      $idx +=3;
      while ( strncmp($e[$idx],"*default*",9) != 0 ) {
        $line = preg_replace('/\s+/',' ',$e[$idx]);
        $e2 = explode(" ",$line);
	$entry['name'] = $e2[0];
	$entry['start'] = base_convert($e2[1],16,10);
        $entry['start_str'] = $e2[1];
	$entry['length'] = base_convert($e2[2],16,10);
        $end = $entry['start'] + $entry['length'];
        $entry['end'] = $end;
        $entry['read_only'] = ( isset($e2[3]) && $e2[3] == 'r' ? true : false );
        $entry['overlapsNextSection'] = false;
        $entry['gapToNextSection'] = false;
        $memoryInfo['sections'][] = $entry;
	$idx++;
      }
      usort($memoryInfo['sections'],"my_memcmp");
      foreach ( $memoryInfo['sections'] as $idx => $mem ) {
        if (isset($memoryInfo['sections'][$idx+1]) && $mem['end'] > $memoryInfo['sections'][$idx+1]['start']) {
          $memoryInfo['sections'][$idx]['overlapsNextSection'] = true;
          $memoryInfo['hasOverlap'] = true;
        } else if ( isset($memoryInfo['sections'][$idx+1]) && 
                    $mem['end'] < $memoryInfo['sections'][$idx+1]['start'] &&
                    $mem['name'] != "MEM_L2_BOOT" && $mem['end'] != 0x88000000 ) {
          /* Check that this isn't a known gap */
          $memoryInfo['sections'][$idx]['gapToNextSection'] = true;
          $memoryInfo['hasGaps'] = true;
        }
      }           
    }
  }
  return $memoryInfo;
}

function print_mem_sections($memoryInfo) {
  foreach ( $memoryInfo['sections'] as $idx => $mem ) {
    $kval = $mem['length'] / 1024;
    $mval = $kval / 1024;
    printf("%24.24s  %s -> 0x%s [ length 0x%s (%d%s) ]",
           $mem['name'],$mem['start_str'],my_dechex($mem['end']),my_dechex($mem['length']),
           $mval >= 1 ? $mval : $kval, 
           $mval >= 1 ? 'M' : 'K');
    if ( $mem['overlapsNextSection'] || $mem['gapToNextSection']) {
      if ( $mem['overlapsNextSection'] ) {
        printf("  ** OVERLAP **\n");
      }
      if ( $mem['gapToNextSection'] ) {
        printf("  ** GAP **\n");
      }
    } else {
      printf("\n");
    }
  }
}

$gccProcessors = false;
$outfile = false;
$mapfile = false;
$nmfile = "nm.out";
if ( $exeArg ) { 
  /* Set up a dummy GCC processors */
  $gccProcessors['my_core']['my_proc']['revs'][] = "my_rev";
  $outfile = $exeArg;
  $mapfile = $mapArg;

} else {
  // Generate a list of processors to iterate over
  $procFile = "gccProcessors.php";
  $dummyFile = "maptest.tmp.c";
  $outfile = "a.out";
  $mapfile = "my.map";
  if ( file_exists($procFile)) {
    unlink($procFile);
  }
  $cmd = "echo \"int main() {}\" > $dummyFile && $gcc -S -mlist-processors-php $dummyFile";
  exec(bash($cmd));
  if ( !file_exists($procFile)) {
    echo "CMD: $cmd\n";
    printf("Error: Failed to include file $procFile\n");
    exit(-1);
  }
  include($procFile);
  /* Purge unwanted entries */
  if ( $coreArg != false ) {
    foreach ( $gccProcessors as $core => $coreInfo ) {
      if ( $core != $coreArg ) {
        unset($gccProcessors[$core]);
      }
    }
  }
  if ( $procArg != false ) {
    foreach ( $gccProcessors[$coreArg] as $proc => $procInfo ) {
      if ( $procArg != $proc ) {
        unset($gccProcessors[$coreArg][$proc]);
      }
    }
  }
  if ( $revArg != false ) {
    foreach ( $gccProcessors[$coreArg][$procArg]['revs'] as $idx => $rev ) {
      if ( $revArg != $rev ) {
        unset($gccProcessors[$coreArg][$procArg]['revs'][$idx]);
      }
    }
  }
}
  
  foreach ( $gccProcessors as $core => $coreInfo ) {
    foreach ( $coreInfo as $proc => $procInfo ) {
      foreach ( $procInfo['revs'] as $idx => $rev ) {
        if ( !$exeArg ) {
          echo "TESTING: $proc $rev\n";
          $cmd = "$gcc -mproc=$proc -msi-revision=$rev $testcase -o $outfile -Wl,-Map=$mapfile";
          exec(bash($cmd),$out,$res);
          if ( $res != 0 ) {
            printf("Test Failed: Failed to produce mapfile\n");
            print_r($cmd);
            print_r($out);
            exit(-1);
          }
        }
        $mem = read_mem_sections($mapfile);
        print_mem_sections($mem);
        if ( $mem['hasOverlap'] ) {
          printf("Test Failed\n");
        }
        if ( $mapOnly ) {
          continue;
        }
        /* Dump out a symbol map and determine the stack/heap size */
        echo "Checking Symbol Placement...\n";
        if ( file_exists($nmfile) ) {
          unlink($nmfile);
        }
        $command = str_replace("arm-none-eabi-gcc","arm-none-eabi-nm",$gcc).
                   " $outfile | sort > $nmfile";
        $out = array();
        $res = 0;
        exec(bash($command),$out,$res);
        if ( $res != 0 ) {
          echo "Test Failed: Failed to nm executable: $command\n";
          print_r($out);
        } else {
          $nmData = read_nm_data($nmfile);
          /* Check that all symbols are placed in sections */
          $curSectionPos = 0;
          $noMoreSections = count($mem['sections']) == 0 ? true : false ;
          $symbolsOK = 0;
          $ttbAddrPos = false;
          $heapStartPos = false;
          $heapEndPos = false;
          $heapObjPos = false;
          $sysStackObj = false;
          $sysStackStart = false;
          $sysStackEnd = false;
          $supStackObj = false;
          $supStackStart = false;
          $supStackEnd = false;
          $irqStackObj = false;
          $irqStackStart = false;
          $irqStackEnd = false;
          $fiqStackObj = false;
          $fiqStackStart = false;
          $fiqStackEnd = false;
          $abortStackObj = false;
          $abortStackStart = false;
          $abortStackEnd = false;
          $undefStackObj = false;
          $undefStackStart = false;
          $undefStackEnd = false;
          
          foreach($nmData as $idx => $sym ) {
            $done = $noMoreSections;
            /* Record the position of useful symbols for later */
            switch ( $sym['sym'] ) {
              case "__ttbaddr":
                $ttbAddrPos = $idx;
              break;
              case "__heap_start":
                $heapStartPos = $idx;
              break;
              case "__heap_end":
                $heapEndPos = $idx;
              break;
              case "__adi_heap_object":
                $heapObjPos = $idx;
              break;
            }
            /* Check all the symbols locations */
            while ( !$done ) { 
              if ( $sym['addr'] < $mem['sections'][$curSectionPos]['start'] ) {
                /* Sym is placed before our first section */
                echo "Test Failed: sym ".$sym['sym']." (".my_dechex($sym['addr']).") located before first section\n";
                $done = true;
              } else if ( $sym['addr'] >= $mem['sections'][$curSectionPos]['start'] &&
                          $sym['addr'] <  $mem['sections'][$curSectionPos]['end'] ) {
                $done = true;
                $symbolFoundInSection = true;
                $symbolsOK++;
                $nmData[$idx]['section'] = $mem['sections'][$curSectionPos]['name'];
                if ( $showAllSymbols ) {
                  echo $sym['sym']." (".my_dechex($sym['addr']).") in section ".
                       $mem['sections'][$curSectionPos]['name']."\n";
                }
              } else {
                /* Symbol > end of section, try next section */
                $curSectionPos++;
                if ( !isset($mem['sections'][$curSectionPos]) ) {
                  echo "Test Failed: sym ".$sym['sym']." not placed in a section\n";
                  $noMoreSections = true;
                  $done = true;
                }
              }
            }
          }
          echo "$symbolsOK symbols found in declared sections\n";
          echo "\nExamining the ttbaddr config for the MMU:\n";
          if ( $ttbAddrPos == false ) {
            echo "Test Failed: __ttbaddr symbol not found\n";
          } else {
            /* Check that ttbaddr fits in the section and is correctly aligned */
            $ttbExpectedAlignment = 1024 * 16;
            $ttbAddr = base_convert($nmData[$ttbAddrPos]['addr'],10,16);
            $modVal = $ttbAddr % $ttbExpectedAlignment;
            if ( $modVal != 0 ) {
              echo "Test Failed: __ttbaddr is not aligned to the expected boundary\n";
              echo "     Addr: 0x".my_dechex($nmData[$ttbAddrPos]['addr'])."(".$nmData[$ttbAddrPos]['addr'].")\n";
              echo "alignment: 0x".my_dechex($ttbExpectedAlignment)."($ttbExpectedAlignment)\n";
              echo "   modVal: 0x".my_dechex($modVal)."($modVal)\n";
            } else {
              echo "__ttbaddr aligned as expected\n";
              echo "__ttbaddr start: 0x".my_dechex($nmData[$ttbAddrPos]['addr'])."\n";
              echo "  __ttbaddr_end: 0x".my_dechex($nmData[$ttbAddrPos]['addr']+$ttbExpectedAlignment)."\n";
              echo "        section: ".$nmData[$ttbAddrPos]['section']."\n";
            }
          }
          echo "\nExamining the heap config:\n";
          if ( $heapStartPos == false ) {
            echo "Test Failed: Did not find the __adi_heap_start symbol\n";
          } else if ( $heapEndPos == false ) {
            echo "Test Failed: Did not find the __adi_heap_end symbol\n";
          } else if ( $heapObjPos == false ) {
            echo "I did not find a heap object in your application\n";
            if ( $nmData[$heapStartPos]['addr'] == $nmData[$heapEndPos]['addr'] ) {
              echo "I'm assuming that since heap start and heap end symbs have the same address that this\n";
              echo "is just an application with no heap usage. **** PLEASE CHECK THIS ****\n";
            } else {
              echo "But there's something else in your heap section?!\n";
            }
          } else {
            echo "Heap start: 0x".my_dechex($nmData[$heapStartPos]['addr'])."\n";
            echo "  Heap obj: 0x".my_dechex($nmData[$heapObjPos]['addr'])."\n";
            echo "  Heap end: 0x".my_dechex($nmData[$heapEndPos]['addr'])."\n";
            echo "   section: ".$nmData[$heapStartPos]['section']."\n";
            $decHS = base_convert($nmData[$heapStartPos]['addr'],16,10);
            $decHE = base_convert($nmData[$heapEndPos]['addr'],16,10);
            $heapSize = $nmData[$heapEndPos]['addr'] - $nmData[$heapStartPos]['addr'];
            echo " Heap size: $heapSize bytes (0x".dechex($heapSize).")\n";
            if ( $nmData[$heapStartPos]['addr'] != $nmData[$heapObjPos]['addr'] ) {
              echo "Test Failed: heap start and heap object are at different locations\n";
            }
          }
        }
      }
    }
  }

function read_nm_data($nmfile) {
  /*  Assumption that the nm output has already been sorted */
  global $isLinux;
  $nmData = array();
  $f = file_get_contents($nmfile);
  $e = explode($isLinux?"\n":"\r\n",$f);
  foreach ( $e as $idx => $line ) {
    if ( strlen($line) > 0 && ctype_xdigit($line[0])) {
      $e2 = explode(" ",$line);
      $entry['addr'] = base_convert($e2[0],16,10);
      $entry['sym'] = $e2[2];
      if ( $entry['addr'] == 0 && $entry['sym'] == "shift" ) {
        // skip it
      } else {
        $nmData[] = $entry;
      }
    }
  }
  return $nmData;
}

function bash($cmd) {
  global $isLinux;

  if ( $isLinux ) {
    return $cmd;
  }
  $cwd = getcwd();
  $bash = "c:/cygwin/bin/bash.exe";
  $bCmd = $bash." -c \" $cmd ";
  $bCmd .="\"";
  return $bCmd;
}

function my_dechex($val) {
  /* Theirs is buggy with large values */
  return base_convert((string)$val,10,16);
}
?>
