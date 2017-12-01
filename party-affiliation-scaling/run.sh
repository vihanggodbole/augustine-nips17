#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_GEN_SCRIPT="${THIS_DIR}/scripts/generateGraphData.rb"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -w -s ' ' 100000 100000 1000000`

   for fold in $folds; do
      # Generate the data.
      echo "Generating data for ${fold} nodes."
      local dataDir="${THIS_DIR}/data/processed/${fold}"
      ruby $DATA_GEN_SCRIPT $fold "${dataDir}"

      # PSL
      psl::runSuite \
         'party-affiliation' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '' \
         false
      
      # Tuffy
      tuffy::runEval \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${dataDir}" \
         "${THIS_DIR}/mln/prog.mln"
   done
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
