#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BASE_DATA_DIR="${THIS_DIR}/../data"
DATA_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/nell-kgi/processed.tar.gz'
DATA_FILE='processed.tar.gz'
DATA_DIR='processed'

function fetchData::main() {
   pushd . > /dev/null

   cd "${BASE_DATA_DIR}"
   requirements::fetch_and_extract_tar "${DATA_URL}" "${DATA_FILE}" "${DATA_DIR}" 'data'

   popd > /dev/null
}

# Run main if not sourced.
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && fetchData::main "$@"
