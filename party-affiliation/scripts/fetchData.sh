#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${scriptDir}/../../scripts/requirements.sh"
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${scriptDir}/../../scripts/util.sh"

readonly BASE_DATA_DIR='data'
readonly DATA_URL='https://linqs-data.soe.ucsc.edu/public/augustine-nips17-data/party-affiliation/processed.tar.gz'
readonly DATA_FILE='processed.tar.gz'
readonly DATA_DIR='processed'

function fetchData::main() {
   pushd .

   cd "${BASE_DATA_DIR}"
   requirements::fetch_and_extract_tar "${DATA_URL}" "${DATA_FILE}" "${DATA_DIR}" 'data'

   popd
}

# Run main if not sourced.
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && fetchData::main "$@"
