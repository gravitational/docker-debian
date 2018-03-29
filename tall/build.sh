#!/bin/bash

set -e
set -x

ROOTFS=/rootfs
SCRIPT_DIR=$(dirname "$0")

source "$SCRIPT_DIR/config"

function bootstrap {
    # Make in-ram new root
    rm -rf "$ROOTFS"
    mkdir -p "$ROOTFS"
    mount -t tmpfs -o size="$TMPFS_SIZE" none "$ROOTFS"

    # Packages required for building rootfs
    apt-get update
    apt-get install -y --no-install-recommends \
        cdebootstrap curl ca-certificates

    apt-get download \
        busybox \
        libc6 \
        ca-certificates \
        libgcc1

    # Installing dumb-init and downloaded debs
    curl -o dumb-init.deb -L "$DUMBINIT_URL"

    for pkg in *.deb; do
        dpkg-deb --fsys-tarfile "$pkg" | tar -xf - -C "$ROOTFS";
    done

    chroot "$ROOTFS/" /bin/busybox --install /bin

    # Collecting certificates from ca-certificates package to one file
    find "$ROOTFS/usr/share/ca-certificates" -name '*.crt' -print0 \
        | xargs -0 cat > "$ROOTFS/etc/ssl/certs/ca-certificates.crt"

    cp -r -t "$ROOTFS" "$SCRIPT_DIR"/rootfs/*
}

function cleanup {
    # cleanup.sh must be called ONBUILD too, DRY
    chroot "$ROOTFS" /bin/sh -c 'test -f /cleanup.sh && sh /cleanup.sh'
}

function output {
    cd "$ROOTFS"
    tar --one-file-system --numeric-owner -cf - ./*
}

function main {
    bootstrap 1>&2
    cleanup 1>&2
    output
}

main
