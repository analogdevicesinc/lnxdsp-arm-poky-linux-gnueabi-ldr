#!/usr/bin/env php
<?php
/* 
 * Copyright (c) 2014, Analog Devices, Inc.  All rights reserved.

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

/* Script to simplify the submitting of diffs to reviewboard.
** By default the script does a diff of the entire repository.
** If you provide arguments, it will only diff those items.
** By default the diff is against your local repository.
** If you add the -o switch, the diff is against origin/<your branch>.
** -f allows you to provide a diff file.
*/

$postCommand = "post-review";
$server = "http://reviewboard.spd.analog.com";
$username = getenv("LOGNAME");
$group = "GNUToolchain";
$repository = "http://edin-git.spd.analog.com/git/gnu-arm.git";
$branch = exec("git branch -v | grep \"^\\*\" | awk '{ print $2}'");
echo "Working with branch: $branch\n";
$toDiff = false;
$diffOrigin = false;
$diffFile = false;
$summary  = false;
$description = false;
$publish = false;
$tars = false;
$i = 1;
while ( $i < $argc ) {
  switch ( $argv[$i] ) {
    case "-help":
    case "--help":
    case "-?":
      help();
    break;
    case "-p":
      $publish = true;
    break;
    case "-tars":
      $i++;
      if ( $i == $argc ) {
        die("-tars requires a list of tars\n");
      }
      $tars = $argv[$i];
    break;
    case "-d":
      $i++;
      if ( $i == $argc ) {
        die("-d requires a description\n");
      }
      $description = $argv[$i];
    break;
    case "-s":
      $i++;
      if ( $i == $argc ) {
        die("-s requires a summary\n");
      }
      $summary = $argv[$i];
    break;
    case "-o":
      $diffOrigin = true;
    break;
    case "-f":
      $i++;
      if ( $i == $argc ) {
        die("Error: -f requires a filename as an argument\n");
      }
      $diffFile = $argv[$i];
      if ( !file_exists($diffFile) ) {
        die("Error: $diffFile does not exist\n");
      }
    break;
    default:
      if ( $toDiff === false ) {
        $toDiff = array();
      }
      $toDiff[] = $argv[$i];
    break;
  }
  $i++;
}
if ( $summary === false ) {
  die("Please provide a summary via the -s switch\n");
}
if ( $description === false &&  $publish === true ) {
  die("Error: You can only auto-publish the diff if you provide a description (-d)\n");
}

if ( $diffFile !== false ) {
  echo "Will use diff reported in $diffFile\n";
} else {
  if ( $toDiff === false ) {
    echo "Will diff against entire repo\n";
  } else {
    echo "Will only diff ".implode(" ",$toDiff)."\n";
  }
}
if ( $diffOrigin === false ) {
  echo "Will diff against local repo\n";
} else {
  echo "Will diff against the origin server\n";
}

/* Make the diff if required */
if ( $diffFile === false ) {
  $diffFile = ".srdiff.diff";
  echo "Preparing the diff...\n";
  $command = "git diff --full-index";
  if ( $diffOrigin ) {
    $command .= " origin/$branch";
  }
  if ( $toDiff !== false ) {
    $command .= " ".implode(" ",$toDiff);
  }
  $command .= " > $diffFile";
  $out = array();
  $res = 0;
  exec($command,$out,$res);
  if ( $res !== 0 ) {
    echo "Something went wrong producing your diff:\n";
    echo "$command\n";
    print_r($out);
    echo "\nreturned $res\n";
    die("Halting\n");
  }
}

/* Punt the review up to reviewboard. */
$command = "$postCommand --server=$server -d --target-groups=$group --diff-filename=$diffFile --repository-url=$repository --summary=\"$summary\" --branch=$branch --target-groups=\"CodeGenBlue\"";
if ( $description !== false ) {
  $command .= " --description=\"$description\"";
}
if ( $publish === true ) {
  $command .= " -p";
}
if ( $tars !== false ) {
  $command .= " --bugs-closed=\"$tars\"";
}
$out = array();
$res = 0;
exec($command, $out, $res);
if ( $res != 0 ) {
  echo "Something went wrong posting your diff:\n";
  echo $command."\n";
  print_r($out);
  echo "\nReturned $res\n";
  exit(-1);
}

if ( $description === false ) {
  echo "No description was provided. You will need to open reviewboard and add one before you can publish the review.\n";
}


function help() {
  echo "-p - publish the review. Requires a description.\n";
  echo "-tars <tars>- list of bugs fixed\n";
  echo "-d <d>- description\n";
  echo "-s <s> - summary\n";
  echo "-o - diff against origin. Otherwise local repo\n";
  echo "-f <f> - use file for diff\n";
  echo "All other arguments are items to diff. Otherwise whole repo is diff'd\n";
  exit(0);
}

?>
