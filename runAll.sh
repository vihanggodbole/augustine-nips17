#!/bin/bash

EXPERIMENTS='jester nell-kgi party-affiliation-scaling party-affiliation friendship epinions collective-classification'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
