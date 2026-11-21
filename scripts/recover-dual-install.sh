#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-}"

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

RECOVERY="$ROOT/.voipcentra-recovery-$(date +%Y%m%d-%H%M%S)-$$"

[[ ! -e "$RECOVERY" && ! -L "$RECOVERY" ]] || exit 1

# Preserve files in a uniquely named recovery directory.
python3 "$SCRIPT_DIR/atomic-publish.py" \
    "$PREMIUM" "$RECOVERY"

echo "RECOVERY COMPLETE: Premium files preserved."
echo "RECOVERY LOCATION: $RECOVERY"
