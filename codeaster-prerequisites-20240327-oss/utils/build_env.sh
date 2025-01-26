# set build environment
utils=$(readlink -n -f $(dirname ${BASH_SOURCE}))

# decode ARCH to comp/math/para
comp=$(awk -F'[-_]' '{print $1}' <<< "${ARCH}")
math=$(awk -F'[-_]' '{print $2}' <<< "${ARCH}")
para=$(awk -F'[-_]' '{print $3}' <<< "${ARCH}")
suffix=$(awk -F'[-_]' '{print $4}' <<< "${ARCH}")

. ${utils}/general.sh
. ${utils}/func_cache.sh
. ${utils}/global_variables.sh
. ${utils}/gitlab_projects.sh

# scripts should only use these variables
use_gcc=0
use_intel=0
use_mkl=0
use_mkl_scalapack=0
use_seq=1
use_ompi=0
use_impi=0
enable_debug=0
use_restricted=${RESTRICTED}

# autoset variables
if [ "${comp:0:3}" = "gcc" ]; then
    use_gcc=1
    export CC=gcc FC=gfortran CXX=g++
fi
if [ "${comp:0:5}" = "intel" ]; then
    use_intel=1
    export CC=icc FC=ifort CXX=icpc
fi
if [ "${math:0:3}" = "mkl" ]; then
    use_mkl=1
fi
if [ "${para:0:4}" = "ompi" ]; then
    use_ompi=1
    export CC=mpicc FC=mpif90 CXX=mpicxx
fi
if [ "${para:0:4}" = "impi" ]; then
    use_impi=1
    export CC=mpiicc FC=mpiifort CXX=mpiicpc
fi
WAF_SUFFIX="std"
if [ ${use_ompi} -eq 1 ] || [ ${use_impi} -eq 1 ]; then
    use_seq=0
    WAF_SUFFIX="mpi"
fi
if grep -q "debug" <<< "${suffix}"; then
    enable_debug=1
    export CXXFLAGS="-D__GLIBCXX_DEBUG ${CXXFLAGS}"
fi

# source lmod.sh/modules.sh if necessary
source_module=/etc/profile.d/lmod.sh
if [ -f "${source_module}" ]; then
    . "${source_module}"
else
    source_module=/etc/profile.d/modules.sh
    if [ -f "${source_module}" ]; then
        . "${source_module}"
    else
        source_module=
    fi
fi
module list > /dev/null 2>&1
use_mod=$((1-$?))

# build environment
cfg_addmem=2800
cfg_mpiexec=
cfg_require_mpiexec=
cfg_addons=
host=$(detect_host)
if [ "${host}" = "cronos" ]; then
    export MODULEPATH=/software/shared/easybuild/modules/all
    if [ "${comp}" = "gcc12" ]; then
        module load compilateur/gcc/12.2
    fi
    if [ "${para}" = "ompi4" ]; then
        module load openmpi-bull/4.1.1
    fi

    if [ "${comp}" = "intel19" ]; then
        module load iccifort/2019.5.281
    fi
    if [ "${para}" = "impi19" ]; then
        # included by intel: imkl/2019.5.281-iimpi-2019.5.281
        module load impi/2019.5.281/2019.5.281-iccifort-2019.5.281
    fi
    if [ "${comp}" = "intel23" ]; then
        module load intel-compilers/2023.2.1
        export CC=icx FC=ifx CXX=icpx
    fi
    if [ "${para}" = "impi21" ]; then
        module load impi/2021.10.0/2021.10.0-intel-compilers-2023.2.1
        export CC="mpicc -cc=icx" FC="mpif90 -fc=ifx" CXX="mpicxx -cxx=icpx"
    fi
    if [ ${use_mkl} -eq 1 ]; then
        if [ "${para}" = "impi19" ]; then
            module load imkl/2019.5.281-iimpi-2019.5.281
        elif [ "${para}" = "impi21" ]; then
            module load imkl/2023.2.0
        else
            module load imkl/2020.4.304
        fi
    fi
    # very high in interactive executions...
    cfg_addmem=7500
    cfg_mpiexec="mpiexec -n {mpi_nbcpu} --bind-to none --tag-output {program}"
    cfg_require_mpiexec=1
    # add native path for LD_PRELOAD automation
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib64
    # to use generic asrun configuration
    export CA_CFG_ASRUN_ETC=/software/restricted/simumeca/aster/etc
fi

if [ "${host}" = "gaia" ]; then
    # boost and swig are in /projets/tools/modules
    module use -a /projets/tools/modules
    module load cmake/3.24.1 python/3.6.5 numpy/1.15.1 boost/1.72.0 \
        swig/4.0.2 python3-scipy/0.19.1 python3-matplotlib/2.2.2

    if [ "${comp}" = "gcc8" ]; then
        module load gcc/8.3.0
    fi

    if [ "${comp}" = "gcc10" ]; then
        module load compilateurs/gcc/10.2
    fi

    if [ "${para}" = "ompi4" ]; then
        module load openmpi/4.0.3-ifs
    fi

    if [ "${para}" = "ompi3" ]; then
        module load openmpi/3.1.4-ifs
    fi

    if [ "${para}" = "ompi2" ]; then
        module load openmpi/2.1.2-ifs10.7
    fi

    if [ "${comp}" = "intel19" ]; then
        module load ifort/2019.0.045 icc/2019.0.045
    fi
    if [ "${para}" = "impi19" ]; then
        module load impi/2019.0.045
    fi
    if [ ${use_mkl} -eq 1 ]; then
        module load mkl/2019.4.070
    fi
    cfg_mpiexec="mpiexec -n {mpi_nbcpu} --bind-to none --tag-output {program}"

    export BOOST_LIB="boost_python36"
    export BOOST_ROOT="/projets/tools/boost/boost_1_72_0"
    export CA_CFG_MFRONT=(
        "-DPYTHONLIBS_VERSION_STRING=3.6.5"
        "-DBOOST_ROOT=${BOOST_ROOT}"
    )
    export CA_CFG_MEDCOUPLING=( "-DBOOST_ROOT=${BOOST_ROOT}" )
    # to use generic asrun configuration
    export CA_CFG_ASRUN_ETC=/projets/simumeca/etc
fi

if [ "${host}" = "hpc-aws-rh8" ]; then
    export MODULEPATH=${MODULEPATH}:/efs/tools/modulefiles
    if [ "${comp}" = "gcc12" ] && ( ! grep -q "gcc-toolset-12" <<< "${X_SCLS}" ); then
        echo "ERROR: you must enable the environment with 'scl enable gcc-toolset-12 bash'"
        exit 1
    fi
    if [ "${para}" = "ompi5" ]; then
        export PATH=${PATH}:/opt/parallelcluster/shared/ompi5_imp/ompi5-improved/install/bin
    fi
    if [ ${use_mkl} -eq 1 ]; then
        module load mkl/2023.1.0
    fi

    cfg_addons=(
        "export LD_PRELOAD=\${LD_PRELOAD}:/lib64/libgomp.so.1"
        "export PATH=\"$(compiler_mpi_advisor bin):\${PATH}\""
    )

    export BOOST_LIB="boost_python39"
    export BOOST_ROOT="${ROOT}/boost-1.82.0"
    export CA_CFG_MFRONT=(
        "-DPYTHONLIBS_VERSION_STRING=3.9"
        "-DBOOST_ROOT=${BOOST_ROOT}"
    )
    export CA_CFG_MEDCOUPLING=(
        "-DPYTHONLIBS_ROOT_DIR=${ROOT}/pyenvs/versions/3.9-dev"
        "-DBOOST_ROOT=${BOOST_ROOT}"
    )
fi

if [ "${host}" = "scibian10" ]; then
    CA_CFG_MFRONT=( "-DPYTHONLIBS_VERSION_STRING=3.7.3"
                    "-DPYTHON_INCLUDE_DIR:PATH=/usr/include/python3.7m" )
fi

printf "Checking virtual environment for '${CURRENT_PRODUCT}'... "
if [ -d ".venv_${CURRENT_PRODUCT}" ]; then
    source .venv_${CURRENT_PRODUCT}/bin/activate
    echo "'.venv_${CURRENT_PRODUCT}' activated"
    # in a venv, PATH is extended but not PYTHONPATH
    export PYTHONPATH=${VIRTUAL_ENV}/$(get_python_path user platlib):${VIRTUAL_ENV}/$(get_python_path user purelib):${PYTHONPATH}
else
    echo "no"
fi

if [ ${use_gcc} -eq 1 ]; then
    check_gcc_100227
    if [ $? -ne 0 ]; then
        echo "ERROR: check_gcc_100227 failed"
        exit 1
    fi

    check_gfortran10_rank
    if [ $? -ne 0 ]; then
        echo "ERROR: check_gfortran10_rank failed"
        exit 1
    fi
fi

if [ ${use_restricted} -eq 0 ]; then
    export MUMPS=${MUMPS_GPL}
    export ECREVISSE=${ECREVISSE_GPL}
fi
