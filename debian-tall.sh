#!/bin/bash

set -e
set -x

ROOTFS=/rootfs
SCRIPT_DIR=$(dirname $0)

source "$SCRIPT_DIR/config"

function bootstrap {
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"
    mount -t tmpfs -o size="$TMPFS_SIZE" none "$ROOTFS"
    apt-get update
    apt-get install -y curl

    apt-get download \
        busybox \
        libc6 \
        ca-certificates \
        libgcc1

    curl -o dumb-init.deb -L "$DUMBINIT_URL"

    for pkg in *.deb; do
        dpkg-deb --fsys-tarfile "$pkg" | tar -xf - -C "$ROOTFS";
    done

    chroot "$ROOTFS/" /bin/busybox --install /bin

    find "$ROOTFS/usr/share/ca-certificates" -name '*.crt' \
        | xargs cat > "$ROOTFS/etc/ssl/certs/ca-certificates.crt"
}

function cleanup {
    rm -rf "$ROOTFS/usr/share/"
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

