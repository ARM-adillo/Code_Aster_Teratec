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
_download_gitlab_tgz ${GITLAB} ${SCOTCH_ID} v${SCOTCH} scotch-${SCOTCH}.tar.gz

rm -rf content && mkdir content
_extract_arch scotch-${SCOTCH}.tar.gz
cd content/src

shared=1
libext=.so
mkinc=Make.inc/Makefile.inc.x86-64_pc_linux2.shlib
if [ ${shared} -ne 1 ]; then
    mkinc=Make.inc/Makefile.inc.x86-64_pc_linux2
    libext=.a
fi

# check for MPI_THREAD_MULTIPLE support
# mpi4py should use MPI_Init_Thread if MPI_THREAD_MULTIPLE is enabled
# see https://bugzilla.redhat.com/show_bug.cgi?id=1386707
check_mpi_thread_multiple_support
# disable_mpi_thread=$?
# ... but
disable_mpi_thread=1

if [ ${enable_debug} -eq 1 ]; then
    export CFLAGS="-g ${CFLAGS}"
fi
if [ ${use_seq} -eq 1 ]; then
    sed -e "s/CFLAGS\s*=/CFLAGS = ${CFLAGS} -Wl,--no-as-needed -DINTSIZE64/g" \
        -e "s/CCD\s*=.*$/CCD = cc/g" ${mkinc} > Makefile.inc
    make scotch -j ${procs}
    make esmumps -j ${procs}
    mkdir -p ${DEST}/scotch-${SCOTCH}
    make install prefix=${DEST}/scotch-${SCOTCH}
    mark_done ${DEST} scotch scotch-${SCOTCH} lib/libscotch${libext} include/scotch.h
else
    sed -e "s/CFLAGS\s*=/CFLAGS = ${CFLAGS} -Wl,--no-as-needed -DINTSIZE64/g" \
        -e "s/CCD\s*=.*$/CCD = mpicc/g" ${mkinc} > Makefile.inc
    if [ ${disable_mpi_thread} -eq 1 ]; then
        sed -i -e "s/-DSCOTCH_PTHREAD_MPI//g" -e "s/-DSCOTCH_PTHREAD//g" Makefile.inc
    fi

    make scotch -j ${procs}
    make ptscotch -j ${procs}
    make esmumps -j ${procs}
    mkdir -p ${DEST}/scotch-${SCOTCH}
    make install prefix=${DEST}/scotch-${SCOTCH}
    cp Makefile.inc ${DEST}/scotch-${SCOTCH}/share/
    mark_done ${DEST} scotch scotch-${SCOTCH} lib/libscotch${libext} include/scotch.h \
        lib/libptscotch${libext} include/ptscotch.h
fi
