#!/bin/bash

export REPO=ghcr.io/bihealth/irods-docker
export IRODS_PKG_VERSION=${IRODS_PKG_VERSION-4.2.11-1}

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}" \
    -t "${REPO}:latest" \
    --target main \
    docker

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}-sssd" \
    -t "${REPO}:latest-sssd" \
    --target sssd \
    docker

echo "Now do"
echo
echo "  docker push ${REPO}:${IRODS_PKG_VERSION}"
echo "  docker push ${REPO}:latest"
echo "  docker push ${REPO}:${IRODS_PKG_VERSION}-sssd"
echo "  docker push ${REPO}:latest-sssd"
