#!/bin/bash

EXPERIMENTS='collective-classification party-affiliation-scaling epinions jester nell-kgi friendship party-affiliation'

trap exit SIGINT

for experiment in $EXPERIMENTS; do
   pushd . > /dev/null
   cd "${experiment}"
   ./run.sh
   popd > /dev/null
done
