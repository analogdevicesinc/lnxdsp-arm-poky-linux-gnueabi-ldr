# Copyright (c) 2014-2019, Analog Devices, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted (subject to the limitations in the
# disclaimer below) provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the
#    distribution.
#
# * Neither the name of Analog Devices, Inc.  nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
# GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
# HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This file is used to automatically alter the copyright on Jenkins imported
# files to use the Clear BSD text.

##set -x

# ensure clear_bsd.txt exists and is non-zero size
if [ ! -s scripts/clear_bsd.txt ] ; then
  echo "error - scripts/clear_bsd.txt is missing"
  exit 1
fi

files=$*
failed=0

for file in ${files} ; do
  if [ `grep --count "Copyright.*All [rR]ights [rR]eserved" $file` -eq 0 ] ; then
    echo "error - can't find the Copyright notice in ${file}"
    failed=$((failed + 1))
  fi
  ext=`echo $file | sed -e "s/.*\.//g"`
  case ${ext} in
    h)
      echo "Adding C-style License to $file"
      sed -i '# Put the license text on the line after the Copyright notice
              /Copyright.*All [rR]ights [rR]eserved/r scripts/clear_bsd.txt
              # Drop anything after "Reserved" on copyright line
              /Copyright/s/Reserved\..*/Reserved./
              # Delete proprietary and confidential statement
              /software is proprietary \(and\|&\) confidential/N
              /software is proprietary \(and\|&\) confidential.*\n.*/d
              ' ${file}
      ;;

    xml)
      echo "Adding XML-style License to $file"
      sed -i '# Put the license text on the line after the Copyright notice
              /Copyright.*All [rR]ights [rR]eserved/{
                a<!--
                r scripts/clear_bsd.txt
                a-->
              }' ${file}
      ;;

    *) echo "error - unknown extension ${ext} for ${file}"
       failed=$((failed + 1))
      ;;
  esac
done

exit ${failed}
