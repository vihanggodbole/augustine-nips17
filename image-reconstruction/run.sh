#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='caltech olivetti'

   for dataset in $datasets; do
      # PSL 2.1 ADMM (H2)
      psl::runLearn \
         "${outBaseDir}/psl-admm-h2/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         '' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-admm-h2/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl-admm-h2/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 ADMM (Postgres)
      psl::runLearn \
         "${outBaseDir}/psl-admm-postgres/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         '--postgres psl' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-admm-postgres/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl-admm-postgres/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         '--postgres psl -ec' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (H2)
      psl::runLearn \
         "${outBaseDir}/psl-maxwalksat-h2/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         "`psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-h2/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl-maxwalksat-h2/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         "-ec `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.1 MaxWalkSat (Postgres)
      psl::runLearn \
         "${outBaseDir}/psl-maxwalksat-postgres/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         "--postgres psl `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-maxwalksat-postgres/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl-maxwalksat-postgres/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         "--postgres psl -ec `psl::maxwalksatOptions`" \
         "${PSL_JAR_PATH}"

      # PSL 2.0
      psl::runLearn \
         "${outBaseDir}/psl-2.0/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         '' \
         "${PSL2_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl-2.0/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl-2.0/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec' \
         "${PSL2_JAR_PATH}"

      # Tuffy
      tuffy::runLearn \
         "${outBaseDir}/tuffy/${dataset}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/processed/${dataset}/learn"

      tuffy::runEval \
         "${outBaseDir}/tuffy/${dataset}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/processed/${dataset}/eval" \
         "${outBaseDir}/tuffy/${dataset}/${LEARNED_MLN_MODEL_FILENAME}"
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
