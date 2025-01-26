# Construction des prérequis de code_aster

L'objectif n'est pas de faire encore un autre meta-*maker* mais
d'avoir un moyen simple pour :

- construire les prérequis, sur cluster dans un premier temps, avec plusieurs
  configurations,

- de gérer quelques dépendances pour ne pas tout reconstruire,

- de permettre une construction dans l'environnement d'un utilisateur pour faire
  des tests de prérequis,

- mêmes scripts utilisés pour construire les prérequis dans un conteneur.

Simplicité et lisibilité :

- un `makefile` + `script.sh` de quelques lignes par produit.

- un fichier qui définit l'environnement.

Arborescence d'installation type :

```bash
ROOT=/software/rd/simumeca/prerequisites

DEST=${ROOT}/<version>/${ARCH}

${DEST}/gcc8-openblas-seq
${DEST}/gcc8-mkl-ompi4

${DEST}/intel19-mkl-impi19
...
```

> Remarque : Selon la plate-forme, `gcc8` indique avant tout qu'on utilise `gcc`.
> Le `8` est une indication, parfois utilisé pour charger un module nécessaire.
> Aujourd'hui, pour la bibliothèque mathématique, c'est `mkl` ou `openblas`.

Pour une version de code_aster, on prend tous les prérequis dont la version
est indiquée dans son fichier de configuration (`env.d/<host-name>_mpi.sh` ou
`/opt/public/` pour les conteneurs) dans un unique répertoire
`${DEST}/<version>/${ARCH}`. Ses dépendances sont donc claires.

## Utilisation de GitLab

Quand c'est possible, on utilise directement le dépôt Git des prérequis
publié sur GitLab.
Afin de télécharger une archive depuis GitLab, il faut fournir un *token*.
Pour cela, il suffit d'aller sur GitLab dans **Edit profile**, puis
**Access Tokens** et de choisir un **Token name** avec la permission **read_api**.
Ce *token* est attendu dans la variable d'environnement `GITLAB_PREREQ_TOKEN`.
On peut la stocker par exemple dans `~/.gitlab-token` :

```bash
export GITLAB_PREREQ_TOKEN="copier la valeur du token ici"
export SINGULARITYENV_GITLAB_PREREQ_TOKEN="${GITLAB_PREREQ_TOKEN}"
```

La deuxième ligne permet de transmettre cette valeur lors d'une construction
d'image avec Singularity.

## Prérequis des prérequis

Le chargement des prérequis de construction est fait dans `utils/build_env.sh`,
essentiellement pour les clusters.

`reqs/requirements_pyenv.txt` fournit la liste des paquets Python nécessaires à
code_aster, qui sont souvent installés auparavant via le *Package Manager* ou
dans un *pyenv* dédié.

Pour les conteneurs, on créé un environnement virtuel contenant `reqs/requirements_dev.txt` avec des outils supplémentaires pour le développement.

Pour chaque produit, on peut définir et activer un environnement virtuel particulier,
deux produits pouvant nécessiter des prérequis incompatibles entre eux
(exemple: des versions très différentes de Cython entre PETSc et mpi4py).
Ces environnements sont automatiquement activés pour chaque produit s'ils existent
sous le nom `.venv_<product-name>`.
Leur contenu est défini par `reqs/requirements_<product-name>.txt`.
Si on est déjà dans un environnement virtuel, les paquets présents sont ajoutés
dans l'environnement virtuel du produit.

Pour créer ces environnements virtuels, on peut faire:

```bash
make ROOT=... ARCH=... setup_venv
```

En interne, pour utiliser le mirroir `pip` sur Nexus, mettre ceci dans
`~/.config/pip/pip.conf` :

```ini
[global]
trusted-host = nexus.retd.edf.fr
index = https://nexus.retd.edf.fr/repository/pypi-all/pypi
index-url = https://nexus.retd.edf.fr/repository/pypi-all/simple
```

### Sur Scibian

Sur Scibian9 et Scibian10, on utilise `openblas`.
Cela fonctionne bien avec `mkl` mais au prix de 5 Go de plus dans le conteneur.
Si on veut le faire, voir [installation de Intel oneAPI MKL](doc/install-mkl.md).

## Utilisation cible

Définir le *token* GitLab :

```bash
. ~/.gitlab-token
```

puis :

```bash
make ROOT=<INSTALL-DIR>/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1
```

Si on ne souhaite pas construire le répertoire d'installation avec
`${ROOT}/<version>/${ARCH}`, on peut passer directement `DEST`
(il faut quand même passer une valeur bidon à `ROOT`) :

```bash
make ROOT=unused DEST=/opt ARCH=gcc8-mkl-ompi4 RESTRICTED=1
```

## Intégration Continue - CI

L'intégration continue de ce dépôt construit des conteneurs embarquant les prérequis.

Images Singularity :

- sur base Debian 10 (référence Salome),
- sur base Debian 11 (version courante pour Scibian),
- sur base Debian 12 (prochaine version),
- sur base Ubuntu 22 (largement répandue).

Image Docker :

- sur base Debian 10 (référence Salome),
- sur base Debian 11 (version courante pour Scibian),
- sur base Debian 12 (prochaine version),
- sur base Ubuntu 22 (largement répandue).

Cf. la [description des *registry*](./doc/registry.md).

```bash
export GITLAB_PREREQ_TOKEN=xxxxx
export DISTR=debian-10
docker build \
  -t codeaster-prerequisites-20221225:${DISTR} \
  -f container/${DISTR}.dockerfile \
  --build-arg "GITLAB_PREREQ_TOKEN=$GITLAB_PREREQ_TOKEN" \
  .
```

```bash
export DISTR=debian-10
docker run --rm -it \
  --user=$(id -u):$(id -g) \
  --mount type=bind,src=$(pwd)/builds,dst=/opt/builds \
  codeaster-prerequisites-20221225:${DISTR}
```

```bash
export GITLAB_PREREQ_TOKEN=xxxxx
export DISTR=debian-10
docker build \
  -t codeaster-unstable \
  -f container/codeaster-${DISTR}.dockerfile \
  --build-arg "GITLAB_PREREQ_TOKEN=$GITLAB_PREREQ_TOKEN" .
```

## Détails de fonctionnement

- L'ajout d'un produit consiste à :

  - ajouter une cible *fictive* dans `PRODUCTS` du *Makefile* ;

  - renseigner si besoin les dépendances avec les autres fichiers *marque*
    `.installed/<product>` ;

  - écrire le script d'installation qui doit se terminer par un appel à
    `mark_done` vérifie la présence d'un ou plusieurs fichiers, place une
    *marque* (fichier `.installed/<product>`) et retourne le code retour de
    succès ou d'échec.

- Les archives des produits sont récupérées depuis leurs dépôts sur GitLab de
  préférence ou bien sur le bucket MinIO *codeaster*.
  Voir pour la [page sur la création des archives](doc/archives.md).

- L'environnement de construction est positionné par `build_env.sh`.

- Le script d'installation peut dépendre des variables définies dans
  `build_env.sh` : *use_seq*, *use_gcc*, *use_intel*, *use_mkl*,
  *use_ompi*, *use_impi*.
  Il ne devrait pas dépendre directement de `comp`, `math` ou `para` (sauf le
  temps de faire des tests).

- Il y a des fonctions pour récupérer les valeurs génériques pour Python
  (lib, include...).

- Variables possibles pour adapter la configuration d'un produit quand elle ne
  peut pas être générique : `CA_CFG_<product>`.

### Vérification de l'environnement

Quelques informations sur l'environnement de construction utilisé (version des
compilateurs, blas/mkl, modules, python...) peuvent être affichées avec :

```bash
make ROOT=<INSTALL-DIR>/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1 check
```

### Générer le fichier d'environnement

```bash
make ROOT=<INSTALL-DIR>/prerequisites ARCH=gcc8-mkl-ompi4 RESTRICTED=1 env
```

C'est fait automatiquement avec la cible par défaut.
Il est parfois intéressant de tester le fichier produit avant de tout
construire. Dans ce cas, il suffit d'enlever l'option `--check` dans
`src/env_file.sh`.

### Archive complète `dist`

La cible `dist` du *Makefile* produit une archive complète contenant les scripts
contenus dans ce dépôt ainsi que les archives téléchargées pour chaque produit.

Le *token* GitLab est nécessaire pour télécharger les archives de certains produits:

```bash
. ~/.gitlab-token
```

puis :

```bash
make dist RESTRICTED=1
```

Il est conseillé de lancer au préalable `make distclean` pour ne pas ajouter
d'archives inutiles.

Pour produire une archive ne contenant que des versions *open source*
(le suffixe `-oss` sera ajouté l'archive), on peut faire :

```bash
make dist RESTRICTED=0
```

L'installation à partir de cette archive ne nécessite pas d'accès à Nexus ou GitLab.

## Source des prérequis

Voir la [page sur la création des archives](doc/archives.md).

## Procédure de mise à jour des prérequis

- La version doit être modifiée dans le fichier `VERSION` dès qu'on change la
  version d'un des préquis.

- Vérifier la construction et l'installation des prérequis hors du répertoire
  d'installation final.

- À faire sur les configurations officielles (Cronos, Gaia, conteneur pour version locale) en séquentiel, en parallèle et en parallèle avec debug.

- Passer les tests de vérification et validation sur Cronos.

## Améliorations

- homard 11.12 embarque plusieurs versions et la version par défaut dans
  code_aster est 11.10...
  Voir aussi ce qui est disponible sur <https://www.salome-platform.org>.

## Remarques de construction sur Eole/Gaia

Il est connu que les scripts d'installation qui modifient les permissions sur
les fichiers peuvent poser problème avec les groupes sur `/projets`.
C'est le cas de PETSc, ce qui peut se traduire par un *Disk quota exceeded*.

De plus, en essayant de compiler sur un noeud calcul,
`newgrp cl-pj-simumeca-admin` semble faire échouer un test de configuration
de PETSc faisant `mpiexec -n 1 testprog`...

Donc : compilation sur une frontale et `newgrp cl-pj-simumeca-admin` avant de
lancer `make ROOT=/projets/simumeca/prerequisites ARCH=... RESTRICTED=1`

Sur Cronos, le groupe est `cl-sw-rd-simumeca-rw` mais ce n'est normalement pas
utile, le quota étant sur le *filesystem*, pas le groupe.

## Catégories de produits

### Prérequis utilisant MPI

- hdf5

- med

- parmetis

- scalapack : fourni par MKL

- scotch

- mumps

- petsc

- mpi4py

- medcoupling

### Prérequis purement séquentiels

- metis

- mfront

- homard

- miss3d

- ecrevisse

- gmsh

- grace (fake)

- asrun

### Prérequis utilisant MKL

- mumps

- petsc

- miss3d
