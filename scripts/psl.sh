#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CLI_MAIN_CLASS='org.linqs.psl.cli.Launcher'

function psl::maxwalksatOptions() {
   echo '-D mpeinference.reasoner=org.linqs.psl.reasoner.bool.BooleanMaxWalkSat -D mpeinference.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -D mpeinference.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -D mpeinference.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator -D weightlearning.reasoner=org.linqs.psl.reasoner.bool.BooleanMaxWalkSat -D weightlearning.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -D weightlearning.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -D weightlearning.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator -D booleanmaxwalksat.maxflips=100000'
}

function psl::mcsatOptions() {
   echo '-D mpeinference.reasoner=org.linqs.psl.reasoner.bool.BooleanMCSat -D mpeinference.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -D mpeinference.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -D mpeinference.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator -D weightlearning.reasoner=org.linqs.psl.reasoner.bool.BooleanMCSat -D weightlearning.groundrulestore=org.linqs.psl.application.groundrulestore.AtomRegisterGroundRuleStore -D weightlearning.termstore=org.linqs.psl.reasoner.term.ConstraintBlockerTermStore -D weightlearning.termgenerator=org.linqs.psl.reasoner.term.ConstraintBlockerTermGenerator'
}

function psl::mosekOptions() {
   echo '-D conictermstore.conicprogramsolver=org.linqs.psl.experimental.optimizer.conic.mosek.Mosek -D mpeinference.reasoner=org.linqs.psl.experimental.reasoner.conic.ConicReasoner -D mpeinference.termstore=org.linqs.psl.experimental.reasoner.conic.ConicTermStore -D mpeinference.termgenerator=org.linqs.psl.experimental.reasoner.conic.ConicTermGenerator'
}

function psl::cvxpxOptions() {
   echo "-D mpeinference.reasoner=org.linqs.psl.experimental.reasoner.general.CVXPYReasoner -D mpeinference.termstore=org.linqs.psl.experimental.reasoner.general.JSONSerialTermStore -D mpeinference.termgenerator=org.linqs.psl.experimental.reasoner.general.JSONSerialTermGenerator -D executablereasoner.executablepath=${LIB_DIR}/cvxpy_reasoner.py"
}

PSL_METHODS=('psl-admm-h2' 'psl-admm-postgres' 'psl-maxwalksat-h2' 'psl-maxwalksat-postgres' 'psl-mcsat-h2' 'psl-mcsat-postgres' 'psl-2.0' 'psl-mosek-h2' 'psl-mosek-postgres' 'psl-1.2.1' 'psl-cvxpy-h2' 'psl-cvxpy-postgres')
PSL_METHODS_CLI_OPTIONS=('' '--postgres psl' "`psl::maxwalksatOptions`" "`psl::maxwalksatOptions` --postgres psl" "`psl::mcsatOptions`" "`psl::mcsatOptions` --postgres psl" '' "`psl::mosekOptions`" "`psl::mosekOptions` --postgres psl" '' "`psl::cvxpxOptions`" "`psl::cvxpxOptions` --postgres psl")
PSL_METHODS_JARS=("${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL_JAR_PATH}" "${PSL2_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_MOSEK_JAR_PATH}" "${PSL121_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_CVXPY_JAR_PATH}" "${PSL_JAR_PATH}:${PSL_CVXPY_JAR_PATH}")

PSL_DEFAULT_OPTIONS='-D log4j.threshold=DEBUG'
PSL_DEFAULT_LEARN_OPTIONS=''
PSL_DEFAULT_EVAL_OPTIONS=''

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

         modelPath="${outDir}/${modelName}-learned.psl"
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
   local classpath=$8

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateDataFiles.rb"
   local dataTemplatePath="${cliDir}/${modelName}-template.data"
   local defaultLearnedModelPath="${cliDir}/${modelName}-learned.psl"
   local outputLearnPath="${outDir}/out-learn.txt"
   local outputTimePath="${outDir}/time-learn.txt"
   local learnDataFilePath="${outDir}/learn.data"
   local learnedModelPath="${outDir}/${modelName}-learned.psl"

   if [ -f "${outputLearnPath}" ]; then
      echo "Target PSL (learn) file exists (${outputLearnPath}), skipping run."
      return
   fi

   echo "Generating PSL (learn) data file to ${learnDataFilePath}."
   ruby $generateDataScript $dataTemplatePath $learnDataFilePath $genDataParams

   # Build the CLI options one at a time for visibility.
   local cliOptions=''
   cliOptions="${cliOptions} -learn"
   cliOptions="${cliOptions} -data ${learnDataFilePath}"
   cliOptions="${cliOptions} -model ${modelPath}"
   cliOptions="${cliOptions} ${extraCliOptions}"
   cliOptions="${cliOptions} -output ${outDir}"
   cliOptions="${cliOptions} ${PSL_DEFAULT_OPTIONS}"
   cliOptions="${cliOptions} ${PSL_DEFAULT_LEARN_OPTIONS}"

   echo "Running PSL (learn). Output redirected to ${outputLearnPath}."
   `requirements::time` `requirements::java` -cp "${classpath}" $CLI_MAIN_CLASS $cliOptions > $outputLearnPath 2> $outputTimePath
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
   local classpath=$8

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

   # Build the CLI options one at a time for visibility.
   local cliOptions=''
   cliOptions="${cliOptions} -infer"
   cliOptions="${cliOptions} -data ${evalDataFilePath}"
   cliOptions="${cliOptions} -model ${modelPath}"
   cliOptions="${cliOptions} ${extraCliOptions}"
   cliOptions="${cliOptions} -output ${outDir}"
   cliOptions="${cliOptions} ${PSL_DEFAULT_OPTIONS}"
   cliOptions="${cliOptions} ${PSL_DEFAULT_LEARN_OPTIONS}"

   echo "Running PSL (eval). Output redirected to ${outputEvalPath}."
   `requirements::time` `requirements::java` -cp "${classpath}" $CLI_MAIN_CLASS $cliOptions > $outputEvalPath 2> $outputTimePath
}
