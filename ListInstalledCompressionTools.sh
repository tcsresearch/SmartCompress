#!/bin/env bash

for cmd in tar gzip gunzip bzip2 bunzip2 xz unxz zip unzip 7z rar unrar zstd lz4; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "[\e[32mInstalled\e[0m] $cmd"
    else
        echo -e "[\e[31mMissing\e[0m]   $cmd"
    fi
done
