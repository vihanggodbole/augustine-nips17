#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='citeseer cora'
   local folds=`seq -s ' ' 0 19`
   local model=''

   for dataset in $datasets; do
      for fold in $folds; do
         # PSL 2.1 ADMM (H2)
         psl::runLearn \
            "${outBaseDir}/psl-admm-h2/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            '' \
            "${PSL_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl-admm-h2/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl-admm-h2/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            '-ed 0.5' \
            "${PSL_JAR_PATH}"

         # PSL 2.1 ADMM (Postgres)
         psl::runLearn \
            "${outBaseDir}/psl-admm-postgres/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            '--postgres psl' \
            "${PSL_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl-admm-postgres/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl-admm-postgres/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            '--postgres psl -ed 0.5' \
            "${PSL_JAR_PATH}"

         # PSL 2.1 MaxWalkSat (H2)
         psl::runLearn \
            "${outBaseDir}/psl-maxwalksat-h2/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            "`psl::maxwalksatOptions`" \
            "${PSL_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl-maxwalksat-h2/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl-maxwalksat-h2/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            "-ed 0.5 `psl::maxwalksatOptions`" \
            "${PSL_JAR_PATH}"

         # PSL 2.1 MaxWalkSat (Postgres)
         psl::runLearn \
            "${outBaseDir}/psl-maxwalksat-postgres/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            "--postgres psl `psl::maxwalksatOptions`" \
            "${PSL_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl-maxwalksat-postgres/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl-maxwalksat-postgres/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            "--postgres psl -ed 0.5 `psl::maxwalksatOptions`" \
            "${PSL_JAR_PATH}"

         # PSL 2.0
         psl::runLearn \
            "${outBaseDir}/psl-2.0/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            '' \
            "${PSL2_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl-2.0/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl-2.0/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            '-ed 0.5' \
            "${PSL2_JAR_PATH}"

         # Tuffy
         tuffy::runLearn \
            "${outBaseDir}/tuffy/${dataset}/${fold}" \
            "${THIS_DIR}/mln" \
            "${THIS_DIR}/scripts" \
            "${THIS_DIR}/data/splits/${dataset}/${fold}/learn"

         tuffy::runEval \
            "${outBaseDir}/tuffy/${dataset}/${fold}" \
            "${THIS_DIR}/mln" \
            "${THIS_DIR}/scripts" \
            "${THIS_DIR}/data/splits/${dataset}/${fold}/eval" \
            "${outBaseDir}/tuffy/${dataset}/${fold}/${LEARNED_MLN_MODEL_FILENAME}"
      done
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
