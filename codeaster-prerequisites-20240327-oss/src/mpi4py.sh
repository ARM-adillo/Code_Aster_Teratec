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

if [ ${use_seq} -eq 1 ] || check_mpi4py_version ${MPI4PY}; then
    mark_done ${DEST} mpi4py mpi4py-${MPI4PY}
    exit 0
fi

cd ${BUILD}
# access: ci-prereq-read-api
_download_gitlab_tgz ${GITLAB} ${MPI4PY_ID} ${MPI4PY} mpi4py-${MPI4PY}.tar.gz

rm -rf content && mkdir content
_extract_arch mpi4py-${MPI4PY}.tar.gz
cd content
python3 setup.py install --prefix=${DEST}/mpi4py-${MPI4PY}

mark_done ${DEST} mpi4py mpi4py-${MPI4PY} \
    $(get_python_path user platlib)/mpi4py/__init__.py
