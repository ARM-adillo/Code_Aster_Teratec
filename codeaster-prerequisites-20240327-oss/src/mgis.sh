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
_download_gitlab_tgz ${GITLAB} ${MGIS_ID} $([ ! -z "${MGIS_SHA}" ] && echo ${MGIS_SHA} || echo MFrontGenericInterfaceSupport-${MGIS}) mgis-${MGIS}.tar.gz

rm -rf content && mkdir content
_extract_arch mgis-${MGIS}.tar.gz
cd content
if [ ${MGIS} = "2.2" ]; then
    patch -p1 < ${prefix}/patches/mgis-2.2-regexp-pythonlibs-version.diff
fi

mkdir build
cd build

pysuffix=$(sed 's/[\.\-]/_/g' <<< "${MGIS}")

build_type=Release
if [ ${enable_debug} -eq 1 ]; then
    build_type=Debug
fi
cmake .. \
    -DCMAKE_BUILD_TYPE=${build_type} \
    -DMGIS_APPEND_SUFFIX=ON \
    -DMGIS_SUFFIX=${MGIS} \
    -DMGIS_SUFFIX_FOR_PYTHON_MODULES=${pysuffix} \
    -Denable-website=OFF \
    -Denable-c-bindings=OFF -Denable-fortran-bindings=OFF \
    -Denable-broken-boost-python-module-visibility-handling=ON \
    -Denable-python-bindings=ON \
    -Denable-portable-build=ON \
    -Denable-python=ON \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -DPYTHON_LIBRARY:FILEPATH=$(get_python_libname) \
    -DPYTHON_INCLUDE_DIR:PATH=$(get_python_path prefix include) \
    "${CA_CFG_MFRONT[@]}" \
    -DCMAKE_INSTALL_PREFIX=${DEST}/mgis-${MGIS}
make -j ${procs}
make install

# should be installed in 'platlib'
mark_done ${DEST} mgis mgis-${MGIS} \
    lib/libMFrontGenericInterface.so \
    $(get_python_path user purelib)
