#!/usr/bin/env bash

# ==============================================================================
# Script Name: smartcompress-v2.sh 
# Description: Dynamically check system tools to compress or decompress files
#              and directories based on explicit speed or size criteria.
# ChangeLog:   Added support for PBzip2, pigz, and pixz.
# ==============================================================================

set -euo pipefail

show_help() {
    cat << EOF
Usage: $(basename "$0") [action] [options] <target>

Actions:
  -c, --compress      Compress the target file or directory (Default action)
  -d, --decompress    Decompress the target archive file

Options:
  -f, --fast          Optimize for SPEED (uses lz4, parallel pigz, or low-level zstd)
  -s, --size          Optimize for SIZE (uses parallel pixz, max xz, or max pbzip2)
  -h, --help          Display this help documentation

Examples:
  $(basename "$0") -c -s my_folder/       # Compress folder maximizing space savings
  $(basename "$0") -c -f big_log.log      # Compress file instantly optimizing for speed
  $(basename "$0") -d archive.tar.zst     # Intelligently extract an archive
EOF
}

best_compressor() {
    local mode="$1"
    local target="$2"

    if [[ ! -e "$target" ]]; then
        echo "Error: Target '$target' does not exist." >&2
        return 1
    fi

    # Evaluation Layer: Identify target type
    local is_dir=false
    if [[ -d "$target" ]]; then
        is_dir=true
        target="${target%/}"
    fi

    case "$mode" in
        "size")
            # Size priority: pixz -> xz -> zstd -> pbzip2 -> bzip2 -> pigz -> gzip
            if command -v pixz >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using parallel pixz (-9)..."
                if $is_dir; then tar -cf - "$target" | pixz -9 > "${target}.tar.xz"; else pixz -9 < "$target" > "${target}.xz"; fi
            elif command -v xz >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using xz (-9)..."
                if $is_dir; then tar -cf - "$target" | xz -9 > "${target}.tar.xz"; else xz -9 -k "$target"; fi
            elif command -v zstd >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using zstd (--ultra -22)..."
                if $is_dir; then tar -cf - "$target" | zstd --ultra -22 > "${target}.tar.zst"; else zstd --ultra -22 "$target"; fi
            elif command -v pbzip2 >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using parallel pbzip2 (-9)..."
                if $is_dir; then tar -cf - "$target" | pbzip2 -9 > "${target}.tar.bz2"; else pbzip2 -9 -k "$target"; fi
            elif command -v bzip2 >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using bzip2 (-9)..."
                if $is_dir; then tar -cf - "$target" | bzip2 -9 > "${target}.tar.bz2"; else bzip2 -9 -k "$target"; fi
            elif command -v pigz >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using parallel pigz (-9)..."
                if $is_dir; then tar -cf - "$target" | pigz -9 > "${target}.tar.gz"; else pigz -9 -k "$target"; fi
            elif command -v gzip >/dev/null 2>&1; then
                echo "Optimizing for SIZE: Using gzip (-9)..."
                if $is_dir; then tar -cf - "$target" | gzip -9 > "${target}.tar.gz"; else gzip -9 -k "$target"; fi
            else
                echo "Error: No compression utilities found on this system." >&2
                return 1
            fi
            ;;

        "speed")
            # Speed priority: lz4 -> zstd -> pigz -> gzip
            if command -v lz4 >/dev/null 2>&1; then
                echo "Optimizing for SPEED: Using lz4..."
                if $is_dir; then tar -cf - "$target" | lz4 - "${target}.tar.lz4"; else lz4 "$target" "${target}.lz4"; fi
            elif command -v zstd >/dev/null 2>&1; then
                echo "Optimizing for SPEED: Using zstd (-1)..."
                if $is_dir; then tar -cf - "$target" | zstd -1 > "${target}.tar.zst"; else zstd -1 "$target"; fi
            elif command -v pigz >/dev/null 2>&1; then
                echo "Optimizing for SPEED: Using parallel pigz (-1)..."
                if $is_dir; then tar -cf - "$target" | pigz -1 > "${target}.tar.gz"; else pigz -1 -k "$target"; fi
            elif command -v gzip >/dev/null 2>&1; then
                echo "Optimizing for SPEED: Using gzip (-1)..."
                if $is_dir; then tar -cf - "$target" | gzip -1 > "${target}.tar.gz"; else gzip -1 -k "$target"; fi
            else
                echo "Error: No speed-optimized utilities found on this system." >&2
                return 1
            fi
            ;;

        "balanced")
            # Balanced priority: zstd -> lz4 -> pixz -> xz -> pbzip2 -> bzip2 -> pigz -> gzip
            if command -v zstd >/dev/null 2>&1; then
                echo "Using balanced zstd (-3)..."
                if $is_dir; then tar -cf - "$target" | zstd -3 > "${target}.tar.zst"; else zstd -3 "$target"; fi
            elif command -v lz4 >/dev/null 2>&1; then
                echo "Using balanced lz4..."
                if $is_dir; then tar -cf - "$target" | lz4 - "${target}.tar.lz4"; else lz4 "$target" "${target}.lz4"; fi
            elif command -v pixz >/dev/null 2>&1; then
                echo "Using balanced parallel pixz..."
                if $is_dir; then tar -cf - "$target" | pixz > "${target}.tar.xz"; else pixz < "$target" > "${target}.xz"; fi
            elif command -v xz >/dev/null 2>&1; then
                echo "Using balanced xz (-6)..."
                if $is_dir; then tar -cf - "$target" | xz -6 > "${target}.tar.xz"; else xz -6 -k "$target"; fi
            elif command -v pbzip2 >/dev/null 2>&1; then
                echo "Using balanced parallel pbzip2..."
                if $is_dir; then tar -cf - "$target" | pbzip2 > "${target}.tar.bz2"; else pbzip2 -k "$target"; fi
            elif command -v bzip2 >/dev/null 2>&1; then
                echo "Using balanced bzip2..."
                if $is_dir; then tar -cf - "$target" | bzip2 > "${target}.tar.bz2"; else bzip2 -k "$target"; fi
            elif command -v pigz >/dev/null 2>&1; then
                echo "Using balanced parallel pigz..."
                if $is_dir; then tar -cf - "$target" | pigz > "${target}.tar.gz"; else pigz -k "$target"; fi
            else
                echo "Using balanced gzip..."
                if $is_dir; then tar -cf - "$target" | gzip > "${target}.tar.gz"; else gzip -k "$target"; fi
            fi
            ;;
    esac
}

best_decompressor() {
    local archive="$1"

    if [[ ! -f "$archive" ]]; then
        echo "Error: Archive file '$archive' does not exist or is not a regular file." >&2
        return 1
    fi

    case "$archive" in
        *.tar.xz)
            if command -v pixz >/dev/null 2>&1; then
                echo "Extracting tar.xz archive using parallel pixz..."
                pixz -dc "$archive" | tar -xf -
            elif command -v xz >/dev/null 2>&1; then
                echo "Extracting tar.xz archive using xz..."
                xz -dc "$archive" | tar -xf -
            else
                echo "Error: pixz or xz is required but neither is installed." >&2; return 1
            fi ;;
        *.xz)
            if command -v pixz >/dev/null 2>&1; then
                echo "Decompressing xz file using parallel pixz..."
                pixz -d < "$archive" > "${archive%.xz}"
            elif command -v xz >/dev/null 2>&1; then
                echo "Decompressing xz file using xz..."
                xz -d -k "$archive"
            else
                echo "Error: pixz or xz is required but neither is installed." >&2; return 1
            fi ;;
        *.tar.zst)
            if ! command -v zstd >/dev/null 2>&1; then echo "Error: zstd is required but not installed." >&2; return 1; fi
            echo "Extracting tar.zst archive using zstd..."
            zstd -dc "$archive" | tar -xf - ;;
        *.zst)
            if ! command -v zstd >/dev/null 2>&1; then echo "Error: zstd is required but not installed." >&2; return 1; fi
            echo "Decompressing zstd file..."
            zstd -d "$archive" ;;
        *.tar.lz4)
            if ! command -v lz4 >/dev/null 2>&1; then echo "Error: lz4 is required but not installed." >&2; return 1; fi
            echo "Extracting tar.lz4 archive using lz4..."
            lz4 -dc "$archive" | tar -xf - ;;
        *.lz4)
            if ! command -v lz4 >/dev/null 2>&1; then echo "Error: lz4 is required but not installed." >&2; return 1; fi
            echo "Decompressing lz4 file..."
            lz4 -d "$archive" ;;
        *.tar.bz2)
            if command -v pbzip2 >/dev/null 2>&1; then
                echo "Extracting tar.bz2 archive using parallel pbzip2..."
                pbzip2 -dc "$archive" | tar -xf -
            elif command -v bzip2 >/dev/null 2>&1; then
                echo "Extracting tar.bz2 archive using bzip2..."
                bzip2 -dc "$archive" | tar -xf -
            else
                echo "Error: pbzip2 or bzip2 is required but neither is installed." >&2; return 1
            fi ;;
        *.bz2)
            if command -v pbzip2 >/dev/null 2>&1; then
                echo "Decompressing bzip2 file using parallel pbzip2..."
                pbzip2 -d -k "$archive"
            elif command -v bzip2 >/dev/null 2>&1; then
                echo "Decompressing bzip2 file using bzip2..."
                bzip2 -d -k "$archive"
            else
                echo "Error: pbzip2 or bzip2 is required but neither is installed." >&2; return 1
            fi ;;
        *.tar.gz|*.tgz)
            if command -v pigz >/dev/null 2>&1; then
                echo "Extracting tar.gz archive using parallel pigz..."
                pigz -dc "$archive" | tar -xf -
            elif command -v gzip >/dev/null 2>&1; then
                echo "Extracting tar.gz archive using gzip..."
                gzip -dc "$archive" | tar -xf -
            else
                echo "Error: pigz or gzip is required but neither is installed." >&2; return 1;
            fi ;;
      *.gz)
          if command -v pigz >/dev/null 2>&1; then
              echo "Decompressing gzip file using parallel pigz..."
              pigz -d -k "$archive"
          elif command -v gzip >/dev/null 2>&1; then
              echo "Decompressing gzip file using gzip..."
              gzip -d -k "$archive"
          else
              echo "Error: pigz or gzip is required but neither is installed." >&2; return 1;
              fi ;;
    *)
      echo "Error: Unsupported or unknown archive format for '$archive'." >&2
      return 1 ;;
  esac
}

#######################################################################################################################
# Main Orchestration #                                                                                                #
#######################################################################################################################

main() {
local action="compress"
local mode="balanced"
local target=""
# Parsing arguments natively supporting both long and short options
while [[ $# -gt 0 ]]; do
case "$1" in
-c|--compress)    action="compress"; shift ;;
-d|--decompress)  action="decompress"; shift ;;
-f|--fast|--speed) mode="speed"; shift ;;
-s|--size)        mode="size"; shift ;;
-h|--help)        show_help; exit 0 ;;
-*)               echo "Unknown option: $1" >&2; show_help; exit 1 ;;
*)                target="$1"; shift ;;
esac
done
if [[ -z "$target" ]]; then
echo "Error: No target file or directory specified." >&2
show_help
exit 1
fi
if [[ "$action" == "compress" ]]; then
best_compressor "$mode" "$target"
elif [[ "$action" == "decompress" ]]; then
best_decompressor "$target"
fi
}
main "$@"

### Notable Implementation Details:
# * **`-k` Flag Safety**: Like `bzip2`, `pbzip2` supports the `-k` (`--keep`) flag natively, meaning it handles standard file-to-file retention cleanly without streaming compromises.
# * **Cascading Priority Layers**: In the `size` optimization layer, `pbzip2` is placed ahead of `bzip2`, but left behind modern engines like `xz` and `zstd` which yield better ratios even over parallel blocks.


