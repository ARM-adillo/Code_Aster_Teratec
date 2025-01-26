# Installation of Intel oneAPI MKL

## Download Intel oneAPI MKL package

Download MKL [using this direct link][direct-mkl-offline] or it changed
Google-search for "oneapi mkl download", select *Linux* as operating system,
*online & offline* distribution, *offline* as installer type.

[direct-mkl-offline]: https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html?operatingsystem=linux&distributions=webdownload&options=offline

Follow the instructions for installation.

## Setup environment

You may create module files from the MKL installation directory to setup the
environment. Or just source the provided shell script:

```shell
source <install-directory>/setvars.sh
```
