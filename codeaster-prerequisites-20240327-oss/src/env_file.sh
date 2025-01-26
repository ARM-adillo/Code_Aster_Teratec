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

declare -a options=(
    "--os=${host}"
    "--root=${DEST}"
    "--dest=${DEST}"
    "--check"
)
if [ ${use_seq} -eq 1 ]; then
    options+=( "--variant=seq" )
    profile="${host}_std.sh"
else
    options+=( "--variant=mpi" )
    profile="${host}_mpi.sh"
fi

versfile=$(mktemp /tmp/env_file.XXXXXX)
options+=( "--version_file=${versfile}" )
cp ${prefix}/VERSION ${versfile}
if [ ${use_seq} -eq 1 ] || [ ${use_mkl_scalapack} -eq 1 ]; then
    grep -v SCALAPACK ${prefix}/VERSION > ${versfile}
fi
if [ ${use_restricted} -eq 0 ]; then
    sed -i -e "s/_GPL//g" ${versfile}
fi

tmpf=$(mktemp /tmp/env_file.XXXXXX)
if [ ${use_mod} -eq 1 ]; then
    module list 2>&1 | grep -v "Loaded Modules" | grep -v "No modules" > ${tmpf}
fi
cat << EOF | python3 - ${tmpf} > ${tmpf}.ml
from glob import glob
import os
import os.path as osp
import re
import sys
with open(sys.argv[1]) as fobj:
    txt = fobj.read()

expr = re.compile("([a-z0-9_\-]+/[a-z0-9\.\-\+]+)(?: +|$)", re.M | re.I)
all = expr.findall(txt)
mod = [i for i in all
       if not i.startswith("cmake") and not i.startswith("swig")]

lines = []
if mod:
    lines.append("")
    if "${source_module}":
        lines.append(". ${source_module}")
    if "${MODULEPATH}":
        lines.append("module use " + "${MODULEPATH}".replace(":", " ").strip())
    lines.append("module load " + " ".join(mod))

def _preload(cmdargs):
    preload = []
    args = cmdargs.split()
    paths = [re.sub("^-L", "", i) for i in args if i.startswith("-L")]
    paths.extend(os.environ.get("LD_LIBRARY_PATH", "").split(":"))
    libs = [re.sub("^-l", "", i) for i in args if i.startswith("-l")]
    for name in libs:
        for src in paths:
            libname = osp.join(src, "lib" + name + ".so")
            fnames = [libname] + glob(libname + "*")
            found = False
            for lib in fnames:
                if osp.exists(lib):
                    preload.append(lib)
                    found = True
                    break
            if found:
                break
    return preload

preload = []
if ${use_mkl}:
    if ${use_mkl_scalapack}:
        preload.extend(_preload("-lmpi"))
        preload.extend(_preload("$(math_link_advisor scalapack)"))
    preload.extend(_preload("$(math_link_advisor math)"))
    preload.extend(_preload("$(math_link_advisor openmp)"))
    if ${use_mkl_scalapack}:
        preload.extend(_preload("$(math_link_advisor blacs)"))

if preload:
    lines.extend(["", "export LD_PRELOAD=\\\\\n" + ":\\\\\n".join(preload)])
print("\n".join(lines))
EOF

(
    echo
    echo "# custom configuration"
    if [ ! -z "${cfg_addmem}" ]; then
        echo "export CONFIG_PARAMETERS_addmem=${cfg_addmem}"
    fi
    if [ ! -z "${cfg_mpiexec}" ]; then
        echo "export CONFIG_PARAMETERS_mpiexec=\"${cfg_mpiexec}\""
    fi
    if [ ! -z "${cfg_require_mpiexec}" ]; then
        echo "export CONFIG_PARAMETERS_require_mpiexec=\"${cfg_require_mpiexec}\""
    fi
    for line in "${cfg_addons[@]}"
    do
        echo "${line}"
    done
)  >> "${tmpf}.ml"

options+=( "--addon=${tmpf}.ml" )
python3 ${prefix}/utils/generate_env.py "${options[@]}"

# keep a trace in the log file
cat "${DEST}/${profile}"
printf "\n"

rm -f ${tmpf} ${tmpf}.ml

mark_done ${DEST} env_file "." "${profile}"
