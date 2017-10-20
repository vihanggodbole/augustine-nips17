#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPERIMENT_SCRIPTS_DIR="${THIS_DIR}/scripts"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds='22050 33075 38588 44100 49613 55125 66150'

   for fold in $folds; do
      runPSL $fold "${outBaseDir}"
      runTuffy $fold "${outBaseDir}"
   done
}

function runPSL() {
   local fold=$1
   local outDir="${2}/psl/${fold}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateDataFiles.rb"

   local pslCliDir="${THIS_DIR}/psl-cli"
   local modelPath="${pslCliDir}/party-affiliation.psl"
   local dataTemplatePath="${pslCliDir}/party-affiliation-template.data"

   local outputEvalPath="${outDir}/out-eval.txt"
   local evalDataFilePath="${outDir}/${fold}-eval.data"

   echo "Generating PSL eval data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $fold

   echo "Running PSL ${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar $PSL_JAR_PATH -i -d ${evalDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG -o ${outDir} > ${outputEvalPath}
}

function runTuffy() {
   local fold=$1
   local outDir="${2}/tuffy/${fold}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateMLNData.rb"

   local mlnCliDir="${THIS_DIR}/mln"
   local programPath="${mlnCliDir}/prog.mln"
   local queryPath="${mlnCliDir}/query.db"
   local evidencePath="${THIS_DIR}/evidence.db"
   local resultsPath="${outDir}/votes.txt"

   local outputEvalPath="${outDir}/out-eval.txt"
   local evalDataFilePath="${outDir}/${fold}-eval.data"

   local sourceDataDir="${THIS_DIR}/data/processed/${fold}"
   local evidencePath="${THIS_DIR}/evidence.db"

   echo "Generating Tuffy eval data file to ${evalDataFilePath}."
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
