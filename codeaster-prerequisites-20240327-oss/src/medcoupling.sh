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
# access: public
_download_gitlab_tgz ${GITLAB} ${_CONFIGURATION_ID} ${_CONFIGURATION} configuration-${_CONFIGURATION}.tar.gz
_download_gitlab_tgz ${GITLAB} ${MEDCOUPLING_ID} ${MEDCOUPLING} medcoupling-${MEDCOUPLING}.tar.gz

rm -rf content && mkdir content
_extract_arch medcoupling-${MEDCOUPLING}.tar.gz
cd content

# workaround for hdf5 detection (only necessary in parallel)
HDF5VAR=HDF5_ROOT_DIR
if [ ${use_seq} -eq 0 ]; then
    HDF5VAR=HDF5_ROOT
    sed -i -e 's!FIND_PACKAGE(SalomeHDF5 REQUIRED)!FIND_PACKAGE(HDF5 REQUIRED)!' CMakeLists.txt
fi

# + configuration + swig, libxml2-devel
_extract_arch ../configuration-${_CONFIGURATION}.tar.gz
mv content configuration

mkdir build
cd build
if [ ${use_seq} -eq 1 ]; then
    on_mpi="OFF"
    on_seq="ON"
else
    on_mpi="ON"
    on_seq="OFF"
fi
build_type=Release
if [ ${enable_debug} -eq 1 ]; then
    build_type=Debug
fi
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${DEST}/medcoupling-${MEDCOUPLING} \
    -DCONFIGURATION_ROOT_DIR=${BUILD}/content/configuration \
    -DPYTHON_ROOT_DIR=$(get_python_prefix) \
    -DSWIG_EXECUTABLE=/usr/bin/swig \
    -DSALOME_CMAKE_DEBUG=ON \
    -DSALOME_USE_MPI=${on_mpi} \
    -DMEDCOUPLING_BUILD_TESTS=OFF \
    -DMEDCOUPLING_BUILD_DOC=OFF \
    -DMEDCOUPLING_USE_64BIT_IDS=ON \
    -DMEDCOUPLING_USE_MPI=${on_mpi} \
    -DMEDCOUPLING_MEDLOADER_USE_XDR=OFF \
    -DXDR_INCLUDE_DIRS="" \
    -DMEDCOUPLING_PARTITIONER_PARMETIS=OFF \
    -DMEDCOUPLING_PARTITIONER_METIS=OFF \
    -DMEDCOUPLING_PARTITIONER_SCOTCH=OFF \
    -DMEDCOUPLING_PARTITIONER_PTSCOTCH=${on_mpi} \
    -DMPI_C_COMPILER:PATH=$(which mpicc) \
    -DMPI_CXX_COMPILER:PATH=$(which mpicxx) \
    -DPYTHON_EXECUTABLE:FILEPATH=$(which python3) \
    -D${HDF5VAR}=${DEST}/hdf5-${HDF5} \
    -DMEDFILE_ROOT_DIR=${DEST}/med-${MED} \
    -DSCOTCH_ROOT_DIR=${DEST}/scotch-${SCOTCH} \
    -DSCOTCH_INCLUDE_DIRS=${DEST}/scotch-${SCOTCH}/include \
    -DMETIS_ROOT_DIR=${DEST}/metis-${METIS} \
    -DMETIS_INCLUDE_DIRS=${DEST}/metis-${METIS}/include \
    -DPTSCOTCH_ROOT_DIR=${DEST}/scotch-${SCOTCH} \
    -DPTSCOTCH_INCLUDE_DIRS=${DEST}/scotch-${SCOTCH}/include \
    -DPARMETIS_ROOT_DIR=${DEST}/parmetis-${PARMETIS} \
    -DPARMETIS_INCLUDE_DIRS=${DEST}/parmetis-${PARMETIS}/include \
    "${CA_CFG_MEDCOUPLING[@]}" \
    -DCMAKE_BUILD_TYPE=${build_type}

make -j ${procs}
make install

mark_done ${DEST} medcoupling medcoupling-${MEDCOUPLING} \
    lib/libmedcoupling.so \
    $(get_python_path user purelib)/medcoupling.py
