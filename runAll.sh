#!/bin/bash

EXPERIMENTS='collective-classification epinions friendship image-reconstruction jester nell-kgi party-affiliation'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
