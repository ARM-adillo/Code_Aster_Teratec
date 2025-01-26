# Création des archives

Les archives sont déposées sur le bucket MinIO *codeaster* dans
`containers-data/prerequisites/`.

Pour les produits diffusés sur internet, on récupère directement l'archive
telle que téléchargée.

Pour chaque produit, on indique où trouver les sources et le moyen de créer
l'archive.

## hdf5

<https://www.hdfgroup.org/downloads/hdf5/> sans modification

- hdf5-1.10-9 refait car contient `./hdf5-...`.

## med

<https://www.salome-platform.org>, *download*, sans modification

Lien direct : <https://files.salome-platform.org/Salome/other/med-4.1.0.tar.gz>

## metis

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/metis>

## parmetis

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/parmetis>

## mfront

<http://tfel.sourceforge.net/>

## homard

<https://aster.retd.edf.fr/scm/hg/aster-prerequisites/homard>
(mais aussi disponible sur <https://www.salome-platform.org>)

## scotch

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/scotch>

## scalapack

<http://www.netlib.org/scalapack/>

## mumps

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/mumps>

## petsc

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/petsc>

## medcoupling

<https://gitlab.pleiade.edf.fr/salome/medcoupling>

<https://gitlab.pleiade.edf.fr/salome/configuration>

## miss3d

<https://gitlab.pleiade.edf.fr/salomemeca/prerequisites/miss3d>

## ecrevisse

<https://aster.retd.edf.fr/scm/hg/aster-prerequisites/ecrevisse>

## gmsh

<https://gmsh.info> (à supprimer)

## grace

*fake*, à supprimer

## asrun

<https://aster.retd.edf.fr/scm/hg/aster/codeaster-frontend>

## Mémo pour la création des archives

### Dépôt Git

Archives faites avec :

```bash
git archive <branch-tag> --prefix product-version/ -o product-version[-pkg].tar.gz
```

Le préfixe est purement textuel, ne pas oublier le `/` final.

### Dépôt Mercurial

Pour ces produits, voir si :

- patch toujours nécessaire,

- procédure de configuration/installation modifiée nécessaire,

- nouvelles sources de diffusion.

Archives faites avec :

```bash
hg archive --rev TAG product-version[-pkg].tar.gz
```
