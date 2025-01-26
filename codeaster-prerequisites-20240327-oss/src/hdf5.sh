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
_download_curl_tgz ${PREREQ_URL}/hdf5-${HDF5}.tar.gz

rm -rf content && mkdir content
_extract_arch hdf5-${HDF5}.tar.gz
cd content

if [ ${use_seq} -eq 0 ]; then
    opts=( "--enable-parallel" )
fi
if [ ${enable_debug} -eq 1 ]; then
    opt+=( "--enable-build-mode=debug" )
fi
opts+=( "--disable-static" )

./configure "${opts[@]}" --prefix=${DEST}/hdf5-${HDF5}
make -j ${procs}
make install

mark_done ${DEST} hdf5 hdf5-${HDF5} lib/libhdf5.so include/hdf5.h
