#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LEARNED_PSL_MODEL_FILENAME='learned-model.psl'

function psl::maxwalksatOptions() {
   echo '-Dmpeinference.reasoner=org.linqs.psl.reasoner.bool.BooleanMaxWalkSat -Dmpeinference.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -Dmpeinference.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -Dmpeinference.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator'
}

function psl::mcsatOptions() {
   echo '-Dmpeinference.reasoner=org.linqs.psl.reasoner.bool.BooleanMCSat -Dmpeinference.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -Dmpeinference.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -Dmpeinference.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator'
}

PSL_METHODS=('psl-admm-h2' 'psl-admm-postgres' 'psl-maxwalksat-h2' 'psl-maxwalksat-postgres' 'psl-mcsat-h2' 'psl-mcsat-postgres' 'psl-2.0')
PSL_METHODS_CLI_OPTIONS=('' '--postgres psl' "`psl::maxwalksatOptions`" "`psl::maxwalksatOptions` --postgres psl" "`psl::mcsatOptions`" "`psl::mcsatOptions` --postgres psl" '')
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL2_JAR_PATH}")

function psl::runSuite() {
   local modelName=$1
   local baseDir=$2
   local runId=$3
   local genDataLearnParams=$4
   local genDataEvalParams=$5
   local evalCliOptions=$6
   local runLearn=$7

   local outBaseDir="${baseDir}/out"
   local cliDir="${baseDir}/psl-cli"
   local scriptsDir="${baseDir}/scripts"

   for i in "${!PSL_METHODS[@]}"; do
      local method="${PSL_METHODS[$i]}"
      local methodCliOptions="${PSL_METHODS_CLI_OPTIONS[$i]}"
      local methodJar="${PSL_METHODS_JARS[$i]}"

      local outDir="${outBaseDir}/${method}/${runId}"
      local modelPath="${cliDir}/${modelName}.psl"

      if [ "${runLearn}" = true ] ; then
         psl::runLearn \
            "${outDir}" \
            "${modelName}" \
            "${cliDir}" \
            "${scriptsDir}" \
            "${genDataLearnParams}" \
            "${modelPath}" \
            "${methodCliOptions}" \
            "${methodJar}"

         modelPath="${outDir}/${LEARNED_PSL_MODEL_FILENAME}"
      fi

      psl::runEval \
         "${outDir}" \
         "${modelName}" \
         "${cliDir}" \
         "${scriptsDir}" \
         "${genDataEvalParams}" \
         "${modelPath}" \
         "${methodCliOptions} ${evalCliOptions}" \
         "${methodJar}"
   done
}

function psl::runLearn() {
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
   local defaultLearnedModelPath="${cliDir}/${modelName}-learned.psl"
   local outputLearnPath="${outDir}/out-learn.txt"
   local outputTimePath="${outDir}/time-learn.txt"
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
   local outputTimePath="${outDir}/time-eval.txt"
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
