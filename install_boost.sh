#!/bin/bash

wget https://archives.boost.io/release/1.75.0/source/boost_1_75_0.tar.gz
tar -xvf boost_1_75_0.tar.gz
cd boost_1_75_0
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/usr/include/python3.7m/"
./bootstrap.sh --with-python=python3.7 --with-libraries=all > resBootstrap 2>&1
./b2 > resb2 2>&1
sudo ./b2 install > resInstall 2>&1
cd ..
rm -r boost_1_75_0.tar.gz
t=$(ls /usr/local/lib | grep libboost_python3 | wc -l)
if [ $t -ge 3 ]
then
        echo "Boost installation looks ok"
else
        echo "Boost installation looks wrong"
fi
