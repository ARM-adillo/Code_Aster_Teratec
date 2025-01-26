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
_download_curl_tgz ${PREREQ_URL}/fake_gracebat-${GRACE}.tar.gz

rm -rf content && mkdir content
_extract_arch fake_gracebat-${GRACE}.tar.gz
mkdir -p ${DEST}/grace-${GRACE}/bin
mv content/fake_gracebat ${DEST}/grace-${GRACE}/bin/gracebat

mark_done ${DEST} grace grace-${GRACE} bin/gracebat
