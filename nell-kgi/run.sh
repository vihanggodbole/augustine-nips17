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

function run() {
   local outBaseDir="${THIS_DIR}/out"

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
   tuffy::runSuite \
      "${THIS_DIR}" \
      "$THIS_DIR/data/processed" \
      ''
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
