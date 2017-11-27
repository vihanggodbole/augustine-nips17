#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/util.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LIB_DIR="${THIS_DIR}/lib"
mkdir -p "${LIB_DIR}"

PSL_JAR_PATH="${LIB_DIR}/psl-cli-2.1.0-NIPS17.jar"
PSL_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/psl-cli-2.1.0-NIPS17.jar'

PSL_MOSEK_JAR_PATH="${LIB_DIR}/psl-mosek-2.1.0-NIPS17.jar"
PSL_MOSEK_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/psl-mosek-2.1.0-NIPS17.jar'

PSL_CVXPY_JAR_PATH="${LIB_DIR}/psl-cvxpy-2.1.0-NIPS17.jar"
PSL_CVXPY_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/psl-cvxpy-2.1.0-NIPS17.jar'

PSL2_JAR_PATH="${LIB_DIR}/psl-cli-2.0.0-NIPS17.jar"
PSL2_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/psl-cli-2.0.0-NIPS17.jar'

PSL121_JAR_PATH="${LIB_DIR}/psl121-1.2.1.jar"
PSL121_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/psl121-1.2.1.jar'

TUFFY_JAR_PATH="${LIB_DIR}/tuffy-modified.jar"
TUFFY_CONFIG_PATH="${THIS_DIR}/tuffy.conf"
TUFFY_JAR_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/tuffy-modified.jar'

# Get the java command we want all tests using.
function requirements::java() {
   echo 'java -Xmx25G -Xms25G'
}

# The time command to use.
# Note that we are not using the builtin time command so we can get
# peak memory information.
function requirements::time() {
   echo '/usr/bin/time -v'
}

function requirements::get_fetch_command() {
   type curl > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "curl -o"
      return
   fi

   type wget > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      echo "wget -O"
      return
   fi

   util::err 'wget or curl not found'
   exit 10
}

# Check for:
#  - wget or curl (final choice to be set in FETCH_COMMAND)
#  - tar
#  - ruby
#  - java
function requirements::check_requirements() {
   local hasWget
   local hasCurl

   type wget > /dev/null 2> /dev/null
   hasWget=$?

   type curl > /dev/null 2> /dev/null
   hasCurl=$?

   if [[ "${hasWget}" -ne 0 ]] && [[ "${hasCurl}" -ne 0 ]]; then
      util::err 'wget or curl required to download dataset'
      exit 10
   fi

   type tar > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      util::err 'tar required to extract dataset'
      exit 11
   fi

   type ruby > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      util::err 'ruby required to generate program files'
      exit 12
   fi

   type java > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      util::err 'java required to run project'
      exit 13
   fi
}

function requirements::fetch_file() {
   local url=$1
   local path=$2
   local name=$3

   if [[ -e "${path}" ]]; then
      echo "${name} file found cached, skipping download."
      return
   fi

   echo "Downloading the file with command: $FETCH_COMMAND"
   `requirements::get_fetch_command` "${path}" "${url}"
   if [[ "$?" -ne 0 ]]; then
      util::err "Failed to download ${name} file"
      exit 30
   fi
}

# Works for tarballs too.
function requirements::extract_tar() {
   local path=$1
   local expectedDir=$2
   local name=$3

   if [[ -e "${expectedDir}" ]]; then
      echo "Extracted ${name} tar found cached, skipping extract."
      return
   fi

   echo "Extracting the ${name} tar"
   tar xf "${path}"
   if [[ "$?" -ne 0 ]]; then
      util::err "Failed to extract ${name} tar"
      exit 40
   fi
}

function requirements::fetch_and_extract_tar() {
   local url=$1
   local path=$2
   local expectedDir=$3
   local name=$4

   requirements::fetch_file "${url}" "${path}" "${name}"
   requirements::extract_tar "${path}" "${expectedDir}" "${name}"
}

function requirements::fetch_all_jars() {
   requirements::fetch_file "${PSL_JAR_URL}" "${PSL_JAR_PATH}" 'PSL'
   requirements::fetch_file "${PSL_MOSEK_JAR_URL}" "${PSL_MOSEK_JAR_PATH}" 'PSL_MOSEK'
   requirements::fetch_file "${PSL_CVXPY_JAR_URL}" "${PSL_CVXPY_JAR_PATH}" 'PSL_CVXPY'
   requirements::fetch_file "${PSL2_JAR_URL}" "${PSL2_JAR_PATH}" 'PSL2'
   requirements::fetch_file "${PSL121_JAR_URL}" "${PSL121_JAR_PATH}" 'PSL121'
   requirements::fetch_file "${TUFFY_JAR_URL}" "${TUFFY_JAR_PATH}" 'Tuffy'
}

function requirements::main() {
   requirements::check_requirements
   requirements::fetch_all_jars
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && requirements::main "$@"
