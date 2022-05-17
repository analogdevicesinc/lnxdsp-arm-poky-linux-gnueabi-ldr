#!/bin/bash -e

# Script for updating compiler XMLs with their originals in the compiler-xml
# repository. It pushes to a feature branch for review.
#
# This is intended for invocation from a Jenkins job, whereby the following
# variables are expected to be set:
# - WORKSPACE: The job's workspace.
# - BRANCH: The branch to sync. Assumed to be the same for both repostories.
#
# When making changes to the set of files copied here, remember to reflect
# them in scripts/adi_parts_config/CCES/processor_xml_list.php.
# The script does not delete files, so files that are no longer synced need
# to be removed manually.

branch=${BRANCH:-master}
feature_branch=feature/update_compiler_xmls/${branch}

gnu="${WORKSPACE}/gnu-arm"
xml="${WORKSPACE}/crosscommon-xml"

# Remove the existing XML files and copy in the current ones
cd ${gnu}/src/proc-defs/XML/ArchDef
rm *.xml
cp ${xml}/ArchDef/ADSP-SC*-compiler.xml .

# Patch licenses
cd ${gnu}
scripts/licenser.sh src/proc-defs/XML/ArchDef/ADSP-SC*-compiler.xml

# check in the files if required
cd ${gnu}/src/proc-defs/XML/ArchDef
if [[ -z $(git status -s .) ]]
then
  echo "NO CHANGES TO BE COMMITTED"
  exit 0
fi

echo
echo "Committing updated files"
xml_commit=$(cd ${xml}; git rev-parse --short=8 HEAD)
git add *-compiler.xml
git status -s .
git commit -m "Update compiler XMLs to crosscommon-xml commit ${xml_commit} on branch ${branch}."

echo
echo "Pushing to ${feature_branch}"
git push origin +HEAD:refs/heads/${feature_branch}

echo
echo "Please click this link to create a pull request for merging to ${branch}:"
echo "https://bitbucket.analog.com/projects/DTE/repos/gnu-arm-toolchain/compare/diff?targetBranch=${branch}&sourceBranch=${feature_branch}"
exit 1
