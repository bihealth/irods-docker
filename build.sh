#!/bin/bash

export REPO=ghcr.io/bihealth/irods-docker
export IRODS_PKG_VERSION=${IRODS_PKG_VERSION-4.3.4}
export IRODS_PYTHON_RULE_ENGINE_VERSION=${IRODS_PYTHON_RULE_ENGINE_VERSION-4.3.4.0-0+4.3.4}
export BUILD_VERSION=${BUILD_VERSION-1}

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}-${BUILD_VERSION}" \
    --build-arg IRODS_PKG_VERSION=${IRODS_PKG_VERSION} \
    --build-arg IRODS_PYTHON_RULE_ENGINE_VERSION=${IRODS_PYTHON_RULE_ENGINE_VERSION} \
    --target main \
    docker

docker build \
    -t "${REPO}:${IRODS_PKG_VERSION}-${BUILD_VERSION}-sssd" \
    --build-arg IRODS_PKG_VERSION=${IRODS_PKG_VERSION} \
    --build-arg IRODS_PYTHON_RULE_ENGINE_VERSION=${IRODS_PYTHON_RULE_ENGINE_VERSION} \
    --target sssd \
    docker

echo "Now do:"
echo "docker push ${REPO}:${IRODS_PKG_VERSION}-${BUILD_VERSION}"
echo "docker push ${REPO}:${IRODS_PKG_VERSION}-${BUILD_VERSION}-sssd"
