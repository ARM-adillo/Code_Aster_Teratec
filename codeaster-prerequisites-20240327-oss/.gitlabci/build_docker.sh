#!/busybox/sh
# Warning: will be executed by /busybox/sh in a kaniko container

variant="$1"
branch="$2"
build_type="$3"
suffix="-next"

if [ "${build_type}" = "release" ]; then
    build_type=""
else
    build_type="-${build_type}"
fi
[ "${branch}" = "main" ] && suffix=""
[ $(echo "${branch}" | awk -F/ '{print $1}') = "maint" ] && suffix=""

echo "+ $(date) - building Docker image ${variant}..."
source ./VERSION
dest="${DOCKER_NEXUS_URL}/codeaster-prerequisites:${VERSION}-${variant}${build_type}${suffix}"

encoded=$(printf "%s:%s" "${DOCKER_NEXUS_USER}" "${DOCKER_NEXUS_PASSWD}" | base64 | tr -d '\n')
cat << eof > /kaniko/.docker/config.json
{
    "auths": {
        "${DOCKER_NEXUS_URL}": {
            "auth": "${encoded}"
        }
    }
}
eof

which make && make distclean

echo ${variant} | grep -q -- "-oss"
iret=$?
if [ ${iret} -eq 0 ]; then
    # use same recipe as for non "-oss"
    variant=${variant%-*}
    # extract...
    tar xvf artf/archive-oss.tar.gz
    # ... and use archive
    cd codeaster-prerequisites-${VERSION}-oss
fi

# copying certificate into /kaniko/ssl/certs/ca-certificates.crt does not work
/kaniko/executor \
      --context "${CI_PROJECT_DIR}" \
      --build-arg GITLAB_PREREQ_TOKEN="${GITLAB_PREREQ_TOKEN}" \
      --build-arg PREREQ_ARCH_SUFFIX="${build_type}" \
      --dockerfile "${CI_PROJECT_DIR}/container/${variant}.dockerfile" \
      --skip-tls-verify \
      --destination "${dest}"
