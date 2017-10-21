#!/bin/sh

EXPERIMENTS='collective-classification epinions image-reconstruction jester party-affiliation'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
