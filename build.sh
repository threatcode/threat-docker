#!/bin/bash

set -e
set -u

DISTROS="${*:-threat-rolling}"
EXTRA_DISTROS=""
ARCHS="amd64"

#DISTROS="threat-rolling threat-dev threat-last-snapshot"
#EXTRA_DISTROS="threat-experimental threat-bleeding-edge"
#ARCHS="amd64 arm64 armhf"

echo "Distributions: $DISTROS"
echo "Architectures: $ARCHS"
for distro in $DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        sudo ./build-rootfs.sh "$distro" "$arch"
        sudo ./docker-build.sh "$distro" "$arch"
        sudo ./docker-test.sh  "$distro" "$arch"
        sudo ./docker-push.sh  "$distro" "$arch"
    done
    sudo ./docker-push-manifest.sh "$distro" "$arch"
done
for distro in $EXTRA_DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        sudo ./docker-build-extra.sh "$distro" "$arch"
        sudo ./docker-test.sh "$distro" "$arch"
        sudo ./docker-push.sh "$distro" "$arch"
    done
    sudo ./docker-push-manifest.sh "$distro" "$arch"
done
