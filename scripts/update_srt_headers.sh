#!/bin/bash -e

# Script for updating SRT headers with their originals in CCES stage svn.
# It pushes to a feature branch for review.
#
# This is intended for invocation from a Jenkins job, whereby the following
# variables are expected to be set:
# - WORKSPACE: The job's workspace.
# - BRANCH: The branch to sync to.
# - CCES_VERSION: The CCES version of the stage checkout.
# - SVN_REVISION: The svn revision of stage. Set automatically by Jenkins.
#
# When making changes to the set of files copied here, remember to reflect
# them in adi_include.mk. The script does not delete files, so files that are
# no longer synced need to be removed manually.

branch=${BRANCH:-master}
feature_branch=feature/update_srt_headers/${branch}

cd ${WORKSPACE}/gnu-arm

gnu="${WORKSPACE}/gnu-arm/src/adi_includes/include/adi"
stage="${WORKSPACE}/stage"

# Helper for copying a header and applying a license to it
cp_lic() {
  cp ${stage}/$1 ${gnu}/cortex-a5/$1
  scripts/licenser.sh ${gnu}/cortex-a5/$1
  cp ${gnu}/cortex-a5/$1 ${gnu}/cortex-a55/$1
}

cp_lic adi_osal.h
cp_lic adi_osal_arch.h
cp_lic runtime/mmu/adi_mmu.h

# Check whether there are changes
cd ${gnu}
if [[ -z $(git status -s .) ]]
then
  echo "NO CHANGES TO BE COMMITTED"
  exit 0
fi

echo
echo "Committing updated files"
git add .
git status -s .
git commit -m "Update SRT headers to CCES ${CCES_VERSION} stage r${SVN_REVISION}."

echo
echo "Pushing to ${feature_branch}"
git push origin +HEAD:refs/heads/${feature_branch}

echo
echo "Please click this link to create a pull request for merging to ${branch}:"
echo "https://bitbucket.analog.com/projects/DTE/repos/gnu-arm-toolchain/compare/diff?targetBranch=${branch}&sourceBranch=${feature_branch}"
exit 1
