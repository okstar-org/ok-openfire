#!/bin/bash

# Note: the Maven build happens inside the Dockerfile's own `build` stage,
# so no pre-build step is needed here.

# Derive the image tag from the project version in pom.xml.
VERSION=$(sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' pom.xml | head -1)
if [[ -z "${VERSION}" ]]; then
    echo "ERROR: could not determine project version from pom.xml" >&2
    exit 1
fi

# Read build arguments from the config file (KEY=VALUE, one per line; '#' and blank lines skipped).
CONFIG_FILE="${OPENFIRE_CONFIG_FILE:-.env}"
BUILD_ARGS=()
if [[ -f "${CONFIG_FILE}" ]]; then
    echo "Using build configuration from ${CONFIG_FILE}"
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%%$'\r'}"                       # strip CR for Windows line endings
        [[ -z "${line}" || "${line}" == \#* ]] && continue
        [[ "${line}" == *=* ]] || continue
        BUILD_ARGS+=(--build-arg "${line}")
    done < "${CONFIG_FILE}"
else
    echo "No ${CONFIG_FILE} found; using Dockerfile ARG defaults"
fi

# Fetch the mirror from the config file, so it can be reported below.
# The config entry itself is already passed to docker via the loop above.
MIRROR=""
if [[ -f "${CONFIG_FILE}" ]]; then
    MIRROR=$(sed -n 's/^[[:space:]]*MIRROR=\(.*\)/\1/p' "${CONFIG_FILE}" | head -1 | tr -d '\r')
fi

# An explicitly set environment variable overrides the config file,
# e.g.: OPENFIRE_BASE_IMAGE=library bash ./build-docker.sh   (build against Docker Hub)
if [[ -n "${OPENFIRE_BASE_IMAGE:-}" ]]; then
    BUILD_ARGS+=(--build-arg "OPENFIRE_BASE_IMAGE=${OPENFIRE_BASE_IMAGE}")
fi

echo "Building okstarorg/ok-openfire:${VERSION} (MIRROR: ${MIRROR:-default}) ..."
docker buildx build "${BUILD_ARGS[@]}" -t "okstarorg/ok-openfire:${VERSION}" . --load
