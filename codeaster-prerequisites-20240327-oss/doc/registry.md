# Container Registry

Les images Singularity sont déposées, en interne EDF, sur MinIO.

## Docker Registry

En interne EDF, on peut déposer les images Docker sur une *registry* privée
sur Nexus : `nexus.retd.edf.fr:5075`

En *extranet*, on peut utiliser le *Container Registry* du Gitlab PAM :
`registry.gitlab.pam-retd.fr`

```bash
docker login nexus.retd.edf.fr:5075 -u $NNI
Password: ...

docker push nexus.retd.edf.fr:5075/codeaster:16.3.26-debian-10
```

Exemple sur Gitlab PAM (sur VM PAM, le proxy kerberos ne fonctionne pas) :

```bash
# script proxy (sur 3128)
# + export des variables
export http_proxy=http://vip-users.proxy.edf.fr:3128
export https_proxy=http://vip-users.proxy.edf.fr:3128
export no_proxy=nexus.retd.edf.fr,linux.pleiade.edf.fr,edf.fr

docker login registry.gitlab.pam-retd.fr -u USER
Password: ...

docker push registry.gitlab.pam-retd.fr/collab_meca_edf_michelin/validation/codeaster:16.3.26-debian-10
```
