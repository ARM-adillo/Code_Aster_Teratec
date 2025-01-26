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
icheck=$?
# --- common ---

printf "\nBuild environment\n"
printf -- "-----------------\n"

printf "\nHost: ${host}\n"
printf "Arch: ${ARCH}\n"
[ ${enable_debug} -eq 1 ] && printf "Debug: enabled\n"

printf "\nCompilers\n"
printf "  CC:  ${CC}\n"
[ ! -z "${CFLAGS}" ] && printf "  CFLAGS: ${CFLAGS}\n"
${CC} --version
printf "  CXX: ${CXX}\n"
[ ! -z "${CXXFLAGS}" ] && printf "  CXXFLAGS: ${CXXFLAGS}\n"
${CXX} --version
printf "  FC:  ${FC}\n"
[ ! -z "${FCFLAGS}" ] && printf "  FCFLAGS: ${FCFLAGS}\n"
${FC} --version

printf "\nMaths libraries\n"
printf "  Scalapack:\n"
printf "    $(math_link_advisor scalapack)\n"
printf "  Blas/Lapack:\n"
printf "    $(math_link_advisor math)\n"
printf "  Blacs:\n"
printf "    $(math_link_advisor blacs)\n"
printf "  OpenMP:\n"
printf "    $(math_link_advisor openmp)\n"

printf "\nPython\n"
printf "  Version: $(get_python_version)\n"
printf "  Prefix: $(get_python_prefix)\n"
printf "  Library path: $(get_python_lib)\n"
printf "  Library name: $(get_python_libname)\n"
printf "  Headers: $(get_python_path prefix include)\n"
printf "User install paths:\n"
printf "  Modules: $(get_python_path user purelib)\n"

printf "\nModule environment: ${source_module}\n"
module list > /dev/null 2>&1 && module list

# printf "\nCustom configuration variables\n"
# echo ${CA_CFG_MEDCOUPLING}
# echo ${CA_CFG_MFRONT}

# exit with checkings status
exit ${icheck}
