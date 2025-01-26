#!/bin/bash

set_prefix() {
    local this=$(readlink -n -f "${1}")
    local src=$(dirname "${this}")
    prefix=$(dirname "${src}")
}

set_prefix "${0}"

. ${prefix}/VERSION
. ${prefix}/utils/build_env.sh

tmpf=$(mktemp /tmp/download_only.XXXXXX)

(
    echo ". ${prefix}/VERSION"
    echo ". ${prefix}/utils/build_env.sh"
    echo "arch=${prefix}/archives"
    echo "rm -rf \${arch}/* && mkdir -p \${arch} && cd \${arch}"
    echo "echo \"downloading archives to \${arch} (using cache as ${CACHE})...\""
    grep _download_ ${prefix}/src/* | awk -F: '{print $2}'
) > ${tmpf}

bash ${tmpf}
rm -f ${tmpf}
