#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 1. Source tracking check: every .s / .inc in src/ must be listed in .make/build.sh
if [[ -d src ]]; then
    for f in src/*.s src/*.inc; do
        if [[ -f "$f" ]]; then
            if ! grep -q "$f" .make/build.sh; then
                echo "Error: $f is not listed in .make/build.sh" >&2
                exit 1
            fi
        fi
    done
fi

echo "Source tracking check passed."

# 2. Check build
./.make/build.sh
echo "Build succeeded."

# 3. Mojave test if demos/99_test.bas exists
if [[ -f demos/99_test.bas ]] && command -v mojave >/dev/null 2>&1; then
    echo "Running simulator regression test..."
    OUTPUT=$(mojave --machine m6502 --load-bin bin/pbasic.bin@0000 < demos/99_test.bas 2>&1 || true)
    
    if ! echo "$OUTPUT" | grep -q -- "--- TEST COMPLETE ---"; then
        echo "Regression test failed: '--- TEST COMPLETE ---' not found" >&2
        echo "$OUTPUT"
        exit 1
    fi
    echo "Regression test passed."
fi

echo "All checks passed."
