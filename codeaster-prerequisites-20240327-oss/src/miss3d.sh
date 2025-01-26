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
_download_gitlab_tgz ${GITLAB} ${MISS3D_ID} ${MISS3D} miss3d-${MISS3D}.tar.gz

rm -rf content && mkdir content
_extract_arch miss3d-${MISS3D}.tar.gz
cd content

libmath=$(math_link_advisor math)
libopenmp=$(math_link_advisor openmp)

if [ "${use_intel}" -eq 1 ]; then
    cp src/Makefile.inc.intel64.template src/Makefile.inc
else
    cat << EOF > src/Makefile.inc
# GNU Fortran 64 bits
# -------------------
F90 = gfortran
F90FLAGS = -O3 -mcmodel=small -fopenmp -fbacktrace -fdefault-double-8 -fdefault-integer-8 -fdefault-real-8 -fallow-argument-mismatch

LD = gfortran
LDFLAGS = -I../common -mcmodel=small -fopenmp -fbacktrace ${libmath} ${libopenmp} -lpthread -fallow-argument-mismatch
EOF
fi
sed -i -e "s%LIBMATH%${libmath}%g" -e "s%LIBOPENMP%${libopenmp}%g" src/Makefile.inc
cat << EOF >> src/Makefile.inc

F90FLAGS += \$(FCFLAGS)
EOF

mkdir -p ${DEST}/miss3d-${MISS3D}/bin ${DEST}/miss3d-${MISS3D}/lib
make -j ${procs}
make prefix=${DEST}/miss3d-${MISS3D} install

mark_done ${DEST} miss3d miss3d-${MISS3D} \
    lib/default/miss3d.x lib/run_miss3d bin/run_miss3d
