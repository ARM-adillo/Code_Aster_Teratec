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
_download_gitlab_tgz ${GITLAB} ${ASRUN_ID} ${ASRUN} codeaster-frontend-${ASRUN}.tar.gz

rm -rf content && mkdir content
_extract_arch codeaster-frontend-${ASRUN}.tar.gz
cd content

# add configuration for editor, terminal, platform...
cat << EOF > external_configuration.py
parameters = {
    "IFDEF": "LINUX64",
    "EDITOR": "gedit",
    "TERMINAL": "xterm",
    "CTAGS_STYLE": ""
}
EOF
export PYTHONPATH=.:$PYTHONPATH
python3 setup.py install --prefix=${DEST}/asrun-${ASRUN}

if [ ! -z "${CA_CFG_ASRUN_ETC}" ]; then
    mv ${DEST}/asrun-${ASRUN}/etc ${DEST}/asrun-${ASRUN}/etc.installed
    ln -s "${CA_CFG_ASRUN_ETC}" ${DEST}/asrun-${ASRUN}/etc
fi

mark_done ${DEST} asrun asrun-${ASRUN} bin/as_run \
    $(get_python_path user purelib)/asrun/run.py
