#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPERIMENT_SCRIPTS_DIR="${THIS_DIR}/scripts"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='citeseer cora'
   local folds=`seq -s ' ' 0 19`

   for dataset in $datasets; do
      for fold in $folds; do
         runPSL $fold $dataset "${outBaseDir}"
         runTuffy $fold $dataset "${outBaseDir}"
      done
   done
}

function runPSL() {
   local fold=$1
   local dataset=$2
   local outDir="${3}/psl/${dataset}/${fold}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateDataFiles.rb"

   local plsCliDir="${THIS_DIR}/psl-cli"
   local modelPath="${plsCliDir}/collective-classification.psl"
   local dataTemplatePath="${plsCliDir}/collective-classification-template.data"
   local learnedModelFilename='collective-classification-learned.psl'
   local defaultLearnedModelPath="${plsCliDir}/${learnedModelFilename}"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local learnDataFilePath="${outDir}/learn.data"
   local evalDataFilePath="${outDir}/eval.data"

   local learnedModelPath="${outDir}/${learnedModelFilename}"

   echo "Generating PSL learn data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $dataset $fold 'learn'

   echo "Running PSL ${dataset}/${fold} (learn). Output redirected to ${outputLearnPath}."
   time java -jar "${PSL_JAR_PATH}" -l -d ${learnDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG > ${outputLearnPath}
   mv ${defaultLearnedModelPath} ${learnedModelPath}

   echo "Generating PSL eval data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $dataset $fold 'eval'

   echo "Running PSL ${dataset}/${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${PSL_JAR_PATH}" -i -d ${evalDataFilePath} -m ${learnedModelPath} -D log4j.threshold=DEBUG -ed -o ${outDir} > ${outputEvalPath}
}

function runTuffy() {
   local fold=$1
   local dataset=$2
   local outDir="${3}/tuffy/${dataset}/${fold}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateMLNData.rb"

   local mlnCliDir="${THIS_DIR}/mln"
   local programPath="${mlnCliDir}/prog.mln"
   local queryPath="${mlnCliDir}/query.db"
   local evidencePath="${THIS_DIR}/evidence.db"

   local resultsLearnPath="${outDir}/learn_hasCat.txt"
   local resultsEvalPath="${outDir}/eval_hasCat.txt"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local evalSourceDataDir="${THIS_DIR}/data/splits/${dataset}/${fold}/eval"

   echo "Generating Tuffy learn data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${dataset}/${fold} (learn). Output redirected to ${outputLearnPath}."
   time java -jar "${TUFFY_JAR_PATH}" -learnwt -dMaxIter 25 -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsLearnPath}" -marginal > ${outputLearnPath}

   echo "Generating Tuffy eval data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${dataset}/${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${TUFFY_JAR_PATH}" -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsEvalPath}" -marginal > ${outputEvalPath}

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
