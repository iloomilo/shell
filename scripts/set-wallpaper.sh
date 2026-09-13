#!/bin/sh
set -eu

preview=0
scheme=""

while [ "$#" -gt 1 ]; do
    case "$1" in
        --preview)
            preview=1
            shift
            ;;
        --scheme)
            scheme="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -lt 1 ]; then
    echo "Usage: set-wallpaper.sh [--preview] [--scheme TYPE] /path/to/image" >&2
    exit 1
fi

img=$(realpath -- "$1")

if [ ! -f "$img" ]; then
    echo "Error: '$img' does not exist." >&2
    exit 1
fi

if [ "$preview" -eq 1 ]; then
    transition=fade
    duration=0.5
else
    transition=wipe
    duration=1.2
fi

if command -v awww >/dev/null 2>&1; then
    awww img "$img" --transition-type "$transition" --transition-duration "$duration"
elif command -v swww >/dev/null 2>&1; then
    swww img "$img" --transition-type "$transition" --transition-duration "$duration"
else
    echo "Error: neither awww nor swww is installed." >&2
    exit 1
fi

if command -v matugen >/dev/null 2>&1; then
    if [ -n "$scheme" ]; then
        matugen image "$img" --type "$scheme"
    else
        matugen image "$img"
    fi
fi
