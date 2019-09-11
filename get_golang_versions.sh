#!/usr/bin/env bash
# -*- mode: bash; -*-

# File: get_golang.sh
# Copyright 2019 Gravitational, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */

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

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

bash_version=$(echo $BASH_VERSION | cut -d '.' -f 1,2)
if version_gt $bash_version 4.3; then
    readarray releases_list <<< $(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' | uniq )
else
    read -a releases_list <<< $(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' | uniq )
fi

latest_release=${releases_list[0]}
latest_major_release=$(cut -d '.' -f 1 <<< ${releases_list[0]})"."$(cut -d . -f 2 <<< ${releases_list[0]})

previous_major_release=$(decrement_version $latest_major_release)
previous_major_release2=$(decrement_version $previous_major_release)

previous_release=$(find_latest_minor_release ${releases_list[@]} $previous_major_release)
previous_release2=$(find_latest_minor_release ${releases_list[@]} $previous_major_release2)

echo $latest_release
echo $previous_release
echo $previous_release2
