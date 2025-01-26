# docker build . -t docaster2sphinx
# EDF internal registry: nexus.retd.edf.fr/debian:bullseye-slim
# + internal repo mirrors: nexus.retd.edf.fr:5012/debian:bullseye-slim
FROM nexus.retd.edf.fr:5012/debian:bookworm-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt install -y \
    apt-utils \
    aspell \
    aspell-fr \
    bash-completion \
    bison \
    ccache \
    clang-format \
    cmake \
    curl \
    flex \
    g++ \
    gcc \
    gdb \
    gettext \
    gfortran \
    git \
    graphviz \
    imagemagick \
    less \
    libboost-chrono-dev \
    libboost-date-time-dev \
    libboost-filesystem-dev \
    libboost-python-dev \
    libboost-regex-dev \
    libboost-serialization-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libglu1-mesa \
    libncurses5 \
    libopenblas-dev \
    libopenmpi-dev \
    libunwind-dev \
    libxcursor1 \
    libxml2-dev \
    lmod \
    locales \
    mercurial \
    nano \
    net-tools \
    openmpi-bin \
    pkg-config \
    procps \
    python3-dev \
    python3-numpy \
    python3-pip \
    python3-scipy \
    python3-sphinx \
    python3-texext \
    python3-venv \
    python3-yaml \
    swig \
    tk \
    valgrind \
    vim \
    wget \
    zlib1g-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*

ENV PATH=/opt/venv/bin:${PATH}

ENV WRKDIR=/opt/repo
WORKDIR ${WRKDIR}
COPY VERSION ${WRKDIR}/
COPY archives ${WRKDIR}/archives
COPY makefile ${WRKDIR}/
COPY reqs ${WRKDIR}/reqs
COPY patches ${WRKDIR}/patches
COPY src ${WRKDIR}/src
COPY utils ${WRKDIR}/utils

RUN \
    python3 -m venv --system-site-packages /opt/venv ; \
    PIP_OPTIONS="--trusted-host nexus.retd.edf.fr --index-url https://nexus.retd.edf.fr/repository/pypi-all/simple" ; \
    python3 -m pip install ${PIP_OPTIONS} --upgrade pip ; \
    python3 -m pip install ${PIP_OPTIONS} -r ${WRKDIR}/reqs/requirements_dev.txt ; \
    mpi4py_spec=$(. ${WRKDIR}/VERSION ; printf "mpi4py==${MPI4PY}") ; \
    python3 -m pip install ${PIP_OPTIONS} "${mpi4py_spec}"

ARG GITLAB_PREREQ_TOKEN
ENV GITLAB_PREREQ_TOKEN ${GITLAB_PREREQ_TOKEN}
ARG PREREQ_ARCH_SUFFIX
ENV PREREQ_ARCH gcc-openblas-ompi${PREREQ_ARCH_SUFFIX}

# use RESTRICTED=0 if build from a '-oss' archive
RUN \
    export DISTR=debian-12 ; \
    make ROOT=/opt/public ARCH=${PREREQ_ARCH} RESTRICTED=1 check ; \
    make ROOT=/opt/public ARCH=${PREREQ_ARCH} RESTRICTED=1 setup_venv ; \
    make ROOT=/opt/public ARCH=${PREREQ_ARCH} RESTRICTED=1

RUN \
    VERSION=$(. ${WRKDIR}/VERSION ; echo ${VERSION}) ; \
    ln -s /opt/public/${VERSION}/${PREREQ_ARCH}/asrun-*/bin/as_run /usr/local/bin/as_run ; \
    ln -s /opt/public/${VERSION}/${PREREQ_ARCH}/asrun-*/bin/astk /usr/local/bin/astk ; \
    cp ${WRKDIR}/reqs/requirements*.txt /opt/public/${VERSION}/ ; \
    cp /opt/public/${VERSION}/${PREREQ_ARCH}/*.sh /opt/public/ ; \
    cd /opt/public ; \
    rm -rf ${WRKDIR}

ENV WRKDIR=

RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user
