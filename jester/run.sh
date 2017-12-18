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

# Limit to 4 hours
# ulimit -t 14400

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -s ' ' 0 9`

   for fold in $folds; do
      # PSL
      psl::runSuite \
         'jester' \
         "${THIS_DIR}" \
         "${fold}" \
         "${fold} learn" \
         "${fold} eval" \
         '-ed 0.5' \
         true

      # Tuffy
      tuffy::runSuite \
         "${THIS_DIR}" \
         "$THIS_DIR/data/splits" \
         "${fold}"
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
