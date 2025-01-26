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
# access: ci-prereq-read-api
# should be on a single line for 'download_only'
_download_gitlab_tgz ${GITLAB} ${MFRONT_ID} $([ ! -z "${MFRONT_SHA}" ] && echo ${MFRONT_SHA} || echo TFEL-${MFRONT}) tfel-${MFRONT}.tar.gz

rm -rf content && mkdir content
_extract_arch tfel-${MFRONT}.tar.gz
cd content
if [ ${MFRONT} = "4.2.0" ]; then
    patch -p1 < ${prefix}/patches/tfel-4.2.0-regexp-pythonlibs-version.diff
fi

mkdir build
cd build

build_type=Release
if [ ${enable_debug} -eq 1 ]; then
    build_type=Debug
fi

if [ "${host}" = "gaia" ]; then
    # it seems that version >=4 needs a more recent boost version
    pybindings=()
    pydone=()
else
    pybindings=(
        "-Denable-python=ON"
        "-Denable-python-bindings=ON "
        "-Denable-broken-boost-python-module-visibility-handling=ON "
        "-DPYTHON_EXECUTABLE:FILEPATH=$(which python3)"
        "-DPYTHON_LIBRARY:FILEPATH=$(get_python_libname)"
        "-DPYTHON_INCLUDE_DIR:PATH=$(get_python_path prefix include)"
    )
    # should be installed in 'platlib'
    pydone=( $(get_python_path user purelib) )
fi

cmake .. \
    -DCMAKE_BUILD_TYPE=${build_type} \
    -DTFEL_SVN_REVISION=${MFRONT} -DTFEL_APPEND_VERSION=${MFRONT} \
    -Ddisable-reference-doc=ON -Ddisable-website=ON \
    -Denable-aster=ON \
    -Denable-portable-build=ON \
    "${pybindings[@]}" \
    "${CA_CFG_MFRONT[@]}" \
    -DCMAKE_INSTALL_PREFIX=${DEST}/mfront-${MFRONT}
make -j ${procs}
make install

mark_done ${DEST} mfront mfront-${MFRONT} \
    include/TFEL-${MFRONT}/TFEL/System \
    lib/libTFELMFront-${MFRONT}.so \
    "${pydone[@]}"
