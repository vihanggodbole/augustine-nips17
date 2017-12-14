#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LEARNED_MLN_MODEL_FILENAME='learned-model.mln'
RAW_LEARNED_MLN_MODEL_FILENAME='raw-learned-model.mln'
TRANSFER_WEIGHTS_SCRIPT="${THIS_DIR}/transferTuffyLearnedWeights.rb"

TUFFY_DEFAULT_OPTIONS=''
TUFFY_DEFAULT_LEARN_OPTIONS='-dMaxIter 25'
TUFFY_DEFAULT_EVAL_OPTIONS='-maxFlips 100000 -randomStep 0.01'

function tuffy::runSuite() {
   local experimentBaseDir=$1
   local dataBaseDir=$2
   local foldId=$3

   local outBaseDir="$experimentBaseDir/out"
   local cliDir="$experimentBaseDir/mln"
   local scriptsDir="$experimentBaseDir/scripts"
   local dataDir="$dataBaseDir/$foldId"

   # We will only run learning once since it always does MCSat no matter what.
   tuffy::runLearn \
      "${outBaseDir}/tuffy-maxwalksat/$foldId" \
      "$cliDir" \
      "$scriptsDir" \
      "$dataDir/learn"

   # Copy over the learning.
   mkdir -p "${outBaseDir}/tuffy-mcsat/${dataset}"
   cp -r "${outBaseDir}/tuffy-maxwalksat/$foldId" "${outBaseDir}/tuffy-mcsat/$foldId"

   # We will eval twice.
   # Once for MaxWalkSat and once for MCSat.

   # MaxWalkSat
   tuffy::runEval \
      "${outBaseDir}/tuffy-maxwalksat/$foldId" \
      "$cliDir" \
      "$scriptsDir" \
      "$dataDir/eval" \
      "${outBaseDir}/tuffy-maxwalksat/$foldId/${LEARNED_MLN_MODEL_FILENAME}"

   # MCSat
   tuffy::runEval \
      "${outBaseDir}/tuffy-mcsat/$foldId" \
      "$cliDir" \
      "$scriptsDir" \
      "$dataDir/eval" \
      "${outBaseDir}/tuffy-mcsat/$foldId/${LEARNED_MLN_MODEL_FILENAME}"
}

function tuffy::runLearn() {
   local outDir=$1
   local cliDir=$2
   local scriptsDir=$3
   local sourceDataDir=$4

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateMLNData.rb"
   local programPath="${cliDir}/prog.mln"
   local queryPath="${cliDir}/query.db"
   local evidencePath="${outDir}/evidence.db"
   local rawResultsLearnPath="${outDir}/${RAW_LEARNED_MLN_MODEL_FILENAME}"
   local resultsLearnPath="${outDir}/${LEARNED_MLN_MODEL_FILENAME}"
   local outputLearnPath="${outDir}/out-learn.txt"
   local outputTimePath="${outDir}/time-learn.txt"

   if [ -f "${outputLearnPath}" ]; then
      echo "Target Tuffy (learn) file exists (${outputLearnPath}), skipping run."
      return
   fi

   echo "Generating Tuffy (learn) data file to ${evidencePath}."
   ruby "${generateDataScript}" "${sourceDataDir}" "${evidencePath}" 'learn'

   # Build the CLI options one at a time for visibility.
   local cliOptions=''
   cliOptions="${cliOptions} -learnwt"
   cliOptions="${cliOptions} -conf ${TUFFY_CONFIG_PATH}"
   cliOptions="${cliOptions} -i ${programPath}"
   cliOptions="${cliOptions} -e ${evidencePath}"
   cliOptions="${cliOptions} -queryFile ${queryPath}"
   cliOptions="${cliOptions} -r ${rawResultsLearnPath}"
   cliOptions="${cliOptions} ${TUFFY_DEFAULT_OPTIONS}"
   cliOptions="${cliOptions} ${TUFFY_DEFAULT_LEARN_OPTIONS}"

   echo "Running Tuffy (learn). Output redirected to ${outputLearnPath}."
   `requirements::time` `requirements::java` -jar "${TUFFY_JAR_PATH}" $cliOptions > $outputLearnPath 2> $outputTimePath

   # Transcribe the learned weights into the model.
   # We need to do this since Tuffy will lose constraints in the learned model.
   echo "Transposing weights to ${resultsLearnPath}."
   ruby "${TRANSFER_WEIGHTS_SCRIPT}" "${programPath}" "${rawResultsLearnPath}" "${resultsLearnPath}"

   rm -f "${evidencePath}"
}

function tuffy::runEval() {
   local outDir=$1
   local cliDir=$2
   local scriptsDir=$3
   local sourceDataDir=$4
   local programPath=$5

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateMLNData.rb"
   local queryPath="${cliDir}/query.db"
   local evidencePath="${outDir}/evidence.db"
   local outputEvalPath="${outDir}/out-eval.txt"
   local outputTimePath="${outDir}/time-eval.txt"
   local resultsEvalPath="${outDir}/results.txt"

   if [ -f "${outputEvalPath}" ]; then
      echo "Target Tuffy (eval) file exists (${outputEvalPath}), skipping run."
      return
   fi

   echo "Generating Tuffy (eval) data file to ${evidencePath}."
   ruby "${generateDataScript}" "${sourceDataDir}" "${evidencePath}" 'eval'

   # Build the CLI options one at a time for visibility.
   local cliOptions=''
   cliOptions="${cliOptions} -conf ${TUFFY_CONFIG_PATH}"
   cliOptions="${cliOptions} -i ${programPath}"
   cliOptions="${cliOptions} -e ${evidencePath}"
   cliOptions="${cliOptions} -queryFile ${queryPath}"
   cliOptions="${cliOptions} -r ${resultsEvalPath}"
   cliOptions="${cliOptions} ${TUFFY_DEFAULT_OPTIONS}"
   cliOptions="${cliOptions} ${TUFFY_DEFAULT_EVAL_OPTIONS}"

   echo "Running Tuffy (eval). Output redirected to ${outputEvalPath}."
   `requirements::time` `requirements::java` -jar "${TUFFY_JAR_PATH}" $cliOptions > $outputEvalPath 2> $outputTimePath

   rm -f "${evidencePath}"
}
