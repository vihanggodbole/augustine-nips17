#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

QUERY_FILE="${THIS_DIR}/mln/query.db"
BASE_QUERY_FILE="${THIS_DIR}/mln/query-base.db"
GEN_QUERY_SCRIPT="${THIS_DIR}/scripts/generateMLNQuery.rb"

# Redefine for experiment specifics.
PSL_METHODS=("${PSL_ACCURACY_METHODS[@]}")
PSL_METHODS_CLI_OPTIONS=("${PSL_ACCURACY_METHODS_CLI_OPTIONS[@]}")
PSL_METHODS_JARS=("${PSL_ACCURACY_METHODS_JARS[@]}")

# We have extra weight learning params.
PSL_DEFAULT_LEARN_OPTIONS='-D votedperceptron.stepsize=5.0 -D votedperceptron.numsteps=100 -D booleanmcsat.numsamples=5000'
PSL_DEFAULT_EVAL_OPTIONS='-D booleanmcsat.numsamples=5000'

# Limit to 300G
ulimit -d 314572800

# Limit to 1 hour
# ulimit -t 3600

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -s ' ' 0 7`

   for fold in $folds; do
      # PSL
      psl::runSuite \
         'epinions' \
         "${THIS_DIR}" \
         "${fold}" \
         "${fold} learn" \
         "${fold} eval" \
         '-ec' \
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
