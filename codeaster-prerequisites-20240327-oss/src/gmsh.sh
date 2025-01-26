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
_download_curl_tgz ${PREREQ_URL}/gmsh-${GMSH}.tar.gz

rm -rf content && mkdir content
_extract_arch gmsh-${GMSH}.tar.gz
rm -rf ${DEST}/gmsh-${GMSH}
mv content ${DEST}/gmsh-${GMSH}

mark_done ${DEST} gmsh gmsh-${GMSH} bin/gmsh
