#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p bin

FILES=(
    src/defs.inc
    src/main.s
)

TMP_ASM=$(mktemp /tmp/pbasic_XXXXXX.s)
TMP_OBJ=$(mktemp /tmp/pbasic_XXXXXX.o)
trap 'rm -f "$TMP_ASM" "$TMP_OBJ"' EXIT

# Concatenate files that exist
for f in "${FILES[@]}"; do
    if [[ -f "$f" ]]; then
        cat "$f" >> "$TMP_ASM"
        echo "" >> "$TMP_ASM"
    fi
done

if command -v ca65 >/dev/null 2>&1 && command -v ld65 >/dev/null 2>&1; then
    ca65 "$TMP_ASM" -o "$TMP_OBJ"
    ld65 -C .make/pbasic.cfg "$TMP_OBJ" -o bin/pbasic.bin
else
    echo "Error: ca65 or ld65 not found (please install cc65)" >&2
    exit 1
fi
