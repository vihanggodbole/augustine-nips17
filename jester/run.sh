#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -s ' ' 0 9`

   for fold in $folds; do
      # PSL 2.1 ADMM (H2)
      psl::runLearn \
         "${outBaseDir}/psl-admm-h2/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-admm-h2/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-admm-h2/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 ADMM (Postgres)
      psl::runLearn \
         "${outBaseDir}/psl-admm-postgres/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '--postgres psl' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-admm-postgres/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-admm-postgres/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '--postgres psl -ec' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (H2)
      psl::runLearn \
         "${outBaseDir}/psl-maxwalksat-h2/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         "`psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-h2/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-maxwalksat-h2/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         "-ec `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (Postgres)
      psl::runLearn \
         "${outBaseDir}/psl-maxwalksat-postgres/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         "--postgres psl `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-postgres/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-maxwalksat-postgres/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         "--postgres psl -ec `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.0
      psl::runLearn \
         "${outBaseDir}/psl-2.0/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '' \
         "${PSL2_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-2.0/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-2.0/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec' \
         "${PSL2_JAR_PATH}"

      # Tuffy
      tuffy::runLearn \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/splits/${fold}/learn"

      tuffy::runEval \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/splits/${fold}/eval" \
         "${outBaseDir}/tuffy/${fold}/${LEARNED_MLN_MODEL_FILENAME}"
   done
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
