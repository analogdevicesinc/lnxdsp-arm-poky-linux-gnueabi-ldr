# Copyright (c) 2014, Analog Devices, Inc.  All rights reserved.
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

#set -x

rdom () { local IFS=\> ; read -d \< E C ;}

if [ $# -lt 1 ] ; then
  echo "Need test path as parameter, e.g. arm-none-qemu-griffin"
  exit 1
fi

# Where the test results live
res_dir="testresults/$1"
# Where we put the Jenkins compatible XML
results="$res_dir/jenkins.junit"

# Add the Header
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $results
echo "<testsuites>" >> $results

# For each test result, we add a new "testsuite"
for f in $res_dir/*.xml
do
temp="${f}.in"
cp $f $temp

# DeJaGnu's XML contains XML special characters, which is really stupid.
# This catches all the cases I can think of.
sed -i -e "/<name>/ s/&/\&amp;/g" $temp
sed -i -e "/<name>/ s/\"/\&quot;/g" $temp
sed -i -e "/<name>/ s/\'/\&#39;/g" $temp
sed -i -e "/<name>/ s/<</\&lt;\&lt;/g" $temp
sed -i -e "/<name>/ s/<\([^n\/][^an]\)/\&lt;\1/g" $temp
sed -i -e "/<name>/ s/>>/\&gt;\&gt;/g" $temp
sed -i -e "/<name>/ s/\([^m][^e]\)>/\1\&gt;/g" $temp

# Name the testsuite after the original xml file.
echo "<testsuite name=\"$f\">" >> $results

sum=0
fail=0
# Simple parser of each XML block.
while rdom; do
#  echo "$E => $C"
  if [ $sum -eq 0 ]; then
    if [ "$E" == "test" ] ; then
      echo -n "<testcase " >> $results
    fi
    if [ "$E" == "result" ] ; then
      if [ "$C" == "UNSUPPORTED" ] ; then
        echo -n "status=\"skipped\" " >> $results
      else
        echo -n "status=\"`echo ${C,,}`\" " >> $results
      fi
      if [ "$C" == "FAIL" ] ; then
        fail=1
      fi
    fi
    if [ "$E" == "name" ] ; then
      echo -n "name=\"$C\"" >> $results
      if [ $fail -eq 0 ]; then
        echo " />" >> $results
      else
        fail=0
        echo ">" >> $results
        echo "<failure type=\"Compilation or Runtime Failure\" message=\"Please refer to the log file\"/>" >> $results
        echo "</testcase>" >> $results
      fi
    fi
# Once we hit the summary section, consider ourselves done for just now.
    if [ "$E" == "summary" ] ; then
      sum=1
    fi
  fi
done < $temp
echo "</testsuite>" >> $results

done
echo "</testsuites>" >> $results
rm $temp
