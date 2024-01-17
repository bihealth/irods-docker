#!/bin/bash

export REPO=ghcr.io/bihealth/irods-docker
export IRODS_PKG_VERSION=${IRODS_PKG_VERSION-4.2.11-1}

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}" \
    --target main \
    docker

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}-sssd" \
    --target sssd \
    docker

echo "Now do:"
echo "docker push ${REPO}:${IRODS_PKG_VERSION}"
echo "docker push ${REPO}:${IRODS_PKG_VERSION}-sssd"
