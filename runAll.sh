#!/bin/bash

EXPERIMENTS='friendship party-affiliation-scaling collective-classification epinions jester nell-kgi image-reconstruction'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
