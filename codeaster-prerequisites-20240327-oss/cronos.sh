if [ -z "$CACHE" ]; then
    # on a frontal node:
    export CACHE=$SCRATCHDIR/.cache_prereq
    source ~/.gitlab-token
    make ROOT=/software/restricted/simumeca/aster/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1 download
    make ROOT=/software/restricted/simumeca/aster/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1 setup_venv
else
    # on a compute node:
    # export CACHE= + cronos.sh
    make ROOT=/software/restricted/simumeca/aster/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1
    make ROOT=/software/restricted/simumeca/aster/prerequisites ARCH=gcc8-mkl-ompi4-debug RESTRICTED=1
fi
