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

# skipped in sequential or if provided within mkl
if [ ${use_seq} -eq 1 ] || [ ${use_mkl_scalapack} -eq 1 ]; then
    mkdir -p ${DEST}/scalapack-${SCALAPACK}/lib
    echo "# not used" > ${DEST}/scalapack-${SCALAPACK}/lib/none
    mark_done ${DEST} scalapack scalapack-${SCALAPACK}
    exit 0
fi

cd ${BUILD}
_download_curl_tgz ${PREREQ_URL}/scalapack-${SCALAPACK}.tar.gz

rm -rf content && mkdir content
_extract_arch scalapack-${SCALAPACK}.tar.gz
cd content
mkdir build
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_Fortran_FLAGS="${FCFLAGS}" \
    -DLAPACK_LIBRARIES="$(math_link_advisor math) $(math_link_advisor openmp)" \
    -DCMAKE_INSTALL_PREFIX=${DEST}/scalapack-${SCALAPACK}
# -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON

make -j ${procs}
make install

mark_done ${DEST} scalapack scalapack-${SCALAPACK} lib/libscalapack.so
