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
_download_curl_tgz ${PREREQ_URL}/med-${MED}.tar.gz

rm -rf content && mkdir content
_extract_arch med-${MED}.tar.gz
cd content

if [ ${MED} = "4.1.1" ]; then
    patch -p1 < ${prefix}/patches/med-4.1.1-check-hdf5-with-tabs.diff
    patch -p1 < ${prefix}/patches/med-4.1.1-check-hdf5-parallel.diff
fi

opts=("--with-swig=yes" )

# Set only fortran length for integer, C/C++ flags will be automatically adapted
export FFLAGS="-fdefault-integer-8 ${FFLAGS}"
export FCFLAGS="-fdefault-integer-8 ${FCFLAGS}"

if [ ${enable_debug} -eq 1 ]; then
    export CFLAGS="-g ${CFLAGS}"
    export CXXFLAGS="-g ${CXXFLAGS}"
    export FCFLAGS="-g ${FCFLAGS}"
    opts+=( "--enable-mesgerr" )
else
    opts+=( "--disable-mesgerr" )
fi
opts+=( "--disable-static" )

export F77=${FC}
alias python=python3
CXXFLAGS='-std=gnu++98' PYTHON=$(which python3) \
    ./configure "${opts[@]}" --with-hdf5=${DEST}/hdf5-${HDF5} --prefix=${DEST}/med-${MED}
[ $? -eq 0 ] || exit 1

make -j ${procs}
[ $? -eq 0 ] || exit 1

make install
[ $? -eq 0 ] || exit 1

unalias python

# documentation costs >100 MB
rm -rf ${DEST}/med-${MED}/share/doc/med

mark_done ${DEST} med med-${MED} \
    lib/libmed.so include/med.h \
    $(get_python_path user platlib)/med/__init__.py
