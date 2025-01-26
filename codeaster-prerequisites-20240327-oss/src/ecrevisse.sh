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

if [ ${ECREVISSE} = "None" ]; then
    mark_done ${DEST} ecrevisse ecrevisse-${ECREVISSE}
    exit 0
fi

cd ${BUILD}
_download_curl_tgz ${PREREQ_URL}/ecrevisse-${ECREVISSE}.tar.gz

rm -rf content && mkdir content
_extract_arch ecrevisse-${ECREVISSE}.tar.gz
cd content/source
cp Makefile_linux_c9 Makefile && make optim
mkdir -p ${DEST}/ecrevisse-${ECREVISSE}/bin
cp ecrevisse_linux_* ${DEST}/ecrevisse-${ECREVISSE}/bin/ecrevisse

mark_done ${DEST} ecrevisse ecrevisse-${ECREVISSE} bin/ecrevisse
