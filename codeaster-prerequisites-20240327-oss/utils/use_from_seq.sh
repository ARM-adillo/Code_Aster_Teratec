#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: use_from_seq.sh mpi-install-dir"
    exit 1
fi
instmpi="${1}"
instseq="${instmpi%-*}-seq"

if [ ! -d "${instmpi}" ]; then
    echo "MPI installation directory not found: ${instmpi}"
    exit 1
fi
if [ ! -d "${instseq}" ]; then
    echo "SEQ installation directory not found: ${instseq}"
    exit 1
fi
if [ ! -f VERSION ]; then
    echo "file not found: VERSION"
    exit 1
fi

. VERSION
products=( $(egrep '^[A-Z]' VERSION | egrep -v '^VERSION' | \
             awk -F= '{print tolower($1)}') )
products_mpi=( hdf5 med parmetis scalapack scotch mumps petsc mpi4py medcoupling )
declare -A ismpi
for prod in ${products_mpi[@]}; do
    ismpi[${prod}]="y"
done

# add symlinks for sequential-only products
for prod in ${products[@]}; do
    if [ "${ismpi[${prod}]}" != "y" ] && [ -e ${instseq}/.installed/${prod} ]; then
        vers=${prod^^}
        if [ -d "${instseq}/${prod}-${!vers}" ]; then
            echo "use ${prod}-${!vers} from $(basename "${instseq}")"
            rm -rf "${instmpi}/${prod}-${!vers}"
            ln -s ${instseq}/${prod}-${!vers} ${instmpi}/
            cp -p ${instseq}/.installed/${prod} ${instmpi}/.installed/
        else
            echo "WARNING: not found: ${instseq}/${prod}-${!vers}"
        fi
    fi
done
