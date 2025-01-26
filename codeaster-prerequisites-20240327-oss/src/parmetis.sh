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

if [ ${use_seq} -eq 1 ]; then
    mark_done ${DEST} parmetis parmetis-${PARMETIS}
    exit 0
fi
if [ ${use_impi} -eq 1 ]; then
    export CC=mpiicc FC=mpiifort CXX=mpiicpc
fi

cd ${BUILD}
# access: ci-prereq-read-api
_download_gitlab_tgz ${GITLAB} ${PARMETIS_ID} ${PARMETIS} parmetis-${PARMETIS}.tar.gz

rm -rf content && mkdir content
_extract_arch parmetis-${PARMETIS}.tar.gz
cd content

shared=1
if [ ${enable_debug} -eq 1 ]; then
    export CFLAGS="-g ${CFLAGS}"
fi

make config CFLAGS="-fPIC ${CFLAGS}" \
    prefix=${DEST}/parmetis-${PARMETIS} \
    shared=${shared}
# gklib_path=${DEST}/metis-${METIS} \
# metis_path=${DEST}/metis-${METIS} \
# i64=1 r64=1

make -j ${procs}

# rebuild libparmetis.so to include all .o from libmetis and GKlib
pushd build/Linux-x86_64/libparmetis > /dev/null
all_metis_o=$(find ../libmetis -name '*.o' | tr '\n' ' ')
sed -i -e "s%../libmetis/libmetis.a%${all_metis_o}%g" CMakeFiles/parmetis.dir/link.txt
popd > /dev/null

make install

libext=.so
[ ${shared} -ne 1 ] && libext=.a
mkdir -p ${DEST}/metis-${METIS}/{lib,include}
# cp build/*/libmetis/libmetis${libext} ${DEST}/metis-${METIS}/lib/
cp metis/include/metis.h ${DEST}/metis-${METIS}/include/

mark_done ${DEST} parmetis parmetis-${PARMETIS} \
    lib/libparmetis${libext} \
    ../metis-${METIS}/include/metis.h \
    include/parmetis.h
