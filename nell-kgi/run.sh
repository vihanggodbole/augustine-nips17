#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local method=''

   # PSL 2.1 ADMM (H2)
   method='psl-admm-h2'
   psl::runLearn \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'learn' \
      '' \
      "${PSL_JAR_PATH}"

   psl::runEval \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'eval' \
      "${outBaseDir}/${method}/${LEARNED_PSL_MODEL_FILENAME}" \
      '-ec -ed 0.5' \
      "${PSL_JAR_PATH}"

   # PSL 2.1 ADMM (Postgres)
   method='psl-admm-postgres'
   psl::runLearn \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'learn' \
      '--postgres psl' \
      "${PSL_JAR_PATH}"

   psl::runEval \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'eval' \
      "${outBaseDir}/${method}/${LEARNED_PSL_MODEL_FILENAME}" \
      '--postgres psl -ec -ed 0.5' \
      "${PSL_JAR_PATH}"

   # PSL 2.1 MaxWalkSat (H2)
   method='psl-maxwalksat-h2'
   psl::runLearn \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'learn' \
      "`psl::maxwalksatOptions`" \
      "${PSL_JAR_PATH}"

   psl::runEval \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'eval' \
      "${outBaseDir}/${method}/${LEARNED_PSL_MODEL_FILENAME}" \
      "-ec -ed 0.5 `psl::maxwalksatOptions`" \
      "${PSL_JAR_PATH}"

   # PSL 2.1 MaxWalkSat (Postgres)
   method='psl-maxwalksat-postgres'
   psl::runLearn \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'learn' \
      "--postgres psl `psl::maxwalksatOptions`" \
      "${PSL_JAR_PATH}"

   psl::runEval \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'eval' \
      "${outBaseDir}/${method}/${LEARNED_PSL_MODEL_FILENAME}" \
      "--postgres psl -ec -ed 0.5 `psl::maxwalksatOptions`" \
      "${PSL_JAR_PATH}"

   # PSL 2.0
   method='psl-2.0'
   psl::runLearn \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'learn' \
      '' \
      "${PSL2_JAR_PATH}"

   psl::runEval \
      "${outBaseDir}/${method}" \
      'nell-kgi' \
      "${THIS_DIR}/psl-cli" \
      "${THIS_DIR}/scripts" \
      'eval' \
      "${outBaseDir}/${method}/${LEARNED_PSL_MODEL_FILENAME}" \
      '-ec -ed 0.5' \
      "${PSL2_JAR_PATH}"

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
