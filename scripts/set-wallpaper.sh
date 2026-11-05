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

# Static palettes use the same Matugen templates and reload hooks as wallpaper
# palettes, but import fixed colors instead of deriving them from the image.
palette=""
case "$scheme" in
    static-catppuccin-latte|static-catppuccin-frappe|static-catppuccin-macchiato|static-catppuccin-mocha|static-nord)
        script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
        palette="$script_dir/../assets/themes/${scheme#static-}.json"
        if [ ! -r "$palette" ] || ! command -v matugen >/dev/null 2>&1; then
            echo "Error: static themes require Matugen and a readable palette: $palette" >&2
            exit 1
        fi
        ;;
    static-*)
        echo "Error: unknown static theme '$scheme'." >&2
        exit 1
        ;;
esac

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
    if [ -n "$palette" ]; then
        matugen json "$palette"
    elif [ -n "$scheme" ]; then
        matugen image "$img" --type "$scheme"
    else
        matugen image "$img"
    fi
fi
