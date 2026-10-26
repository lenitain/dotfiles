#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

resvg \
    -h 2560 -w 3840 \
    starry-night-sky.svg starry-night-sky.png \
    && oxipng \
        -o 4 \
        -a \
        --strip safe \
        --force \
        starry-night-sky.png
