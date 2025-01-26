#!/bin/bash
#SBATCH --partition=c8g
#SBATCH --job-name=run_ctest_aster
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
export WAFBUILD_ENV=$(readlink -n -f ${BASH_SOURCE})

# DEVTOOLS_COMPUTER_ID avoids waf to re-source the environment
export DEVTOOLS_COMPUTER_ID=ip-10-0-8-45

export PREREQ_PATH=/fsx/home/etud8-4/aster/20240327/conradbigbrain
export PREREQ_VERSION=20240327

# force parallel build
export ENABLE_MPI=0

. /etc/profile.d/modules.sh
module use /tools/acfl/24.04/modulefiles/gnu/../../moduledeps/gnu/13.2.0 /tools/acfl/24.04/modulefiles/acfl/../../moduledeps/acfl/24.04 /tools/acfl/24.04/modulefiles /opt/amazon/modules/modulefiles /opt/amazon/modules/modulefiles /usr/share/Modules/modulefiles /etc/modulefiles
module load binutils/13.2.0 acfl/24.04 gnu/13.2.0

# custom configuration
export CONFIG_PARAMETERS_addmem=2800

export LINKFLAGS="${LINKFLAGS} -Wl,--no-as-needed"

# prerequisites paths
export PYPATH_PYTHON="/fsx/home/etud8-4/codeaster-prerequisites-20240327-oss/venv/lib/python3.7/site-packages:/fsx/home/etud8-4/codeaster-prerequisites-20240327-oss/venv/lib64/python3.7/site-packages"
export PATH="/fsx/home/etud8-4/codeaster-prerequisites-20240327-oss/venv/bin:${PATH}"
export PYTHONPATH="${PYPATH_PYTHON}:${PYTHONPATH}"

export PATH_HDF5="${PREREQ_PATH}/hdf5-1.10.9"
export LIBPATH_HDF5="${PREREQ_PATH}/hdf5-1.10.9/lib"
export INCLUDES_HDF5="${PREREQ_PATH}/hdf5-1.10.9/include"
export LD_LIBRARY_PATH="${LIBPATH_HDF5}:${LD_LIBRARY_PATH}"

export PATH_MED="${PREREQ_PATH}/med-4.1.1"
export LIBPATH_MED="${PREREQ_PATH}/med-4.1.1/lib"
export INCLUDES_MED="${PREREQ_PATH}/med-4.1.1/include"
export PYPATH_MED="${PREREQ_PATH}/med-4.1.1/lib64/python3.7/site-packages"
export PATH="${PREREQ_PATH}/med-4.1.1/bin:${PATH}"
export LD_LIBRARY_PATH="${LIBPATH_MED}:${LD_LIBRARY_PATH}"
export PYTHONPATH="${PYPATH_MED}:${PYTHONPATH}"

export PATH_METIS="${PREREQ_PATH}/metis-5.2.1"
export LIBPATH_METIS="${PREREQ_PATH}/metis-5.2.1/lib"
export INCLUDES_METIS="${PREREQ_PATH}/metis-5.2.1/include"
export LD_LIBRARY_PATH="${LIBPATH_METIS}:${LD_LIBRARY_PATH}"

export TFELHOME="${PREREQ_PATH}/mfront-4.2.0"
export TFELVERS="4.2.0"
export PATH_MFRONT="${PREREQ_PATH}/mfront-4.2.0"
export LIBPATH_MFRONT="${PREREQ_PATH}/mfront-4.2.0/lib"
export INCLUDES_MFRONT="${PREREQ_PATH}/mfront-4.2.0/include/TFEL-4.2.0"
export PATH="${PREREQ_PATH}/mfront-4.2.0/bin:${PATH}"
export LD_LIBRARY_PATH="${LIBPATH_MFRONT}:${LD_LIBRARY_PATH}"

export PATH_MGIS="${PREREQ_PATH}/mgis-2.2"
export LIBPATH_MGIS="${PREREQ_PATH}/mgis-2.2/lib"
export INCLUDES_MGIS="${PREREQ_PATH}/mgis-2.2/include"
export LD_LIBRARY_PATH="${LIBPATH_MGIS}:${LD_LIBRARY_PATH}"

export PATH_HOMARD="${PREREQ_PATH}/homard-11.12_aster2"
export PATH="${PREREQ_PATH}/homard-11.12_aster2/bin:${PATH}"

export PATH_SCOTCH="${PREREQ_PATH}/scotch-7.0.4"
export LIBPATH_SCOTCH="${PREREQ_PATH}/scotch-7.0.4/lib"
export INCLUDES_SCOTCH="${PREREQ_PATH}/scotch-7.0.4/include"
export LD_LIBRARY_PATH="${LIBPATH_SCOTCH}:${LD_LIBRARY_PATH}"

export PATH_MUMPS="${PREREQ_PATH}/mumps-5.6.2"
export LIBPATH_MUMPS="${PREREQ_PATH}/mumps-5.6.2/lib"
export INCLUDES_MUMPS="${PREREQ_PATH}/mumps-5.6.2/include ${PREREQ_PATH}/mumps-5.6.2/include_seq"
export LD_LIBRARY_PATH="${LIBPATH_MUMPS}:${LD_LIBRARY_PATH}"

export PATH_MISS3D="${PREREQ_PATH}/miss3d-6.7_aster7"
export PATH="${PREREQ_PATH}/miss3d-6.7_aster7/bin:${PATH}"

export PATH_MEDCOUPLING="${PREREQ_PATH}/medcoupling-V9_11_0"
export LIBPATH_MEDCOUPLING="${PREREQ_PATH}/medcoupling-V9_11_0/lib"
export INCLUDES_MEDCOUPLING="${PREREQ_PATH}/medcoupling-V9_11_0/include"
export PYPATH_MEDCOUPLING="${PREREQ_PATH}/medcoupling-V9_11_0/lib/python3.7/site-packages"
export LD_LIBRARY_PATH="${LIBPATH_MEDCOUPLING}:${LD_LIBRARY_PATH}"
export PYTHONPATH="${PYPATH_MEDCOUPLING}:${PYTHONPATH}"

export PATH_GMSH="${PREREQ_PATH}/gmsh-4.10.5-Linux64"
export PATH="${PREREQ_PATH}/gmsh-4.10.5-Linux64/bin:${PATH}"

export PATH_GRACE="${PREREQ_PATH}/grace-0.0.1"
export PATH="${PREREQ_PATH}/grace-0.0.1/bin:${PATH}"

export PATH_ASRUN="${PREREQ_PATH}/asrun-2023.0.0"
export PYPATH_ASRUN="${PREREQ_PATH}/asrun-2023.0.0/lib/python3.7/site-packages"
export PATH="${PREREQ_PATH}/asrun-2023.0.0/bin:${PATH}"
export PYTHONPATH="${PYPATH_ASRUN}:${PYTHONPATH}"

export LIB_BOOST="boost_python3"
export LIBPATH_BOOST="/usr/lib64"
export INCLUDES_BOOST="/usr/include"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LIBPATH_BOOST}"

export LINKFLAGS="${LINKFLAGS} -Wl,-rpath=${LD_LIBRARY_PATH}"

export PATH=/tools/openblas/gnu/24.04/bin:$PATH
export LD_LIBRARY_PATH=/tools/openblas/gnu/24.04/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=/tools/openblas/gnu/24.04/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=/tools/openblas/gnu/24.04/include:$CPLUS_INCLUDE_PATH

REFINE=3 /fsx/home/etud8-4/aster/install/mpi/bin/run_aster Cube_perf.py
