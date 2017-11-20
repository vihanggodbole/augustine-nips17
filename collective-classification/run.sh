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
         # PSL
         psl::runSuite \
            'collective-classification' \
            "${THIS_DIR}" \
            "${dataset}/${fold}" \
            "${dataset} ${fold} learn" \
            "${dataset} ${fold} eval" \
            '-ed 0.5' \
            true

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
