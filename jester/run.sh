#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local folds=`seq -s ' ' 0 9`

   for fold in $folds; do
      psl::runLearn \
         "${outBaseDir}/psl/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} learn" \
         '' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl/${fold}" \
         'jester' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${fold} eval" \
         "${outBaseDir}/psl/${fold}/${LEARNED_MODEL_FILENAME}" \
         '-ec' \
         "${PSL_JAR_PATH}"

      runTuffy $fold "${outBaseDir}"
   done
}

function runPSL() {
   local fold=$1
   local outDir="${2}/psl/${fold}"

   mkdir -p $outDir

   local generateDataScript="${EXPERIMENT_SCRIPTS_DIR}/generateDataFiles.rb"

   local plsCliDir="${THIS_DIR}/psl-cli"
   local modelPath="${plsCliDir}/jester.psl"
   local dataTemplatePath="${plsCliDir}/jester-template.data"
   local learnedModelFilename='jester-learned.psl'
   local defaultLearnedModelPath="${plsCliDir}/${learnedModelFilename}"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local learnDataFilePath="${outDir}/learn.data"
   local evalDataFilePath="${outDir}/eval.data"

   local learnedModelPath="${outDir}/${learnedModelFilename}"

   echo "Generating PSL learn data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $fold 'learn'

   echo "Running PSL ${fold} (learn). Output redirected to ${outputLearnPath}."
   time java -jar "${PSL_JAR_PATH}" -l -d ${learnDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG > ${outputLearnPath}
   mv ${defaultLearnedModelPath} ${learnedModelPath}

   echo "Generating PSL eval data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $fold 'eval'

   echo "Running PSL ${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${PSL_JAR_PATH}" -i -d ${evalDataFilePath} -m ${learnedModelPath} -D log4j.threshold=DEBUG -ed -o ${outDir} > ${outputEvalPath}
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

   local resultsLearnPath="${outDir}/learned_model.txt"
   local resultsEvalPath="${outDir}/eval_rating.txt"

   local outputLearnPath="${outDir}/out-learn.txt"
   local outputEvalPath="${outDir}/out-eval.txt"

   local evalSourceDataDir="${THIS_DIR}/data/splits/${fold}/eval"

   echo "Generating Tuffy learn data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${fold} (learn). Output redirected to ${outputLearnPath}."
   time java -jar "${TUFFY_JAR_PATH}" -learnwt -dMaxIter 25 -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsLearnPath}" -marginal > ${outputLearnPath}

   echo "Generating Tuffy eval data file to ${evidencePath}."
   ruby "${generateDataScript}" "${evalSourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy ${fold} (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${TUFFY_JAR_PATH}" -conf "${TUFFY_CONFIG_PATH}" -i "${resultsLearnPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsEvalPath}" -marginal > ${outputEvalPath}

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
