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
    apt-get install -y cdebootstrap curl ca-certificates

    cdebootstrap --flavour="$FLAVOUR" --include="$BOOTSTRAP_INCLUDE" \
        "$SUITE" "$ROOTFS" "$MIRROR"

    # Installing dumb-init
    curl -o dumb-init.deb -L "$DUMBINIT_URL"
    dpkg --root "$ROOTFS" -i dumb-init.deb

    cp -r -t "$ROOTFS" "$SCRIPT_DIR"/rootfs/*

    # Configure locales
    chroot "$ROOTFS" /usr/sbin/locale-gen
    chroot "$ROOTFS" /usr/sbin/locale-gen en_US.UTF-8
    chroot "$ROOTFS" /usr/sbin/dpkg-reconfigure locales

}

function cleanup {
    # Remove unused packages
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

