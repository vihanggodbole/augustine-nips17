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

# Limit to 300G
ulimit -d 314572800

# Limit to 1 hour
# ulimit -t 3600

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='caltech olivetti'

   for dataset in $datasets; do
      # PSL
      psl::runSuite \
         'image-reconstruction' \
         "${THIS_DIR}" \
         "${dataset}" \
         "${dataset} learn" \
         "${dataset} eval" \
         '-ec' \
         true

      # Tuffy
      # TODO(eriq): Tuffy implementation is currently broken.
#      tuffy::runLearn \
#         "${outBaseDir}/tuffy/${dataset}" \
#         "${THIS_DIR}/mln" \
#         "${THIS_DIR}/scripts" \
#         "${THIS_DIR}/data/processed/${dataset}/learn"
#
#      tuffy::runEval \
#         "${outBaseDir}/tuffy/${dataset}" \
#         "${THIS_DIR}/mln" \
#         "${THIS_DIR}/scripts" \
#         "${THIS_DIR}/data/processed/${dataset}/eval" \
#         "${outBaseDir}/tuffy/${dataset}/${LEARNED_MLN_MODEL_FILENAME}"
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
