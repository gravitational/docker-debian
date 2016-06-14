#!/bin/bash

set -e
set -x

ROOTFS=/rootfs/
SCRIPT_DIR=$(dirname $0)

source "$SCRIPT_DIR/config"

function bootstrap {
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"
    mount -t tmpfs -o size="$TMPFS_SIZE" none "$ROOTFS"
    apt-get update
    apt-get install -y debootstrap curl

    debootstrap --variant="$VARIANT" --include="$VENTI_INCLUDE" \
        "$SUITE" "$ROOTFS" "$MIRROR"

    curl -o dumb-init.deb -L "$DUMBINIT_URL"
    dpkg --root "$ROOTFS" -i dumb-init.deb

    curl -o go-linux.tar.gz -L "$GOLANG_URL"
    tar -xf go-linux.tar.gz -C "$ROOTFS"

    chroot "$ROOTFS" /bin/bash -c 'GOROOT=/go GOPATH=/gocode PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin go get github.com/tools/godep'
}

function cleanup {
    pushd "$ROOTFS"
    rm -rf var/lib/apt/lists/*
    rm -rf var/cache/apt/archives/*
    rm -rf var/cache/debconf/*old
    popd
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

