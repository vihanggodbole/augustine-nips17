#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -s ' ' 0 7`

   for fold in $folds; do
      # PSL 2.1 (H2)
      psl::runLearn \
         "${outBaseDir}/psl/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec 0.5' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 (Postgres)
      psl::runLearn \
         "${outBaseDir}/psl-postgres/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '--postgres psl' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-postgres/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-postgres/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '--postgres psl -ec 0.5' \
         "${PSL_JAR_PATH}"

      # PSL 2.0
      psl::runLearn \
         "${outBaseDir}/psl-2.0/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '' \
         "${PSL2_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-2.0/${fold}" \
         'epinions' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl-2.0/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec 0.5' \
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
