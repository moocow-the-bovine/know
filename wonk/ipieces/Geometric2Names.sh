#!/bin/sh

USAGE="$0 <color1> <color2>"
if [ $# -lt 1 ] ; then
  echo "Usage: $USAGE"
  exit 1
fi
color1=$1
color2=$2

# naming
mmv -rv "*-$color1.*" '#1-1.#2'
mmv -rv "*-$color2.*" '#1-2.#2'

mmv -rv 'sphere-*' 'bard#1'
mmv -rv 'cone-*' 'fool#1'
mmv -rv 'cylinder-*' 'herald#1'

# striping
mmv -rv '*.gif' '#1a.gif'
mcp -v '*a.gif' '#1b.gif'
