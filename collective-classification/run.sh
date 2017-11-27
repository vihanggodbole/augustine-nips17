#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Redefine for experiment specifics.
PSL_METHODS=('psl-admm-h2' 'psl-admm-postgres' 'psl-maxwalksat-h2' 'psl-maxwalksat-postgres' 'psl-mcsat-h2' 'psl-mcsat-postgres')
PSL_METHODS_CLI_OPTIONS=('' '--postgres psl' "`psl::maxwalksatOptions`" "`psl::maxwalksatOptions` --postgres psl" "`psl::mcsatOptions`" "`psl::mcsatOptions` --postgres psl")
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}")

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
