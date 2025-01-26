#!/bin/bash

set_prefix() {
    local this=$(readlink -n -f "${1}")
    local src=$(dirname "${this}")
    prefix=$(dirname "${src}")
}

set_prefix "${0}"

. ${prefix}/VERSION
. ${prefix}/utils/build_env.sh

branch=$(git branch | egrep '^\*' | sed -s 's/^\* *//')
if [ ! -z "${CI_COMMIT_REF_NAME}" ]; then
    branch=HEAD
fi
archive=codeaster-prerequisites-${VERSION}
if [ ${use_restricted} -eq 0 ]; then
    archive=${archive}-oss
fi

echo "archiving branch ${branch} to ${archive}.tar..."
rm -f ${archive}.tar ${archive}.tar.gz
git archive ${branch} --prefix ${archive}/ -o ${archive}.tar

echo "adding archives..."
tar xf ${archive}.tar
cp -rp archives ${archive}/
printf "\nRESTRICTED=${use_restricted}\n" >> ${archive}/VERSION
tar --append -f ${archive}.tar ${archive}/VERSION ${archive}/archives/

echo "creating ${archive}.tar.gz..."
rm -rf ${archive}/
gzip -9 ${archive}.tar
