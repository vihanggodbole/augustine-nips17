#!/bin/bash

trap exit SIGINT

DATA_DIR='data'
FETCH_DATA_SCRIPT="fetchData.sh"
JAR_PATH='../psl-cli-CANARY.jar'
JAR_URL='https://linqs-data.soe.ucsc.edu/maven/repositories/psl-releases/org/linqs/psl-cli/CANARY/psl-cli-CANARY.jar'

FETCH_COMMAND=''

function err() {
   echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

# Check for:
#  - wget or curl (final choice to be set in FETCH_COMMAND)
#  - tar
#  - java
function check_requirements() {
   local hasWget

   type wget > /dev/null 2> /dev/null
   hasWget=$?

   type curl > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      FETCH_COMMAND="curl -o"
   elif [[ "${hasWget}" -eq 0 ]]; then
      FETCH_COMMAND="wget -O"
   else
      err 'wget or curl required to download dataset'
      exit 10
   fi

   type tar > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'tar required to extract dataset'
      exit 11
   fi

   type ruby > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'ruby required to generate psl files'
      exit 12
   fi

   type java > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'java required to run project'
      exit 13
   fi
}

function fetch_data() {
   pushd . > /dev/null
   cd $DATA_DIR

   bash $FETCH_DATA_SCRIPT
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to download dataset'
      exit 20
   fi

   popd > /dev/null
}

function fetch_jar() {
   if [[ -e "${JAR_PATH}" ]]; then
      echo "PSL jar found cached, skipping download."
      return
   fi

   echo "Downloading the jar with command: $FETCH_COMMAND"
   $FETCH_COMMAND "${JAR_PATH}" "${JAR_URL}"
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to download jar'
      exit 30
   fi
}

function run() {
   BASE_DIR=`pwd`
   SCRIPTS_DIR="${BASE_DIR}/scripts"
   GENERATE_DATAFILE_SCRIPT="${SCRIPTS_DIR}/generateDataFiles.rb"

   OUT_BASE_DIR="${BASE_DIR}/out"

   DATASETS='caltech olivetti'
   METHOD_LEARN='learn'
   METHOD_EVAL='eval'

   PSL_CLI_DIR="${BASE_DIR}/psl-cli"
   MODEL_PATH="${PSL_CLI_DIR}/image-reconstruction.psl"
   DATA_TEMPLATE_PATH="${PSL_CLI_DIR}/image-reconstruction-template.data"
   LEARNED_MODEL_FILENAME='image-reconstruction-learned.psl'
   LEARNED_MODEL_PATH="${PSL_CLI_DIR}/${LEARNED_MODEL_FILENAME}"

   for dataset in $DATASETS; do
      outDir="${OUT_BASE_DIR}/${dataset}"
      mkdir -p $outDir

      outputLearnPath="${outDir}/out-learn.txt"
      outputEvalPath="${outDir}/out-eval.txt"

      learnDataFilePath="${outDir}/${dataset}-learn.data"
      evalDataFilePath="${outDir}/${dataset}-eval.data"

      learnedModelPath="${outDir}/${LEARNED_MODEL_FILENAME}"

      echo "Generating learn data file to ${learnDataFilePath}."
      ruby $GENERATE_DATAFILE_SCRIPT $DATA_TEMPLATE_PATH $learnDataFilePath $dataset $METHOD_LEARN

      echo "Running ${dataset} (learn). Output redirected to ${outputLearnPath}."
      time java -Xmx12G -Xms12G -jar $JAR_PATH -l -d ${learnDataFilePath} -m ${MODEL_PATH} -D log4j.threshold=DEBUG -D votedperceptron.stepsize=5.0 -D votedperceptron.numsteps=100 > ${outputLearnPath}
      mv ${LEARNED_MODEL_PATH} ${learnedModelPath}

      echo "Generating eval data file to ${evalDataFilePath}."
      ruby $GENERATE_DATAFILE_SCRIPT $DATA_TEMPLATE_PATH $evalDataFilePath $dataset $METHOD_EVAL

      echo "Running ${dataset} (eval). Output redirected to ${outputEvalPath}."
      time java -Xmx12G -Xms12G -jar $JAR_PATH -i -d ${evalDataFilePath} -m ${learnedModelPath} -D log4j.threshold=DEBUG -ec -o ${outDir} > ${outputEvalPath}
   done
}

function main() {
   check_requirements
   fetch_data
   fetch_jar
   run
}

main "$@"
