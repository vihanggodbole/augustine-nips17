#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds='22050 33075 38588 44100 49613 55125 66150'

   for fold in $folds; do
      # PSL 2.1 (H2)
      psl::runEval \
         "${outBaseDir}/psl/${fold}" \
         'party-affiliation' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/party-affiliation.psl" \
         '' \
         "${PSL_JAR_PATH}"

      # PSL 2.1 (Postgres)
      psl::runEval \
         "${outBaseDir}/psl-postgres/${fold}" \
         'party-affiliation' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/party-affiliation.psl" \
         '--postgres psl' \
         "${PSL_JAR_PATH}"

      # PSL 2.0
      psl::runEval \
         "${outBaseDir}/psl-2.0/${fold}" \
         'party-affiliation' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/party-affiliation.psl" \
         '' \
         "${PSL2_JAR_PATH}"

      # Tuffy
      tuffy::runEval \
         "${outBaseDir}/tuffy/${fold}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/processed/${fold}" \
         "${THIS_DIR}/mln/prog.mln"
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
