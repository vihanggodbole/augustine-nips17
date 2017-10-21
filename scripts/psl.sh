#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LEARNED_MODEL_FILENAME='learned-model.psl'

function psl::runLearn() {
   local outDir=$1
   local modelName=$2
   local cliDir=$3
   local scriptsDir=$4
   local genDataParams=$5
   local extraCliOptions=$6
   local jarPath=$7

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateDataFiles.rb"
   local modelPath="${cliDir}/${modelName}.psl"
   local dataTemplatePath="${cliDir}/${modelName}-template.data"
   local defaultLearnedModelPath="${cliDir}/${modelName}-learned.psl"
   local outputLearnPath="${outDir}/out-learn.txt"
   local learnDataFilePath="${outDir}/learn.data"
   local learnedModelPath="${outDir}/${LEARNED_MODEL_FILENAME}"

   echo "Generating PSL (learn) data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $genDataParams

   echo "Running PSL (learn). Output redirected to ${outputLearnPath}."
   time `requirements::java` -jar "${jarPath}" -l -d ${learnDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG ${extraCliOptions} > ${outputLearnPath}
   mv ${defaultLearnedModelPath} ${learnedModelPath}
}

function psl::runEval() {
   local outDir=$1
   local modelName=$2
   local cliDir=$3
   local scriptsDir=$4
   local genDataParams=$5
   local modelPath=$6
   local extraCliOptions=$7
   local jarPath=$8

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateDataFiles.rb"
   local dataTemplatePath="${cliDir}/${modelName}-template.data"
   local outputEvalPath="${outDir}/out-eval.txt"
   local evalDataFilePath="${outDir}/eval.data"

   echo "Generating PSL (eval) data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $genDataParams

   echo "Running PSL (eval). Output redirected to ${outputEvalPath}."
   time `requirements::java` -jar "${jarPath}" -i -d ${evalDataFilePath} -m ${modelPath} -D log4j.threshold=DEBUG ${extraCliOptions} -o ${outDir} > ${outputEvalPath}
}
