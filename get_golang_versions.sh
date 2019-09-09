#!/usr/bin/env bash
# -*- mode: bash; -*-

# File: get_golang.sh
# Copyright (C) 2019 Gravitational Inc.
# Description: Find 3 latest major Golang releases

# set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

function decrement_version() {
    local VERSION="$1"

    local DECREMENTED_VERSION=
    if [[ "$VERSION" =~ .*\..* ]]; then
        DECREMENTED_VERSION="${VERSION%.*}.$((${VERSION##*.}-1))"
    else
        DECREMENTED_VERSION="$((${VERSION##*.}-1))"
    fi

    echo "$DECREMENTED_VERSION"
}

function find_latest_minor_release() {
    local RELEASES=("$@")
    local MAJOR_RELEASE="${RELEASES[-1]}"

    for version in ${RELEASES[@]}; do
        if [[ "$version" =~ ^"$MAJOR_RELEASE" ]];
        then
            echo $version
            break
        fi
    done
}

readarray releases_list <<< $(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 30 | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' | uniq )

latest_release=${releases_list[0]}
latest_major_release=$(cut -d '.' -f 1 <<< ${releases_list[0]})"."$(cut -d . -f 2 <<< ${releases_list[0]})

previous_major_release=$(decrement_version $latest_major_release)
previous_major_release2=$(decrement_version $previous_major_release)

previous_release=$(find_latest_minor_release ${releases_list[@]} $previous_major_release)
previous_release2=$(find_latest_minor_release ${releases_list[@]} $previous_major_release2)

echo $latest_release
echo $previous_release
echo $previous_release2
