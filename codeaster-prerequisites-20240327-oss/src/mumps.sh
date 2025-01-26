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
# access: ci-prereq-read-api
_download_gitlab_tgz ${GITLAB} ${MUMPS_ID} ${MUMPS} mumps-${MUMPS}.tar.gz

rm -rf content && mkdir content
_extract_arch mumps-${MUMPS}.tar.gz
cd content

libscal="$(math_link_advisor scalapack) $(math_link_advisor blacs)"
libmath=$(math_link_advisor math)
libomp=$(math_link_advisor openmp)
flagomp="$(openmp_flag_advisor)"

if [ ${enable_debug} -eq 1 ]; then
    export CFLAGS="-g ${CFLAGS}"
    export FCFLAGS="-g ${FCFLAGS}"
fi
# version >= 5.4.1
export CFLAGS="-DUSE_SCHEDAFFINITY -Dtry_null_space ${CFLAGS}"
export FCFLAGS="-fallow-argument-mismatch -DUSE_SCHEDAFFINITY -Dtry_null_space ${FCFLAGS}"
# version >= 5.6.0
export FCFLAGS="-DUSE_MPI3 ${FCFLAGS}"
if [ ${use_mkl} -eq 1 ]; then
    export FCFLAGS="-DGEMMT_AVAILABLE ${FCFLAGS}"
fi
if [ ${use_gcc} -eq 1 ]; then
    export FCFLAGS="-ffixed-line-length-none ${FCFLAGS}"
fi
if [ ${use_intel} -eq 1 ]; then
    export FCFLAGS="-extend-source 132 ${FCFLAGS}"
fi
# gfortran >= 10
if check_gcc_minversion 10; then
    export FCFLAGS="-fallow-argument-mismatch ${FCFLAGS}"
fi

# add explicit length declaration in include
sed -i 's/INTEGER *,/INTEGER(4),/g' include/*_{struc,root}.h
sed -i 's/INTEGER *::/INTEGER(4) ::/g' include/*_{struc,root}.h
sed -i 's/INTEGER MPI/INTEGER(4) MPI/g' libseq/mpif.h
sed -i 's/REAL *,/REAL(4),/g' include/*_{struc,root}.h libseq/mpif.h
sed -i 's/REAL *::/REAL(4) ::/g' include/*_{struc,root}.h libseq/mpif.h
sed -i 's/COMPLEX *,/COMPLEX(4),/g' include/*_{struc,root}.h libseq/mpif.h
sed -i 's/COMPLEX *::/COMPLEX(4) ::/g' include/*_{struc,root}.h libseq/mpif.h
sed -i 's/LOGICAL *,/LOGICAL(4),/g' include/*_{struc,root}.h libseq/mpif.h
sed -i 's/LOGICAL *::/LOGICAL(4) ::/g' include/*_{struc,root}.h libseq/mpif.h

# create makefile - look for examples
# those in the Make.inc folder
# https://gitlab.com/petsc/petsc/-/blob/main/config/BuildSystem/config/packages/MUMPS.py
# https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/mumps/package.py

# variables used in the template
orderingsf=( "-Dpord" "-Dmetis" "-Dscotch" )
scotchlib=( "-lesmumps -lscotch -lscotcherr -lscotcherrexit" )
incparmetis=""
libparmetis=""
incpar=""
varincs=INCSEQ
varlibs=LIBSEQ
libseqneeded=libseqneeded
if [ ${use_seq} -eq 0 ]; then
    orderingsf+=( "-Dparmetis" "-Dptscotch" )
    scotchlib+=( "-lptscotch -lptscotcherr -lptscotcherrexit" )
    incparmetis="IPARMETIS  = -I${DEST}/parmetis-${PARMETIS}/include"
    libparmetis="LPARMETIS  = -L${DEST}/parmetis-${PARMETIS}/lib -lparmetis"
    incpar=$(compiler_mpi_advisor include)
    [ ! -z "${incpar}" ] && incpar="-I${incpar}"
    varincs=INCPAR
    varlibs=LIBPAR
    libseqneeded=
fi
pathscalapack=$(awk '{print $1}' <<< "${libscal}")
pathscalapack=${pathscalapack/-L/}
common_flags="-O3 -fPIC ${flagomp} -DPORD_INTSIZE64"
rpaths=( -Wl,-rpath,${DEST}/mumps-${MUMPS}/lib/
        -Wl,-rpath,${DEST}/metis-${METIS}/lib/
        -Wl,-rpath,${DEST}/parmetis-${PARMETIS}/lib/
        -Wl,-rpath,${DEST}/scotch-${SCOTCH}/lib/
        -Wl,-rpath,${pathscalapack}/ )

# templating...
cat << eof > Makefile.inc
# Makefile for mumps

LPORDDIR   = \$(topdir)/PORD/lib/
IPORD      = -I\$(topdir)/PORD/include/
LPORD      = -L\$(LPORDDIR) -lpord

IMETIS     = -I${DEST}/metis-${METIS}/include
LMETIS     = -L${DEST}/metis-${METIS}/lib -lmetis -lGKlib
${incparmetis}
${libparmetis}
ISCOTCH    = -I${DEST}/scotch-${SCOTCH}/include
LSCOTCH    = -L${DEST}/scotch-${SCOTCH}/lib ${scotchlib[@]}

ORDERINGSF = ${orderingsf[@]}
ORDERINGSC = \$(ORDERINGSF)
LORDERINGS  = \$(LPORD) \$(LMETIS) \$(LPARMETIS) \$(LSCOTCH)
IORDERINGSC = \$(IPORD) \$(IMETIS) \$(IPARMETIS) \$(ISCOTCH)
IORDERINGSF = \$(ISCOTCH)

PLAT =
LIBEXT_SHARED = .so
SONAME = -soname
FPIC_OPT = -fPIC

# Adapt/uncomment RPATH_OPT to avoid modifying
# LD_LIBRARY_PATH in case of shared libraries
RPATH_OPT = ${rpaths[@]}

CC = mpicc
FC = gfortran
FL = gfortran
OUTC = -o
OUTF = -o
# WARNING: AR must ends with a blank space!
AR = /usr/bin/ar rcs ""
RANLIB = echo
RM = /bin/rm -f

LAPACK = -llapack
SCALAP = ${libscal}
INCPAR = ${incpar}
LIBPAR = \$(SCALAP) $(compiler_mpi_advisor link)
INCSEQ = -I\$(topdir)/libseq
LIBSEQ = \$(LAPACK) -L\$(topdir)/libseq -lmpiseq
LIBBLAS = ${libmath}
LIBOTHERS = ${libomp} -lpthread

CDEFS = -DAdd_

OPTF = ${common_flags} ${FCFLAGS}
OPTC = ${common_flags} ${CFLAGS}
OPTL = ${common_flags}

INCS = \$(${varincs})
LIBS = \$(${varlibs})
LIBSEQNEEDED = ${libseqneeded}
eof

cat Makefile.inc

# build
make allshared -j ${procs}

# move installation
rm -rf ${DEST}/mumps-${MUMPS}
mkdir -p ${DEST}/mumps-${MUMPS}/{include,include_seq,lib,share}
cp Makefile.inc ${DEST}/mumps-${MUMPS}/share/
cp include/* ${DEST}/mumps-${MUMPS}/include/
cp libseq/mpi*.h ${DEST}/mumps-${MUMPS}/include_seq/
cp lib/* ${DEST}/mumps-${MUMPS}/lib/
cp -r examples ${DEST}/mumps-${MUMPS}/share/
rm ${DEST}/mumps-${MUMPS}/share/examples/*.*

mark_done ${DEST} mumps mumps-${MUMPS} \
    lib/libcmumps.so lib/libdmumps.so lib/libmumps_common.so \
    lib/libpord.so lib/libsmumps.so lib/libzmumps.so
