#!/bin/bash -e

# Script for updating part headers with their originals in the complib
# repository. It pushes to a feature branch for review.
#
# This is intended for invocation from a Jenkins job, whereby the following
# variables are expected to be set:
# - WORKSPACE: The job's workspace.
# - BRANCH: The branch to sync. Assumed to be the same for both repositories.
#
# When making changes to the set of files copied here, remember to reflect
# them in adi_include.mk. The script does not delete files, so files that are
# no longer synced need to be removed manually.

branch=${BRANCH:-master}
feature_branch=feature/update_part_headers/${branch}

cd ${WORKSPACE}/gnu-arm

gnu="${WORKSPACE}/gnu-arm/src/adi_includes/include/adi"
dsplib="${WORKSPACE}/complib/DSPLIB/LIBC/include/platform/21k_211xx"

# Helper for copying a header and applying a license to it 
cp_lic() {
  cp ${dsplib}/$1 ${gnu}/$2
  scripts/licenser.sh ${gnu}/$2/$(basename $1)
}

echo "Updating the ADSP-SC5xx headers on ${branch}"

SUPPORTED_A5_PARTS="
  SC582 SC583 SC584 SC587 SC589
  SC570 SC571 SC572 SC573
  SC591 SC591W SC592 SC592W SC593W SC594 SC594W
"

SUPPORTED_A55_PARTS="
  SC595 SC595W SC596 SC596W SC598 SC598W
"

YODA_GENERATED_A5_PARTS="
  SC571 SC573
  SC584 SC587 SC589
  SC592 SC592W SC593W SC594 SC594W
"

YODA_GENERATED_A55_PARTS="
  SC596 SC596W SC598 SC598W
"

## copy def, cdef, typedef and device wrapper includes and update the copyrights
for PART in ${SUPPORTED_A5_PARTS}; do
  cp_lic def${PART}.h cortex-a5
  cp_lic cdef${PART}.h cortex-a5
  cp_lic ADSP-${PART}_typedefs.h cortex-a5
  cp_lic ADSP-${PART}_device.h cortex-a5
done
for PART in ${SUPPORTED_A55_PARTS}; do
  cp_lic def${PART}.h cortex-a55
  cp_lic cdef${PART}.h cortex-a55
  cp_lic ADSP-${PART}_typedefs.h cortex-a55
  cp_lic ADSP-${PART}_device.h cortex-a55
done

## The part-specific Yoda headers in the sys directory
for PART in ${YODA_GENERATED_A5_PARTS}; do
  if [[ ${PART} == SC59* ]]; then SEP=-; else SEP=_; fi
  cp_lic sys/ADSP${SEP}${PART}.h cortex-a5/sys
  cp_lic sys/ADSP${SEP}${PART}_cdef.h cortex-a5/sys
  cp_lic sys/ADSP${SEP}${PART}_device.h cortex-a5/sys
  cp_lic sys/ADSP${SEP}${PART}_typedefs.h cortex-a5/sys
done
for PART in ${YODA_GENERATED_A55_PARTS}; do
  cp_lic sys/ADSP-${PART}.h cortex-a55/sys
  cp_lic sys/ADSP-${PART}_cdef.h cortex-a55/sys
  cp_lic sys/ADSP-${PART}_device.h cortex-a55/sys
  cp_lic sys/ADSP-${PART}_typedefs.h cortex-a55/sys
done

## Remember the device/typedef generic headers
cp_lic ADSP-SC58x_device.h cortex-a5
cp_lic ADSP-SC58x_typedefs.h cortex-a5
cp_lic ADSP-SC57x_device.h cortex-a5
cp_lic ADSP-SC57x_typedefs.h cortex-a5
cp_lic ADSP-SC59x_device.h cortex-a5
cp_lic ADSP-SC59x_typedefs.h cortex-a5
cp_lic ADSP-SC59x_device.h cortex-a55
cp_lic ADSP-SC59x_typedefs.h cortex-a55

## copy wrapper used core and legacy support files (new in CCES 2.1.0, renamed
## in 2.3.0)
cp_lic sys/ADSP_SC5xx_legacy.h cortex-a5/sys
cp_lic sys/ADSP_SC5xx_legacy.h cortex-a55/sys

# Then older files that we need to keep
cp_lic sys/ADSP-SC589_device.h cortex-a5/sys

## copy misc other includes
cp_lic sys/addr_t.h cortex-a55/sys
cp_lic cdefSC58x_rom.h cortex-a5
cp_lic adi_rom_typedef.h cortex-a5
cp_lic adi_rom_typedef.h cortex-a55
cp_lic cdefSC58x_rom_otpLayout.h cortex-a5
cp_lic defSC58x_rom.h cortex-a5
cp_lic defSC58x_rom_jumptable.h cortex-a5
cp_lic sruSC589.h cortex-a5

cp_lic sys/defSC57x_id_macros.h cortex-a5/sys
cp_lic sys/defSC58x_id_macros.h cortex-a5/sys
cp_lic sys/defSC59x_id_macros.h cortex-a5/sys
cp_lic sys/defSC59x_id_macros.h cortex-a55/sys

cp_lic sys/anomaly_macros_rtl.h sys
cp_lic sys/internal_system_prototypes.h cortex-a5/sys
cp_lic sys/internal_system_prototypes.h cortex-a55/sys
cp_lic sru.h cortex-a5
cp_lic sru.h cortex-a55

cp_lic cdefSC57x_rom.h cortex-a5
cp_lic cdefSC57x_rom_otpLayout.h cortex-a5
cp_lic defSC57x_rom.h cortex-a5
cp_lic defSC57x_rom_jumptable.h cortex-a5
cp_lic sruSC573.h cortex-a5

cp_lic cdefSC59x_rom.h cortex-a5
cp_lic cdefSC59x_rom_otpLayout.h cortex-a5
cp_lic cdefSC594_family_rom_otpLayout.h cortex-a5
cp_lic defSC59x_rom.h cortex-a5
cp_lic defSC59x_rom_jumptable.h cortex-a5
cp_lic sruSC594.h cortex-a5

cp_lic cdefSC59x_rom.h cortex-a55
cp_lic cdefSC59x_rom_otpLayout.h cortex-a55
cp_lic cdefSC598_family_rom_otpLayout.h cortex-a55
cp_lic defSC59x_rom.h cortex-a55
cp_lic defSC59x_rom_jumptable.h cortex-a55
cp_lic sruSC598.h cortex-a55
cp_lic sruSC594.h cortex-a55  #sruSC598.h includes sruSC594.h

cd ${gnu}

rm -f cortex-a{5,55}/*.tmp cortex-a{5,55}/sys/*.tmp sys/*.tmp

# check in the files if required
if [[ -z $(git status -s .) ]]
then
  echo "NO CHANGES TO BE COMMITTED"
  exit 0
fi

echo
echo "Committing updated files"
complib_commit=$(cd $dsplib; git rev-parse --short=8 HEAD)
git add cortex-a{5,55}/*.h cortex-a{5,55}/sys/*.h sys/*.h
git status -s .
git commit -m "Update part headers to complib commit ${complib_commit} on branch ${branch}."

echo
echo "Pushing to ${feature_branch}"
git push origin +HEAD:refs/heads/${feature_branch}

echo
echo "Please click this link to create a pull request for merging to ${branch}:"
echo "https://bitbucket.analog.com/projects/DTE/repos/gnu-arm-toolchain/compare/diff?targetBranch=${branch}&sourceBranch=${feature_branch}"
exit 1
