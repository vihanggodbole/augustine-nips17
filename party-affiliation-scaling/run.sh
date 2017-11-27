#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_GEN_SCRIPT="${THIS_DIR}/scripts/generateGraphData.rb"

# Redefine for experiment specifics.
PSL_METHODS=('psl-admm-postgres' 'psl-mosek-postgres' 'psl-cvxpy-postgres')
PSL_METHODS_CLI_OPTIONS=('--postgres psl' "`psl::mosekOptions` --postgres psl" "`psl::cvxpxOptions` --postgres psl")
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_CVXPY_JAR_PATH}")

# Limit to 300G
ulimit -d 314572800

# Limit to 4 hours
ulimit -t 14400

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -w -s ' ' 100000 100000 1000000`

   for fold in $folds; do
      # Generate the data.
      echo "Generating data for ${fold} nodes."
      local dataDir="${THIS_DIR}/data/processed/${fold}"
      ruby $DATA_GEN_SCRIPT $fold "${dataDir}"

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
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
