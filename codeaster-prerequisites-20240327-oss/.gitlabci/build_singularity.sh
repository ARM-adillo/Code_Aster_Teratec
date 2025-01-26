#!/bin/bash

variant="$1"
branch="$2"
build_type="$3"
suffix="-next"

if [ "${build_type}" = "release" ]; then
    build_type=""
else
    build_type="-${build_type}"
fi
[ "${branch}" = "main" ] && suffix=""
[ $(awk -F/ '{print $1}' <<< "${branch}") = "maint" ] && suffix=""

echo "+ $(date) - building Singularity image ${variant}..."
source VERSION
dest=codeaster-prerequisites-${VERSION}-${variant}${build_type}${suffix}.sif

export SINGULARITYENV_GITLAB_PREREQ_TOKEN="${GITLAB_PREREQ_TOKEN}"
export SINGULARITYENV_PREREQ_ARCH_SUFFIX="${build_type}"

make distclean

echo ${variant} | grep -q -- "-oss"
iret=$?
if [ ${iret} -eq 0 ]; then
    # use same recipe as for non "-oss"
    variant=${variant%-*}
    # extract...
    tar xvf artf/archive-oss.tar.gz
    # ... and use archive
    cd codeaster-prerequisites-${VERSION}-oss
fi

singularity build --nohttps ${dest} container/${variant}.def

if [ ${iret} -eq 0 ]; then
    mv ${dest} ../artf/
else
    mv ${dest} artf/
fi
