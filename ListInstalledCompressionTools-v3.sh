#!/bin/env bash

############################################################################################################
# Define Files #                                                                                           #
############################################################################################################

COLORS_FILE="$(pwd)/conf/Colors2.conf"

############################################################################################################
# Define Functions #                                                                                       #
############################################################################################################

function SanityChecker() {
# Check if the file exists and is a regular file
    if [ -f "$COLORS_FILE" ]; then
        echo "Sourcing '$COLORS_FILE': [OK]. "
        source "$COLORS_FILE"
    else
        echo "ERROR: File '$COLORS_FILE' does not exist."
        return 1
    fi
}


echo " "
echo "${brightyellow} SmartCompress Diagnostic Utility ${reset} "
echo "${brightyellow} -------------------------------- ${reset} "
echo " "

echo "  ${brightyellow} [CATEGORY]: ${brightwhite} Tar/Gzip ${reset} "
echo "  --------------------------------"
for cmd in tar gzip gunzip pigz; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "    [\e[32mInstalled\e[0m] $cmd"
    else
        echo -e "    [\e[31mMissing\e[0m]   $cmd"
    fi
done

echo " "

echo "  ${brightyellow} [CATEGORY]: ${brightwhite} Bzip ${reset} "
echo "  --------------------------------"
for cmd in bzip2 bunzip2 pbzip2; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "    [\e[32mInstalled\e[0m] $cmd"
    else
        echo -e "    [\e[31mMissing\e[0m]   $cmd"
    fi
done

echo " "

echo "  ${brightyellow} [CATEGORY]: ${brightwhite} xz/zip/7z ${reset} "
echo "  --------------------------------"
for cmd in xz unxz pixz zip unzip 7z; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "    [\e[32mInstalled\e[0m] $cmd"
    else
        echo -e "    [\e[31mMissing\e[0m]   $cmd"
    fi
done

echo " "

echo "  ${brightyellow} [CATEGORY]: ${brightwhite} rar/zstd/lz4 ${reset} "
echo "  --------------------------------"
for cmd in rar unrar zstd lz4; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "    [\e[32mInstalled\e[0m] $cmd"
    else
        echo -e "    [\e[31mMissing\e[0m]   $cmd"
    fi
done

echo " "
