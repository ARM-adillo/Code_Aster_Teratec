if [ -z "${CACHE}" ]; then
    echo "CACHE variable not defined!"
    exit 1
fi
if [ ! -d "${CACHE}" ]; then
    echo "cache directory does not exist: ${CACHE}"
    exit 1
fi

# helper functions
_extract_arch()
{
    [ -d content ] || mkdir content
    tar xf "${1}" -C content --strip-components 1
    [ $? -eq 0 ] && rm -f "${1}"
}

_download_curl_tgz()
{
    # usage: _download_tgz URL
    local arch="$(basename "${1}")"
    if [ -f "${ARCHIVESDIR}/${arch}" ]; then
        cp "${ARCHIVESDIR}/${arch}" "${arch}"
    elif [ -f "${CACHE}/${arch}" ]; then
        cp "${CACHE}/${arch}" "${arch}"
    else
        curl --insecure -L -o "${arch}" "${1}"
        cp "${arch}" "${CACHE}/$(basename "${1}")"
    fi
    return 0
}

_download_gitlab_tgz()
{
    # usage: _download_gitlab_tgz BASEURL PROJECT-ID SHA ARCH
    local arch="${4}"
    if [ -f "${ARCHIVESDIR}/${arch}" ]; then
        cp "${ARCHIVESDIR}/${arch}" "${arch}"
    elif [ -f "${CACHE}/${arch}" ]; then
        cp "${CACHE}/${arch}" "${arch}"
    else
        if [ -z "${GITLAB_PREREQ_TOKEN}" ]; then
            echo "ERROR: Please set GITLAB_PREREQ_TOKEN environment variable."
            return 1
        fi
        url="${1}/api/v4/projects/${2}/repository/archive?sha=${3}"
        echo "downloading ${url}..."
        curl --insecure --header "PRIVATE-TOKEN: ${GITLAB_PREREQ_TOKEN}" --url "${url}" \
            -L -o "${arch}"
        cp "${arch}" "${CACHE}/${arch}"
    fi
    return 0
}
