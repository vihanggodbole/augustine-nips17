#!/bin/bash

EXPERIMENTS='friendship jester nell-kgi epinions party-affiliation party-affiliation-scaling collective-classification'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
