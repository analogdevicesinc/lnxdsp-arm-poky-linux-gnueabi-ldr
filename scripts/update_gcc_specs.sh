#!/bin/bash
export compiler=$1
echo "Compiler: $compiler"
libgccfile=`$compiler -print-libgcc-file-name`
SPECSFILE=`dirname $libgccfile`/specs
topLevel=`which $compiler`
topLevel=`dirname $topLevel`
topLevel=`dirname $topLevel`
echo "Toolchain installed in $topLevel"
echo "Writing GCC specs file: $SPECSFILE"
$compiler -dumpspecs  | sed -e 's@/lib\(64\)\?/ld@/'$topLevel'&@g' -e "/^\*cpp:$/{n;s,$, -isystem "$topLevel"/include,}" > $SPECSFILE
