## Test installation AWS

```bash
ROOT=/efs/software/codeaster
DEV=/efs/software/codeaster/integration
PREREQ=${ROOT}/prerequisites

mkdir -p ${ROOT} ${DEV} ${PREREQ}
```

### Installation pyenv

```bash
export PYENV_ROOT=${PREREQ}/pyenvs
curl https://pyenv.run | bash
```

Création de `${PREREQ}/env.sh`:

```bash
cat << EOF > ${PREREQ}/env.sh
# pyenv
export PYENV_ROOT=${PREREQ}/pyenvs
export PATH=\${PYENV_ROOT}/bin:\${PATH}
eval "\$(pyenv init -)"

# ompi5
export PATH=/opt/parallelcluster/shared/ompi5_imp/ompi5-improved/install/bin:\${PATH}

# GCC 12
#scl enable gcc-toolset-12 bash
. \$(readlink -n -f \$(dirname \${BASH_SOURCE}))/gcc-toolset-12-env.sh
EOF
```

avec `${PREREQ}/gcc-toolset-12-env.sh` (car `scl load` ne fonctionne pas):

```bash
cat << EOF > ${PREREQ}/gcc-toolset-12-env.sh
export INFOPATH=/opt/rh/gcc-toolset-12/root/usr/share/info:\${INFOPATH}
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:/opt/rh/gcc-toolset-12/root/usr/lib:\${LD_LIBRARY_PATH}
export MANPATH=/opt/rh/gcc-toolset-12/root/usr/share/man:\${MANPATH}

export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:\${PATH}

export PCP_DIR=/opt/rh/gcc-toolset-12/root
export PKG_CONFIG_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64/pkgconfig
export X_SCLS=gcc-toolset-12
EOF
```

Pour le contenu de ce fichier, faire un _diff_ entre `env` avant et après `scl enable...`.

### Install Python (3.9.18)

```bash
. ${PREREQ}/env.sh
pyenv install 3.9-dev
pyenv virtualenv 3.9-dev 3.9-pre20240327
pyenv global 3.9-pre20240327
```

`python3-config --cflags` ne retourne pas le bon chemin. On ajoute un lien:

```bash
cd ${PREREQ}/pyenvs/versions/3.9-pre20240327
rmdir include
ln -s ../../include .
```

### Installation packages

```bash
pip install --upgrade pip

# for code_aster
pip install 'numpy<2' scipy mpi4py

# for med
pip install swig pyyaml

pip cache purge
```

### Installation de boost

```bash
. ${PREREQ}/env.sh

# required to build boost::python
export C_INCLUDE_PATH=$C_INCLUDE_PATH:${PREREQ}/pyenvs/versions/3.9-dev/include/python3.9
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:${PREREQ}/pyenvs/versions/3.9-dev/include/python3.9

./bootstrap.sh --prefix=${PREREQ}/boost-1.82.0
./b2 install
```

### codeaster-prerequisites

- nouvel host: `hpc-aws-rh8` et `utils/build_env.sh` associé.
- patches nécessaires pour mfront et mgis : regexp pour nettoyer la version de Python.
- semblant de généricité pour boost.
- fix dans la génération du `Makefile.inc` de mumps.

### code_aster

- détection de `hpc-aws-rh8` (dans `waf.main`).
- ajout de `env.d/hpc-aws-rh8_mpi.sh`

```bash
./configure --prefix=${ROOT}/install/unstable
make install-tests
```

Modifier `share/aster/profile.sh`:
- ajouter `/lib64/libgomp.so.1` après les mkl dans LD_PRELOAD.
- ajouter ompi5: `export PATH=/opt/parallelcluster/shared/ompi5_imp/ompi5-improved/install/bin:${PATH}`

=> fait maintenant via `cfg_addons`.
