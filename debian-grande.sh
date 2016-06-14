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

    debootstrap --variant="$VARIANT" --include="$GRANDE_INCLUDE" \
        "$SUITE" "$ROOTFS" "$MIRROR"

    curl -o dumb-init.deb -L "$DUMBINIT_URL"
    dpkg --root "$ROOTFS" -i dumb-init.deb
}

function cleanup {
    chroot "$ROOTFS" dpkg -P --force-remove-essential \
        adduser \
        debconf-i18n \
        dmsetup \
        e2fslibs \
        e2fsprogs \
        gcc-4.8-base \
        init \
        libcryptsetup4 \
        libdevmapper1.02.1 \
        liblocale-gettext-perl \
        libtext-charwidth-perl \
        libtext-iconv-perl \
        libtext-wrapi18n-perl \
        login \
        systemd \
        systemd-sysv \
        udev
    pushd "$ROOTFS"
    rm -rf usr/share/{doc,man,locale,info}
    rm -rf lib/{udev,systemd}
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

