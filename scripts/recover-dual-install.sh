#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-}"
EXPECTED_TX="${2:-}"

[[ "$EXPECTED_TX" =~ ^[0-9a-f]{32}$ ]] || {
    echo "SAFETY STOP: Valid transaction ID required."
    exit 1
}

# Manual recovery remains strictly test-only.
[[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]] || {
    echo "SAFETY STOP: Recovery is test-only."
    exit 1
}

[[ "${VOIPCENTRA_TEST_RECOVERY_ACK:-}" == "RECOVER_TEST_PREMIUM" ]] || {
    echo "SAFETY STOP: Explicit recovery approval required."
    exit 1
}

[[ "$ROOT" =~ ^/tmp/voipcentra-dual-[A-Za-z0-9._-]+$ ]] || {
    echo "SAFETY STOP: Invalid test root."
    exit 1
}

[[ -d "$ROOT" && ! -L "$ROOT" ]] || {
    echo "SAFETY STOP: Test root unavailable."
    exit 1
}

# Recovery must not run concurrently with deployment.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deployment-lock.sh"
voipcentra_acquire_lock "$ROOT" || exit 1

PREMIUM="$ROOT/VoIPCentra-WebPhone"
ORIGINAL="$ROOT/ViciPhone"

[[ -d "$PREMIUM" && ! -L "$PREMIUM" ]] || {
    echo "SAFETY STOP: No valid Premium deployment found."
    exit 1
}

[[ ! -e "$ORIGINAL" && ! -L "$ORIGINAL" ]] || {
    echo "SAFETY STOP: Original installation already exists."
    exit 1
}

[[ -s "$PREMIUM/src/viciphone.php" ]] || {
    echo "SAFETY STOP: Premium installation incomplete."
    exit 1
}

MARKER="$PREMIUM/.voipcentra-transaction-id"

[[ -f "$MARKER" && ! -L "$MARKER" ]] || {
    echo "SAFETY STOP: Transaction marker missing."
    exit 1
}

ACTUAL_TX="$(cat "$MARKER")"

[[ "$ACTUAL_TX" == "$EXPECTED_TX" ]] || {
    echo "SAFETY STOP: Transaction ID mismatch."
    exit 1
}

# Require a valid FAILED transaction journal before moving files.
python3 - "$ROOT" "$EXPECTED_TX" <<'JOURNAL_CHECK'
import json
import os
import stat
import sys
from pathlib import Path

root = Path(sys.argv[1])
tx = sys.argv[2]
journal = root / (".voipcentra-transaction-" + tx + ".json")

flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC
fd = os.open(str(journal), flags)

with os.fdopen(fd, "r") as handle:
    info = os.fstat(handle.fileno())

    if not stat.S_ISREG(info.st_mode):
        raise RuntimeError("Recovery journal is not regular")

    if info.st_nlink != 1:
        raise RuntimeError("Recovery journal hardlink rejected")

    if info.st_uid != os.geteuid():
        raise RuntimeError("Recovery journal owner mismatch")

    if stat.S_IMODE(info.st_mode) & 0o077:
        raise RuntimeError("Recovery journal permissions unsafe")

    data = json.load(handle)

expected = ["STARTED", "PREMIUM_INSTALLED", "FAILED"]

if not isinstance(data, dict):
    raise RuntimeError("Invalid recovery journal")

if data.get("transaction_id") != tx:
    raise RuntimeError("Recovery journal transaction mismatch")

if data.get("current_state") != "FAILED":
    raise RuntimeError("Recovery journal is not FAILED")

history = data.get("history")

if not isinstance(history, list):
    raise RuntimeError("Invalid recovery history")

if any(not isinstance(entry, dict) for entry in history):
    raise RuntimeError("Invalid recovery history entry")

states = [entry.get("state") for entry in history]

if states != expected:
    raise RuntimeError("Recovery journal history mismatch")

print("PASS: FAILED transaction journal verified")
JOURNAL_CHECK

echo "PASS: Recovery transaction verified."

RECOVERY="$ROOT/.voipcentra-recovery-$(date +%Y%m%d-%H%M%S)-$$"

[[ ! -e "$RECOVERY" && ! -L "$RECOVERY" ]] || exit 1

# Preserve files in a uniquely named recovery directory.
python3 "$SCRIPT_DIR/atomic-publish.py" \
    "$PREMIUM" "$RECOVERY"

echo "RECOVERY COMPLETE: Premium files preserved."
echo "RECOVERY LOCATION: $RECOVERY"
