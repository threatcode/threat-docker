#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURE=$2
TARBALL=$DISTRO-$ARCHITECTURE.tar.xz
VERSIONFILE=$DISTRO-$ARCHITECTURE.release.version

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"threatos"}
PROJECT_URL=${CI_PROJECT_URL:-"https://github.com/threatcode/build-scripts/threat-docker"}
BUILD_DATE=${CI_JOB_STARTED_AT:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
BUILD_VERSION=$(date -u +"%Y.%m.%d")
VCS_REF=${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64" ;;
    arm64) platform="linux/arm64" ;;
    armhf) platform="linux/arm/7" ;;
esac

case "$DISTRO" in
    threat-last-snapshot)
        IMAGE=threat
        VERSION=$(cat "$VERSIONFILE")
        RELEASE_DESCRIPTION="$VERSION"
        ;;
    *)
        IMAGE="$DISTRO"
        VERSION="$BUILD_VERSION"
        RELEASE_DESCRIPTION="$DISTRO"
        ;;
esac

TAG=$VERSION-$ARCHITECTURE

export DOCKER_BUILDKIT=1
docker build \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg PROJECT_URL="$PROJECT_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    --platform "$platform" \
    --progress plain \
    --pull \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Push the image so that subsequent jobs can fetch it
    docker push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$DISTRO-$ARCHITECTURE".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
