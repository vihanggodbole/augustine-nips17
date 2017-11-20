#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_GEN_SCRIPT="${THIS_DIR}/scripts/generateFriendshipData.rb"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -w -s ' ' 100 100 2000`

   for fold in $folds; do
      # Generate the data.
      ruby $DATA_GEN_SCRIPT -p $fold -l 10 -fh 0.85 -fl 0.15 -n friendship
      local dataDir="${THIS_DIR}/data/friendship_${fold}_0010"

      # PSL
      psl::runSuite \
         'friendship' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '-ec -ed 0.5' \
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
