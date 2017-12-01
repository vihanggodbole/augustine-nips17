#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

QUERY_FILE="${THIS_DIR}/mln/query.db"
BASE_QUERY_FILE="${THIS_DIR}/mln/query-base.db"
GEN_QUERY_SCRIPT="${THIS_DIR}/scripts/generateMLNQuery.rb"

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

      # Weight learning needs a modified query that contians all the targets.
      ruby "${GEN_QUERY_SCRIPT}" "${THIS_DIR}/data/splits/${fold}/learn" "${QUERY_FILE}"

      # Tuffy
      tuffy::runLearn \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/splits/${fold}/learn"

      # Evaluation can use the default query.
      cp "${BASE_QUERY_FILE}" "${QUERY_FILE}"

      tuffy::runEval \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/splits/${fold}/eval" \
         "${outBaseDir}/tuffy/${fold}/${LEARNED_MLN_MODEL_FILENAME}"

      rm "${QUERY_FILE}"
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
