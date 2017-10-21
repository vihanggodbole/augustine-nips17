#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds='22050 33075 38588 44100 49613 55125 66150'

   for fold in $folds; do
      psl::runEval \
         "${outBaseDir}/psl/${fold}" \
         'party-affiliation' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold}" \
         "${THIS_DIR}/psl-cli/party-affiliation.psl" \
         '' \
         "${PSL_JAR_PATH}"

      runTuffy $fold "${outBaseDir}"
   done
}

function runTuffy() {
   local fold=$1
   local outDir="${2}/tuffy/${fold}"

   mkdir -p $outDir

   local generateDataScript="${THIS_DIR}/scripts/generateMLNData.rb"

   local mlnCliDir="${THIS_DIR}/mln"
   local programPath="${mlnCliDir}/prog.mln"
   local queryPath="${mlnCliDir}/query.db"
   local evidencePath="${THIS_DIR}/evidence.db"
   local resultsPath="${outDir}/votes.txt"

   local outputEvalPath="${outDir}/out-eval.txt"

   local sourceDataDir="${THIS_DIR}/data/processed/${fold}"

   echo "Generating Tuffy eval data file to ${evidencePath}."
   ruby "${generateDataScript}" "${sourceDataDir}" "${evidencePath}"

   echo "Running Tuffy ${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${TUFFY_JAR_PATH}" -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsPath}" -marginal > ${outputEvalPath}

   rm -f "${evidencePath}"
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
