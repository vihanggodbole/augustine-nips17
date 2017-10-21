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

   for dataset in $datasets; do
      for fold in $folds; do
         psl::runLearn \
            "${outBaseDir}/psl/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} learn" \
            '' \
            "${PSL_JAR_PATH}"

         psl::runEval \
            "${outBaseDir}/psl/${dataset}/${fold}" \
            'collective-classification' \
            "${THIS_DIR}/psl-cli" \
            "${THIS_DIR}/scripts" \
            "${dataset} ${fold} eval" \
            "${outBaseDir}/psl/${dataset}/${fold}/${LEARNED_PSL_MODEL_FILENAME}" \
            '-ed 0.5' \
            "${PSL_JAR_PATH}"

         tuffy::runLearn \
            "${outBaseDir}/tuffy/${dataset}/${fold}" \
            "${THIS_DIR}/mln" \
            "${THIS_DIR}/scripts" \
            "${THIS_DIR}/data/splits/${dataset}/${fold}/eval"

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
