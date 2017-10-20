#!/bin/bash

readonly DATA1_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/image-reconstruction/raw.tar.gz'
readonly DATA1_FILE='raw.tar.gz'
readonly DATA1_DIR='raw'

readonly DATA2_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/image-reconstruction/processed.tar.gz'
readonly DATA2_FILE='processed.tar.gz'
readonly DATA2_DIR='processed'

FETCH_COMMAND=''

function err() {
   echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

# Check for:
#  - wget or curl (final choice to be set in FETCH_COMMAND)
#  - tar
#  - maven
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
}

function fetch_data() {
   dataFile=$1
   dataUrl=$2

   if [[ -e "${dataFile}" ]]; then
      echo "Data file found cached, skipping download."
      return
   fi

   echo "Downloading the dataset with command: $FETCH_COMMAND"
   $FETCH_COMMAND "${dataFile}" "${dataUrl}"
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to download dataset'
      exit 20
   fi
}

function extract_data() {
   dataFile=$1
   dataDir=$2

   if [[ -e "${dataDir}" ]]; then
      echo "Extracted data found cached, skipping extract."
      return
   fi

   echo 'Extracting the dataset'
   tar xzf "${dataFile}"
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to extract dataset'
      exit 30
   fi
}

function main() {
   check_requirements
   fetch_data $DATA1_FILE $DATA1_URL
   extract_data $DATA1_FILE $DATA1_DIR

   fetch_data $DATA2_FILE $DATA2_URL
   extract_data $DATA2_FILE $DATA2_DIR
}

main "$@"
