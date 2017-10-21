#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BASE_DATA_DIR="${THIS_DIR}/../data"

DATA1_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/image-reconstruction/raw.tar.gz'
DATA1_FILE='raw.tar.gz'
DATA1_DIR='raw'

DATA2_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/image-reconstruction/processed.tar.gz'
DATA2_FILE='processed.tar.gz'
DATA2_DIR='processed'

function fetchData::main() {
   pushd . > /dev/null

   cd "${BASE_DATA_DIR}"
   requirements::fetch_and_extract_tar "${DATA1_URL}" "${DATA1_FILE}" "${DATA1_DIR}" 'rawData'
   requirements::fetch_and_extract_tar "${DATA2_URL}" "${DATA2_FILE}" "${DATA2_DIR}" 'data'

   popd > /dev/null
}

# Run main if not sourced.
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && fetchData::main "$@"
