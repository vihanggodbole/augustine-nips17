#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LEARNED_PSL_MODEL_FILENAME='learned-model.psl'

function psl::maxwalksatOptions() {
   echo '-Dmpeinference.reasoner=org.linqs.psl.reasoner.bool.BooleanMaxWalkSat -Dmpeinference.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -Dmpeinference.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -Dmpeinference.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator'
}

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
   local outputTimePath="${outDir}/time.txt"
   local learnDataFilePath="${outDir}/learn.data"
   local learnedModelPath="${outDir}/${LEARNED_PSL_MODEL_FILENAME}"

   if [ -f "${outputLearnPath}" ]; then
      echo "Target PSL (learn) file exists (${outputLearnPath}), skipping run."
      return
   fi

   echo "Generating PSL (learn) data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $genDataParams

   echo "Running PSL (learn). Output redirected to ${outputLearnPath}."
   `requirements::time` `requirements::java` -jar "${jarPath}" -learn -data ${learnDataFilePath} -model ${modelPath} -D log4j.threshold=DEBUG ${extraCliOptions} > ${outputLearnPath} 2> ${outputTimePath}
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
   local outputTimePath="${outDir}/time.txt"
   local evalDataFilePath="${outDir}/eval.data"

   if [ -f "${outputEvalPath}" ]; then
      echo "Target PSL (eval) file exists (${outputEvalPath}), skipping run."
      return
   fi

   echo "Generating PSL (eval) data file to ${evalDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $evalDataFilePath $genDataParams

   echo "Running PSL (eval). Output redirected to ${outputEvalPath}."
   `requirements::time` `requirements::java` -jar "${jarPath}" -infer -data ${evalDataFilePath} -model ${modelPath} -D log4j.threshold=DEBUG ${extraCliOptions} -output ${outDir} > ${outputEvalPath} 2> ${outputTimePath}
}
