#!/bin/bash

make dist RESTRICTED=0

mkdir -p artf
mv codeaster-prerequisites-*-oss.tar.gz artf/archive-oss.tar.gz
