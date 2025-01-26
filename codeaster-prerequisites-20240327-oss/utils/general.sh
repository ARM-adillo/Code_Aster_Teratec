# mark target as done if a file exists
mark_done()
{
    # usage: mark_done DEST PROD INSTDIR FILE1 [FILE2...]
    [ $# -ge 3 ] || return 2
    local mark="${1}/.installed/${2}"
    local iret=0
    for file in "${@:4}"; do
        if [ ! -e "${1}/${3}/${file}" ]; then
            echo "not found: ${1}/${3}/${file}"
            iret=1
        fi
    done
    if [ ${iret} -eq 0 ]; then
        echo "installation completed - $(date)" > "${mark}"
    fi
    return ${iret}
}

detect_host()
{
    if [ ! -z "${SINGULARITY_NAME}" ] || [ -f /.dockerenv ]; then
        local wbe=$(ls /opt/public/*_${WAF_SUFFIX}.sh 2> /dev/null)
        if [ ! -z "${wbe}" ]; then
            plt=$(basename "${wbe}" | sed -e "s%_${WAF_SUFFIX}\.sh$%%")
            printf "${plt}"
            return
        fi
    fi
    if [ ! -z "${DISTR}" ]; then
        printf "${DISTR}"
        return
    fi
    if [ -f /software/rd/simumeca/cronos ]; then
        printf cronos
    elif [ -f /projets/simumeca/gaia ]; then
        printf gaia
    elif egrep -q "Scibian 10.0" /etc/issue; then
        printf scibian10
    elif [ -d /efs/projects ] && [ -d /efs/software ]; then
        printf hpc-aws-rh8
    else
        uname -n
    fi
    printf ""
}

math_link_advisor()
{
    # usage: math_link_advisor [math|scalapack|openmp|blacs|all]
    # - VERSION file **MUST HAVE BEEN SOURCED** (for scalack version)
    local path
    local scal
    local math
    local omp
    local blacs
    local type=all
    [ ! -z "$1" ] && type="$1"
    if [ ${use_mkl} -eq 1 ]; then
        path="-L${MKLROOT}/lib/intel64"
    fi
    if [ ${use_mkl_scalapack} -eq 1 ]; then
        # scalapack
        if [ ${use_seq} -eq 1 ]; then
            scal=""
        else
            scal="${path} -lmkl_scalapack_lp64"
        fi
        # blacs
        if [ ${use_seq} -eq 0 ]; then
            if [ ${use_impi} -eq 1 ]; then
                blacs="-lmkl_blacs_intelmpi_lp64"
            else
                blacs="-lmkl_blacs_openmpi_lp64"
            fi
        fi
    else
        if [ ${use_seq} -eq 0 ]; then
            scal="-L${DEST}/scalapack-${SCALAPACK}/lib -lscalapack"
        fi
    fi
    if [ ${use_mkl} -eq 1 ]; then
        # blas/lapack
        if [ ${use_intel} -eq 1 ]; then
            math="${path} -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core"
        else
            math="${path} -Wl,--no-as-needed -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core"
        fi
    else
        math="-lopenblas"
    fi
    # openmp
    if [ ${use_intel} -eq 1 ]; then
        omp="-liomp5"
    else
        omp="-lgomp"
    fi
    case "${type}" in
        scalapack ) printf -- "${scal}" ;;
        math ) printf -- "${math}" ;;
        openmp ) printf -- "${omp}" ;;
        blacs ) printf -- "${blacs}" ;;
        * ) printf -- "${scal} ${math} ${omp} ${blacs}" ;;
    esac
}

# From Intel MKL Linking Advisor:
# intel-mkl-seq
# -L${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -ldl
# intel-mkl-impi
# -L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -liomp5 -lpthread -lm -ldl

# gcc-mkl-seq
# -L${MKLROOT}/lib/intel64 -Wl,--no-as-needed -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -lgomp -lpthread -lm -ldl
# gcc-mkl-ompi
# -L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -Wl,--no-as-needed -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -lmkl_blacs_openmpi_lp64 -lgomp -lpthread -lm -ldl

openmp_flag_advisor()
{
    local omp
    # openmp
    if [ ${use_intel} -eq 1 ]; then
        omp="-qopenmp"
    else
        omp="-fopenmp"
    fi
    printf -- "${omp}"
}

compiler_mpi_advisor()
{
    # usage: compiler_mpi_advisor [bin|include|lib|link|all]
    local bin
    local include
    local lib
    local link
    local type=all
    local show
    [ ! -z "$1" ] && type="$1"
    if [ ${use_impi} -eq 1 ] ; then
        bin=$(dirname $(which $(basename ${FC})))
        link=$(exec ${FC} --show)
    elif [ ${use_ompi} -eq 1 ] ; then
        bin=$(ompi_info --path bindir --parsable | sed 's/path:bindir://')
        include=$(exec ${FC} --showme:incdirs)
        lib=$(exec ${FC} --showme:libdirs)
        link=$(exec ${FC} --showme:link)
    fi
    case "${type}" in
        bin ) printf -- "${bin}" ;;
        include ) printf -- "${include}" ;;
        lib ) printf -- "${lib}" ;;
        link ) printf -- "${link}" ;;
    esac
}

do_check_100227()
{
    # usage: do_check options
    cat << EOF > .check_gcc_100227.F90
program p
    implicit none
    integer, parameter :: nbmode = 3
    integer :: k
    real    :: mass(nbmode*2)
    do k = 1, nbmode*2
        mass(k) = k
    end do
    print *, (mass(k+k), k=1,nbmode)
end program
EOF
    gfortran ${@} .check_gcc_100227.F90 && ./a.out > .check_gcc_100227.output
    egrep -q " 2\.0000.*4\.0000.*6\.0000" .check_gcc_100227.output
    return $?
}

check_gcc_100227()
{
    do_check_100227 -O1
    iret=$?
    if [ ${iret} -ne 0 ]; then
        do_check_100227 -O1 -fno-frontend-optimize
        iret=$?
        if [ ${iret} -eq 0 ]; then
            export FCFLAGS="${FCFLAGS} -fno-frontend-optimize"
        fi
    fi
    rm -f .check_gcc_100227* a.out
    return ${iret}
}

do_check_gfortran10_rank()
{
    # usage: do_check options
    cat << EOF > .check_gfortran10_rank.F90
subroutine func(a)
    integer :: a(1)
    print *, "result:", a(1)
end subroutine func

program p
    implicit none
    integer :: k
    k = 1
    call func(k)
end program
EOF
    gfortran ${@} .check_gfortran10_rank.F90 && ./a.out > .check_gfortran10_rank.output
    egrep -q "result: *1" .check_gfortran10_rank.output
    return $?
}

check_gfortran10_rank()
{
    do_check_gfortran10_rank >> .check_gfortran10_rank.log 2>&1
    iret=$?
    if [ ${iret} -ne 0 ]; then
        do_check_gfortran10_rank -fallow-argument-mismatch >> .check_gfortran10_rank.log 2>&1
        iret=$?
        if [ ${iret} -eq 0 ]; then
            export FCFLAGS="${FCFLAGS} -fallow-argument-mismatch"
        fi
    fi
    rm -f .check_gfortran10_rank* a.out
    return ${iret}
}

check_cmake_version()
{
    local minimal="$1"
    first=$( (cmake --version | grep version | awk '{print $3}' ; echo "$minimal") | sort -V | head -1 )
    test "${first}" == ${minimal} && return 0
    return 1
}

check_gcc_minversion()
{
    local minimal="$1"
    tmpf=$(mktemp /tmp/get_gcc_version.XXXXXX.c)
    cat << EOF > ${tmpf}
#include <stdlib.h>
int main() {
    if ( __GNUC__ < $1 ) { exit(1); }
    exit(0);
}
EOF
    ${CC} -o ${tmpf}.out ${tmpf} && ${tmpf}.out
    iret=$?
    rm -f ${tmpf}.out ${tmpf}
    return ${iret}
}

check_mpi4py_version() {
    local expected="$1"
    installed=$(python3 -m mpi4py --version 2> /dev/null | sed -e 's/mpi4py *//')
    test "${installed}" == "${expected}" && return 0
    return 1
}

check_mpi_thread_multiple_support() {
       tmpf=$(mktemp /tmp/check_mpi_thread_multiple_support.XXXXXX.c)
    cat << EOF > ${tmpf}
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

int main( int argc, char *argv[] ) {
    // Initilialise MPI and ask for thread support
    int provided;
    MPI_Init_thread( NULL, NULL, MPI_THREAD_MULTIPLE, &provided );
    if ( provided < MPI_THREAD_MULTIPLE ) {
        /* The threading support level is lesser than that demanded */
        MPI_Abort( MPI_COMM_WORLD, EXIT_FAILURE );
    }
    MPI_Finalize();
    return EXIT_SUCCESS;
}
EOF
    ${CC} -o ${tmpf}.out ${tmpf} && ${tmpf}.out
    iret=$?
    rm -f ${tmpf}.out ${tmpf}
    return ${iret}
}
