#!/bin/bash

# --- common ---
set_prefix() {
    local this=$(readlink -n -f "${1}")
    local src=$(dirname "${this}")
    prefix=$(dirname "${src}")
}

set_prefix "${0}"

. ${prefix}/VERSION
. ${prefix}/utils/build_env.sh
# --- common ---

cd ${BUILD}
_download_curl_tgz ${PREREQ_URL}/homard-${HOMARD}.tar.gz

rm -rf content && mkdir content
_extract_arch homard-${HOMARD}.tar.gz
cd content
mkdir -p ${DEST}/homard-${HOMARD}/bin
python3 setup_homard.py --prefix=${DEST}/homard-${HOMARD}/bin

# remove old binaries - default is V11_10!
# tag=$(awk -F_ '{print $1}' <<< "${HOMARD}")
# cd ${DEST}/homard-${HOMARD}/bin/Linux64
# rm $(ls HOMARD* | grep -v ${tag})

mark_done ${DEST} homard homard-${HOMARD} bin/ASTER_HOMARD/homard
