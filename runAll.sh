#!/bin/bash

EXPERIMENTS='collective-classification epinions jester nell-kgi party-affiliation-scaling friendship'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
