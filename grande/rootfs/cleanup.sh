#!/bin/sh

set -e

localepurge

apt-get autoclean
apt-get clean

find /var/cache/apt/archives -type f -delete
find /var/cache/debconf -iname '*old' -and -type f -delete

find /var/lib/apt/lists -type f -delete

find /usr/share/locale -type f -delete

find /usr/share/doc -type f -delete
find /usr/share/man -type f -delete
