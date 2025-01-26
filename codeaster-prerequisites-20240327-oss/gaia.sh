newgrp cl-pj-simumeca-admin

if [ -z "$CACHE" ]; then
    # on a frontal node:
    export CACHE=$SCRATCHDIR/.cache_prereq
    source ~/.gitlab-token
    make ROOT=/projets/simumeca/prerequisites ARCH=gcc8-mkl-ompi3 RESTRICTED=1 download
    make ROOT=/projets/simumeca/prerequisites ARCH=gcc8-mkl-ompi3 RESTRICTED=1 setup_venv
else
    # on a compute node:
    # export CACHE= + gaia.sh
    make ROOT=/projets/simumeca/prerequisites ARCH=gcc8-mkl-ompi3 RESTRICTED=1
    make ROOT=/projets/simumeca/prerequisites ARCH=gcc8-mkl-ompi3-debug RESTRICTED=1
fi
