#!/bin/bash

set -e
set -x

ROOTFS=/rootfs/
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

    cdebootstrap --flavour="$FLAVOUR" --include="$BOOTSTRAP_INCLUDE" \
        "$SUITE" "$ROOTFS" "$MIRROR"

    # Installing dumb-init
    curl -o dumb-init.deb -L "$DUMBINIT_URL"
    dpkg --root "$ROOTFS" -i dumb-init.deb

    cp -r -t "$ROOTFS" "$SCRIPT_DIR"/rootfs/*

    echo 'Acquire::Language { "en"; };' >  "$ROOTFS/etc/apt/apt.conf.d/99translations"
    echo 'APT::Install-Recommends "0";' >  "$ROOTFS/etc/apt/apt.conf.d/00apt"
    echo 'APT::Install-Suggests "0";'   >> "$ROOTFS/etc/apt/apt.conf.d/00apt"
    # Disable sync after every package installed
    echo 'force-unsafe-io' > "$ROOTFS/etc/dpkg/dpkg.cfg.d/02apt-speedup"

    # Automatic apt-get clean after apt-get ops
    echo 'DSELECT::Clean "always";' > "$ROOTFS/etc/apt/apt.conf.d/99AutomaticClean"

    # Select default suite
    echo "APT::Default-Release \"$SUITE\";" > "$ROOTFS/etc/apt/apt.conf.d/01defaultrelease"

    # Configure locales
    chroot "$ROOTFS" /usr/sbin/locale-gen
    chroot "$ROOTFS" /usr/sbin/locale-gen en_US.UTF-8
    chroot "$ROOTFS" /usr/sbin/dpkg-reconfigure locales

    echo 'deb http://httpredir.debian.org/debian/ '"${DEBIAN_VERSION}"' main contrib non-free' > "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://httpredir.debian.org/debian/ '"${DEBIAN_VERSION}"'-updates main contrib non-free' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://security.debian.org/ '"${DEBIAN_VERSION}"'/updates main contrib non-free' >> "$ROOTFS/etc/apt/sources.list"

    chroot "$ROOTFS" /usr/bin/apt-get update
    chroot "$ROOTFS" /usr/bin/apt-get dist-upgrade --yes

    chroot "$ROOTFS" echo "localepurge localepurge/nopurge multiselect en,en_US.UTF-8" | debconf-set-selections
    chroot "$ROOTFS" apt-get install -y localepurge
    chroot "$ROOTFS" dpkg-reconfigure localepurge
    chroot "$ROOTFS" localepurge
}

function cleanup {
    # Remove unused packages
    chroot "$ROOTFS" dpkg -P --force-remove-essential \
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
        systemd \
        systemd-sysv \
        udev

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
