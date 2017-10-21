#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXPERIMENT_SCRIPTS_DIR="${THIS_DIR}/scripts"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='caltech olivetti'

   for dataset in $datasets; do
      # TEST
      # runPSL $dataset "${outBaseDir}"
      runTuffy $dataset "${outBaseDir}"
   done
}

function runPSL() {
   local dataset=$1
   local outDir="${2}/psl/${dataset}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateDataFiles.rb"

   local plsCliDir="${THIS_DIR}/psl-cli"
   local modelPath="${plsCliDir}/image-reconstruction.psl"
   local dataTemplatePath="${plsCliDir}/image-reconstruction-template.data"
   local learnedModelFilename='image-reconstruction-learned.psl'
   local defaultLearnedModelPath="${plsCliDir}/${learnedModelFilename}"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local learnDataFilePath="${outDir}/learn.data"
   local evalDataFilePath="${outDir}/eval.data"

   local learnedModelPath="${outDir}/${learnedModelFilename}"

   echo "Generating PSL learn data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $dataset 'learn'

   echo "Running PSL ${dataset} (learn). Output redirected to ${outputLearnPath}."
   time java -Xmx12G -Xms12G -jar "${PSL_JAR_PATH}" -l -d ${learnDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG > ${outputLearnPath}
   mv ${defaultLearnedModelPath} ${learnedModelPath}

   echo "Generating PSL eval data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $dataset 'eval'

   echo "Running PSL ${dataset} (eval). Output redirected to ${outputEvalPath}."
   time java -Xmx12G -Xms12G -jar "${PSL_JAR_PATH}" -i -d ${evalDataFilePath} -m ${learnedModelPath} -D log4j.threshold=DEBUG -ed -o ${outDir} > ${outputEvalPath}
}

function runTuffy() {
   local dataset=$1
   local outDir="${2}/tuffy/${dataset}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateMLNData.rb"

   local mlnCliDir="${THIS_DIR}/mln"
   local programPath="${mlnCliDir}/prog.mln"
   local queryPath="${mlnCliDir}/query.db"
   local evidencePath="${THIS_DIR}/evidence.db"

   local resultsLearnPath="${outDir}/learned_model.txt"
   local resultsEvalPath="${outDir}/eval_pixelBrightness.txt"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local evalSourceDataDir="${THIS_DIR}/data/splits/${dataset}/eval"

   echo "Generating Tuffy learn data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${dataset} (learn). Output redirected to ${outputLearnPath}."
   time java -Xmx12G -Xms12G -jar "${TUFFY_JAR_PATH}" -learnwt -dMaxIter 25 -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsLearnPath}" -marginal > ${outputLearnPath}

   echo "Generating Tuffy eval data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${dataset} (eval). Output redirected to ${outputEvalPath}."
   time java -Xmx12G -Xms12G -jar "${TUFFY_JAR_PATH}" -conf "${TUFFY_CONFIG_PATH}" -i "${resultsLearnPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsEvalPath}" -marginal > ${outputEvalPath}

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
