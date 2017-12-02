#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_GEN_SCRIPT="${THIS_DIR}/scripts/generateFriendshipData.rb"

# Limit to 300G
ulimit -d 314572800

# Limit to 8 hours
# ulimit -t 28800

function run() {
   local outBaseDir="${THIS_DIR}/out"

   local folds="$(seq -w -s ' ' 30 10 0200)"
   PSL_METHODS=('psl-admm-postgres' 'psl-mosek-postgres' 'psl-cvxpy-postgres')
   PSL_METHODS_CLI_OPTIONS=('--postgres psl' "`psl::mosekOptions` --postgres psl" "`psl::cvxpxOptions` --postgres psl")
   PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_CVXPY_JAR_PATH}")

   for fold in $folds; do
      # Generate the data.
      ruby $DATA_GEN_SCRIPT -p $fold -l 10 -fh 0.85 -fl 0.15 -n friendship
      local dataDir="${THIS_DIR}/data/friendship_${fold}_0010"

      # PSL
      psl::runSuite \
         'friendship' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '-ec -ed 0.5' \
         false
   done

   local folds="$(seq -w -s ' ' 100 100 0600)"
   PSL_METHODS=('psl-admm-postgres' 'psl-mosek-postgres')
   PSL_METHODS_CLI_OPTIONS=('--postgres psl' "`psl::mosekOptions` --postgres psl")
   PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}")

   for fold in $folds; do
      # Generate the data.
      ruby $DATA_GEN_SCRIPT -p $fold -l 10 -fh 0.85 -fl 0.15 -n friendship
      local dataDir="${THIS_DIR}/data/friendship_${fold}_0010"

      # PSL
      psl::runSuite \
         'friendship' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '-ec -ed 0.5' \
         false
   done

   local folds="$(seq -w -s ' ' 100 100 1000)"
   PSL_METHODS=('psl-admm-postgres')
   PSL_METHODS_CLI_OPTIONS=('--postgres psl')
   PSL_METHODS_JARS=("${PSL_JAR_PATH}")

   for fold in $folds; do
      # Generate the data.
      ruby $DATA_GEN_SCRIPT -p $fold -l 10 -fh 0.85 -fl 0.15 -n friendship
      local dataDir="${THIS_DIR}/data/friendship_${fold}_0010"

      # PSL
      psl::runSuite \
         'friendship' \
         "${THIS_DIR}" \
         "${fold}" \
         '' \
         "${fold}" \
         '-ec -ed 0.5' \
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
