#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_GEN_SCRIPT="${THIS_DIR}/scripts/generateFriendshipData.rb"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   # TEST
   # local folds=`seq -w -s ' ' 100 100 2000`
   local folds='1000'

   for fold in $folds; do
      # Generate the data.
      ruby $DATA_GEN_SCRIPT -p $fold -l 10 -fh 0.85 -fl 0.15 -n friendship
      local dataDir="${THIS_DIR}/data/friendship_${fold}_0010"

      # PSL 2.1 ADMM (H2)
      psl::runEval \
         "${outBaseDir}/psl-admm-h2/${fold}" \
         'friendship' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/friendship.psl" \
         '-ec -ed 0.5' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 ADMM (Postgres)
      psl::runEval \
         "${outBaseDir}/psl-admm-postgres/${fold}" \
         'friendship' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/friendship.psl" \
         '-ec -ed 0.5 --postgres psl' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (Postgres)
      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-postgres/${fold}" \
         'friendship' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/friendship.psl" \
         "-ec -ed 0.5 --postgres psl `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (H2)
      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-h2/${fold}" \
         'friendship' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/friendship.psl" \
         "-ec -ed 0.5 `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.0
      psl::runEval \
         "${outBaseDir}/psl-2.0/${fold}" \
         'friendship' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/friendship.psl" \
         '-ec -ed 0.5' \
         "${PSL2_JAR_PATH}"

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
