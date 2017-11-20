#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local method=''

   # PSL
   psl::runSuite \
      'nell-kgi' \
      "${THIS_DIR}" \
      '' \
      "learn" \
      "eval" \
      '-ec -ed 0.5' \
      true

   # Tuffy
   method='tuffy'
   tuffy::runLearn \
      "${outBaseDir}/${method}" \
      "${THIS_DIR}/mln" \
      "${THIS_DIR}/scripts" \
      "${THIS_DIR}/data/processed/learn"

   tuffy::runEval \
      "${outBaseDir}/${method}" \
      "${THIS_DIR}/mln" \
      "${THIS_DIR}/scripts" \
      "${THIS_DIR}/data/processed/eval" \
      "${outBaseDir}/${method}/${LEARNED_MLN_MODEL_FILENAME}"
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
