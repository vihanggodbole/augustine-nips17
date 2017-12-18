#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Redefine for experiment specifics.
PSL_METHODS=("${PSL_ACCURACY_METHODS[@]}")
PSL_METHODS_CLI_OPTIONS=("${PSL_ACCURACY_METHODS_CLI_OPTIONS[@]}")
PSL_METHODS_JARS=("${PSL_ACCURACY_METHODS_JARS[@]}")

# Limit to 300G
ulimit -d 314572800

# Limit to 10 mins
# ulimit -t 600

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
            '' \
            true

         # Tuffy
         tuffy::runSuite \
            "${THIS_DIR}" \
            "$THIS_DIR/data/splits" \
            "${dataset}/${fold}"
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
