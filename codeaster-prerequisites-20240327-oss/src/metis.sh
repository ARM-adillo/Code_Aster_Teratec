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

# METIS and GKlib are currently provided by the old tar.gz from 2013...
# GitHub repositories seem not consistent with MUMPS needs.
# mark_done ${DEST} metis metis-${METIS}
# exit 0
### END ###

cd ${BUILD}
# access: ci-prereq-read-api
_download_gitlab_tgz ${GITLAB} ${METIS_ID} v${METIS} metis-${METIS}.tar.gz
_download_gitlab_tgz ${GITLAB} ${_GKLIB_ID} ${_GKLIB} gklib-${_GKLIB}.tar.gz

if [ ${enable_debug} -eq 1 ]; then
    export CFLAGS="-g ${CFLAGS}"
fi

# GKlib
rm -rf content && mkdir content
_extract_arch gklib-${_GKLIB}.tar.gz
cd content

make config CFLAGS="-fPIC ${CFLAGS}" prefix=${DEST}/metis-${METIS}
make -j ${procs}
make install

# METIS
cd ..
rm -rf content && mkdir content
_extract_arch metis-${METIS}.tar.gz
cd content

make config CFLAGS="-fPIC ${CFLAGS}" \
    prefix=${DEST}/metis-${METIS} \
    shared=1 i64=1 r64=1
make -j ${procs}
make install

mark_done ${DEST} metis metis-${METIS} lib/libmetis.so include/metis.h
