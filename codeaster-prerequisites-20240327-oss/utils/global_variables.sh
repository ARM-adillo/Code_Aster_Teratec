# Nexus repository of archives
PREREQ_URL=https://minio.retd.edf.fr/codeaster/containers-data/prerequisites

procs=$(nproc)
if [ $(nproc) -gt 8 ]; then
    procs=$(($(nproc)-2))
fi

# metis does not properly support submake
unset $(printenv | egrep '^MAKE' | awk -F= '{print $1}')

# convenient getters for "system" prerequisites: python, numpy, boost
get_python_version()
{
    python3 -c "import sysconfig ; print(sysconfig.get_python_version())"
}

get_python_prefix()
{
    python3 -c "import sys ; print(sys.prefix)"
}

get_python_lib()
{
    python3 -c "import sysconfig ; print(sysconfig.get_config_var('LIBDIR'))"
}

get_python_libname()
{
    local name=$(python3 -c "import sysconfig ; print(sysconfig.get_config_var('LDLIBRARY'))")
    find "$(get_python_lib)" -follow -type f -name "${name}" 2> /dev/null | head -1
}

get_python_path()
{
    if [ $# -ne 2 ]; then
        echo "usage: get_python_path scheme name"
        echo "  scheme: prefix / user"
        echo "  name: platlib / purelib / include"
        exit 1
    fi
    cat << EOF | python3 -
import os, sysconfig
paths = sysconfig.get_paths(os.name + "_${1}")
res = paths["${2}"]
if "${1}" == "user":
    res = res.replace(paths["data"], "").lstrip("/")
print(res)
EOF
}
