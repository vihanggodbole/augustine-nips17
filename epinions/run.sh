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
# We have extra weight learning params.
PSL_METHODS=('psl-admm-postgres' 'psl-maxwalksat-postgres' 'psl-mcsat-postgres')
PSL_METHODS_CLI_OPTIONS=('--postgres psl -D votedperceptron.stepsize=5.0 -D votedperceptron.numsteps=100' "`psl::maxwalksatOptions` --postgres psl -D votedperceptron.stepsize=5.0 -D votedperceptron.numsteps=100" "`psl::mcsatOptions` --postgres psl -D votedperceptron.stepsize=5.0 -D votedperceptron.numsteps=100")
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}")

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
         '-ec -D booleanmcsat.numsamples=5000' \
         true

      # TODO(eriq): Don't run Tuffy until this is resolved with the new infrastructure.
      echo "TODO(eriq): Resolve with new infrastructure."
      exit

#      # Weight learning needs a modified query that contians all the targets.
#      ruby "${GEN_QUERY_SCRIPT}" "${THIS_DIR}/data/splits/${fold}/learn" "${QUERY_FILE}"
#
#      # Tuffy
#      tuffy::runLearn \
#         "${outBaseDir}/tuffy/${fold}" \
#         "${THIS_DIR}/mln" \
#         "${THIS_DIR}/scripts" \
#         "${THIS_DIR}/data/splits/${fold}/learn"
#
#      # Evaluation can use the default query.
#      cp "${BASE_QUERY_FILE}" "${QUERY_FILE}"
#
#      tuffy::runEval \
#         "${outBaseDir}/tuffy/${fold}" \
#         "${THIS_DIR}/mln" \
#         "${THIS_DIR}/scripts" \
#         "${THIS_DIR}/data/splits/${fold}/eval" \
#         "${outBaseDir}/tuffy/${fold}/${LEARNED_MLN_MODEL_FILENAME}"
#
#      rm "${QUERY_FILE}"

      # Tuffy
      tuffy::runSuite \
         "${THIS_DIR}" \
         "$THIS_DIR/data/splits" \
         "${dataset}/${fold}"
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
