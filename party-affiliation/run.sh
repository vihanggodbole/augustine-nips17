#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Redefine for experiment specifics.
# PSL_METHODS=('psl-admm-postgres' 'psl-mosek-postgres' 'psl-cvxpy-postgres')
# PSL_METHODS_CLI_OPTIONS=('--postgres psl' "`psl::mosekOptions` --postgres psl" "`psl::cvxpxOptions` --postgres psl")
# PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_CVXPY_JAR_PATH}")

PSL_METHODS=('psl-admm-postgres' 'psl-mosek-postgres')
PSL_METHODS_CLI_OPTIONS=('--postgres psl' "`psl::mosekOptions` --postgres psl")
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}")

# Limit to 300G
ulimit -d 314572800

# Limit to 4 hours
ulimit -t 14400

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds='22050 33075 38588 44100 49613 55125 66150'

   for fold in $folds; do
      # PSL
      psl::runSuite \
         'party-affiliation' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '' \
         false
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
