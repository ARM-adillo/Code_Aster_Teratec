#!/bin/bash

scl enable devtoolset-8 bash

cd codeaster-prerequisites-20240327-oss
sed -i -e 's#-lopenblas#-L /tools/openblas -lopenblas#g' utils/general.sh
sed -i -e 's#LIBPATH="#LIBPATH="/tools/openblas #g' \
       -e 's#maths-libs=auto#maths-libs="scalapack metis openblas"#g' src/mumps.sh
sed -i -e "s#centos8#$(uname -n)#g" utils/generate_env.py
sed -i "32 c libmath=\"-L${OPENBLAS_ROOT}/lib -lopenblas\"" ./src/petsc.sh

cat << eof >> utils/build_env.sh

CA_CFG_MEDCOUPLING=( "-DBOOST_ROOT=/opt/aster/boost" )
eof
