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
        cdebootstrap curl ca-certificates ubuntu-keyring

    cdebootstrap --flavour="$FLAVOUR" --include="$BOOTSTRAP_INCLUDE" \
        --keyring "/usr/share/keyrings/ubuntu-archive-keyring.gpg" \
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

    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"' main restricted' > "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-updates main restricted' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"' universe' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-updates universe' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"' multiverse' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://archive.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-updates multiverse' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://security.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-security main restricted' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://security.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-security universe' >> "$ROOTFS/etc/apt/sources.list"
    echo 'deb http://security.ubuntu.com/ubuntu/ '"${UBUNTU_VERSION}"'-security multiverse' >> "$ROOTFS/etc/apt/sources.list"

    chroot "$ROOTFS" /usr/bin/apt-get update
    chroot "$ROOTFS" /usr/bin/apt-get dist-upgrade --yes

    chroot "$ROOTFS" echo "localepurge localepurge/nopurge multiselect en,en_US.UTF-8" | debconf-set-selections
    chroot "$ROOTFS" apt-get install -y localepurge ucf
    chroot "$ROOTFS" dpkg-reconfigure localepurge
    chroot "$ROOTFS" localepurge
}

function cleanup {
    # Remove unused packages
    chroot "$ROOTFS" dpkg -P --force-remove-essential \
        e2fsprogs
    
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
