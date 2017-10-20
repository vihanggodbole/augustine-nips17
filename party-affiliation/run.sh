#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${scriptDir}/scripts/fetchData.sh"
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${scriptDir}/../scripts/requirements.sh"

trap exit SIGINT

function run() {
   BASE_DIR=`pwd`
   SCRIPTS_DIR="${BASE_DIR}/scripts"
   GENERATE_DATAFILE_SCRIPT="${SCRIPTS_DIR}/generateDataFiles.rb"

   OUT_BASE_DIR="${BASE_DIR}/out/psl"

   FOLDS='22050 33075 38588 44100 49613 55125 66150'

   PSL_CLI_DIR="${BASE_DIR}/psl-cli"
   MODEL_PATH="${PSL_CLI_DIR}/party-affiliation.psl"
   DATA_TEMPLATE_PATH="${PSL_CLI_DIR}/party-affiliation-template.data"

   for fold in $FOLDS; do
      outDir="${OUT_BASE_DIR}/${fold}"
      mkdir -p $outDir

      outputEvalPath="${outDir}/out-eval.txt"
      evalDataFilePath="${outDir}/${fold}-eval.data"

      echo "Generating eval data file to ${evalDataFilePath}."
      ruby $GENERATE_DATAFILE_SCRIPT $DATA_TEMPLATE_PATH $evalDataFilePath $fold $METHOD_EVAL

      echo "Running ${fold} (eval). Output redirected to ${outputEvalPath}."
      time java -jar $PSL_JAR_PATH -i -d ${evalDataFilePath} -m ${MODEL_PATH} -D log4j.threshold=DEBUG -o ${outDir} > ${outputEvalPath}
   done
}

function main() {
   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
