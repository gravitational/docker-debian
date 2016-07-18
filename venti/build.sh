#!/bin/bash

set -e
set -x

ROOTFS=/rootfs/
SCRIPT_DIR=$(dirname $0)

source "$SCRIPT_DIR/config"

function bootstrap {
    # Make in-ram new root
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"
    mount -t tmpfs -o size="$TMPFS_SIZE" none "$ROOTFS"

    # Packages required for building rootfs
    apt-get update
    apt-get install -y --no-install-recommends cdebootstrap curl ca-certificates make

    cdebootstrap --flavour="$FLAVOUR" --include="$BOOTSTRAP_INCLUDE" \
        "$SUITE" "$ROOTFS" "$MIRROR"

    # Installing dumb-init
    curl -o dumb-init.deb -L "$DUMBINIT_URL"
    dpkg --root "$ROOTFS" -i dumb-init.deb

    # Setup golang building environment and godep
    curl -o go-linux.tar.gz -L "$GOLANG_URL"
    tar -xf go-linux.tar.gz -C "$ROOTFS"
    chroot "$ROOTFS" /bin/bash -c 'GOROOT=/go GOPATH=/gocode PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin go get github.com/tools/godep'

    cp -r -t "$ROOTFS" "$SCRIPT_DIR"/rootfs/*

    # Install docker
    curl -sSL https://get.docker.com/ | chroot "$ROOTFS" /bin/bash

    # Configure locales
    chroot "$ROOTFS" /usr/sbin/locale-gen
    chroot "$ROOTFS" /usr/sbin/locale-gen en_US.UTF-8
    chroot "$ROOTFS" /usr/sbin/dpkg-reconfigure locales
}

function cleanup {
    # cleanup.sh must be called ONBUILD too, DRY
    chroot "$ROOTFS" /bin/sh -c 'test -f /cleanup.sh && sh /cleanup.sh'
}

function output {
    cd "$ROOTFS"
    tar --one-file-system --numeric-owner -cf - *
}

function main {
    bootstrap 1>&2
    cleanup 1>&2
    output
}

main

