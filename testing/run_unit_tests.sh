#!/usr/bin/env bash
# QuakeC unit test runner.
set -euo pipefail

GAME_DIR=/workspace/game
QUAKEC_DIR=/workspace/repos/quakec
OUTPUT_LOG=/workspace/quakec-unit-tests.log

is_linux_x86_64() {
    [[ -f "$1" ]] && file -b "$1" | grep -Eq '^ELF 64-bit .*x86-64'
}

TEST_BINARY="$GAME_DIR/qc-test-nzportable64"
DEFAULT_BINARY="$GAME_DIR/nzportable64"

# An explicit Vril ref must always be compiled, even when a prior test binary
# is available. Otherwise, reuse a valid test binary or the fetched Linux game.
if [[ -n "${VRIL_OVERRIDE:-}" ]]; then
    echo '[INFO] Building overridden Vril engine...'
    /entrypoint.sh build-vril --target linux-x86_64 --clean
    cp /workspace/repos/vril-engine/build/sdl/nzportable "$TEST_BINARY"
elif ! is_linux_x86_64 "$TEST_BINARY" && ! is_linux_x86_64 "$DEFAULT_BINARY"; then
    echo '[INFO] No Linux x86_64 game executable found; building Vril...'
    /entrypoint.sh build-vril --target linux-x86_64 --clean
    cp /workspace/repos/vril-engine/build/sdl/nzportable "$TEST_BINARY"
fi

if is_linux_x86_64 "$TEST_BINARY"; then
    GAME_BINARY="$TEST_BINARY"
else
    GAME_BINARY="$DEFAULT_BINARY"
fi
if ! is_linux_x86_64 "$GAME_BINARY"; then
    echo "[ERROR] No usable Linux x86_64 game executable was produced." >&2
    exit 1
fi
chmod +x "$GAME_BINARY"

if [[ -n "${ASSETS_OVERRIDE:-}" ]]; then
    echo "[INFO] Building overridden assets..."
    /entrypoint.sh build-map --full
    /entrypoint.sh build-assets
fi

echo "[INFO] Building test QuakeC..."
/entrypoint.sh build-quakec --test-mode
cp "$QUAKEC_DIR/build/standard/progs.dat" "$GAME_DIR/nzp/progs.dat"

echo "[INFO] Running unit tests..."
cd "$GAME_DIR"
set +e
"$GAME_BINARY" +map nzp_warehouse +vid_renderer headless | tee "$OUTPUT_LOG"
game_status=${PIPESTATUS[0]}
set -e
if (( game_status != 0 )); then
    echo "[ERROR] Game exited with status $game_status" >&2
    exit 1
fi

failed_count=$(awk '/^\* Failed: / { print $3 }' "$OUTPUT_LOG")
if [[ -z "$failed_count" ]]; then
    echo "[ERROR] Unit test summary was not generated" >&2
    exit 1
fi
if (( failed_count != 0 )); then
    echo "[ERROR] $failed_count unit tests failed" >&2
    exit 1
fi

echo "[INFO] Unit tests passed."
