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

build_venv() {
    prod="$1"
    printf "\nSetting virtual environments for '${prod}'...\n\n"
    python3 -m pip freeze -l > reqs/requirements_previously_installed.txt
    python3 -m venv --system-site-packages --prompt 'venv' .venv_${prod}
    . .venv_${prod}/bin/activate
    python3 -m pip install ${PIP_OPTIONS} -r reqs/requirements_previously_installed.txt
    python3 -m pip install ${PIP_OPTIONS} -r reqs/requirements_${prod}.txt
    echo
}

build_venv mpi4py
build_venv petsc
