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
_download_gitlab_tgz ${GITLAB} ${PETSC_ID} ${PETSC} petsc-${PETSC}.tar.gz
_download_gitlab_tgz ${GITLAB} ${PETSC_3RD_ID} ${PETSC_3RD} petsc-3rd-${PETSC_3RD}.tar.gz

rm -rf content && mkdir content
_extract_arch petsc-${PETSC}.tar.gz
_extract_arch petsc-3rd-${PETSC_3RD}.tar.gz
cd content

libscal="$(math_link_advisor scalapack) $(math_link_advisor blacs)"
libmath="-L/lib -lopenblas"
libs=$(math_link_advisor openmp)

export PETSC_DIR=${BUILD}/content
libmath="-L/lib -lopenblas"
export PYTHONPATH=${PETSC_DIR}/${PETSC_ARCH}/lib:${PYTHONPATH}

compilers_vars=( "CC=${CC}" "CXX=${CXX}" "FC=${FC}" )
[ ! -z "${CFLAGS}" ] && compilers_vars+=( CFLAGS="${CFLAGS}" )
[ ! -z "${CXXFLAGS}" ] && compilers_vars+=( CXXFLAGS="${CXXFLAGS}" )
[ ! -z "${FCFLAGS}" ] && compilers_vars+=( FCFLAGS="${FCFLAGS}" )

# METIS is embedded by libparmetis:  -L${DEST}/metis-${METIS}/lib -lmetis
# ensure to have consistent python3 and cython in PATH

# building slep4py needs access to petsc4py
export PYTHONPATH=${DEST}/petsc-${PETSC}/lib:${PYTHONPATH}
export LD_LIBRARY_PATH=${DEST}/mumps-${MUMPS}/lib:${DEST}/scotch-${SCOTCH}/lib:${DEST}/parmetis-${PARMETIS}/lib:${DEST}/scalapack-${SCALAPACK}/lib:${LD_LIBRARY_PATH}

python3 ./configure \
    --with-debugging=${enable_debug} \
    --with-mpi=1 \
    --with-ssl=0 \
    --with-x=0 \
    --with-64-bit-indices=0 \
    --with-mumps-lib="-L${DEST}/mumps-${MUMPS}/lib -lzmumps -ldmumps -lmumps_common -lpord -L${DEST}/scotch-${SCOTCH}/lib -lesmumps -lptscotch -lptscotcherr -lptscotcherrexit -lscotch -lscotcherr -lscotcherrexit -L${DEST}/parmetis-${PARMETIS}/lib -lparmetis" \
    --with-mumps-include=${DEST}/mumps-${MUMPS}/include \
    --with-blas-lapack-lib="${libmath}" \
    --with-scalapack-lib="${libscal}" \
    --with-python=1 \
    --with-petsc4py=1 \
    --download-ml=${BUILD}/content/3rd/pkg-trilinos-ml-${_ML}.tar.gz \
    --download-sowing=${BUILD}/content/3rd/sowing_${_SOWING}.tar.gz \
    --download-hypre=${BUILD}/content/3rd/hypre_${_HYPRE}.tar.gz \
    --download-superlu=${BUILD}/content/3rd/SuperLU_${_SUPERLU}.tar.gz \
    --download-slepc=${BUILD}/content/3rd/slepc-${_SLEPC}.tar.gz \
    --download-slepc-configure-arguments="--with-slepc4py --download-arpack=${BUILD}/content/3rd/arpack_${_ARPACK}.tar.gz" \
    --download-hpddm=${BUILD}/content/3rd/hpddm_${_HPDDM}.tar.gz \
    --with-openmp=1 \
    --prefix=${DEST}/petsc-${PETSC} \
    "${compilers_vars[@]}" \
    LIBS="${libs} -lz"
[ $? -eq 0 ] || exit 1

make -j ${procs} all
[ $? -eq 0 ] || exit 1

make -j ${procs} install
[ $? -eq 0 ] || exit 1

mark_done ${DEST} petsc petsc-${PETSC} \
    include/petsc.h \
    lib/libpetsc.so \
    lib/petsc4py/lib/__init__.py \
    lib/slepc4py/lib/__init__.py
