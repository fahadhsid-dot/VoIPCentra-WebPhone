#!/usr/bin/env bash
set -euo pipefail

# VoIPCentra Original ViciPhone 3.0 Installer
# Development version: isolated test installation only.

SOURCE="/tmp/ViciPhone-Original-v2.2-Fresh"
WEBROOT="${VOIPCENTRA_TEST_ROOT:-/tmp/voipcentra-dual-v2.2-test}"
TARGET="$WEBROOT/ViciPhone"
EXPECTED_COMMIT="24e98fccfa7b7079fff970e02fca5f002ac1f2cc"

echo "=== ORIGINAL VICIPHONE 3.0 INSTALLER ==="

# Production deployment deliberately disabled in this stage.
[[ "$WEBROOT" =~ ^/tmp/voipcentra-dual-[A-Za-z0-9._-]+$ && ! -L "$WEBROOT" ]] || {
    echo "SAFETY STOP: Invalid isolated test directory."
    exit 1
}

for tool in git php tar mktemp; do
    command -v "$tool" >/dev/null || {
        echo "ERROR: Missing dependency: $tool"
        exit 1
    }
done

# Acquire shared deployment lock before any source fetching.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/deployment-lock.sh"
voipcentra_acquire_lock "$WEBROOT" || exit 1

# Fetch or verify the exact approved upstream revision.

bash "$SCRIPT_DIR/fetch-original-viciphone.sh" "$SOURCE" || {
    echo "ERROR: Original ViciPhone source verification failed."
    exit 1
}

COMMIT="$(git -C "$SOURCE" rev-parse HEAD)"

[[ "$COMMIT" == "$EXPECTED_COMMIT" ]] || {
    echo "ERROR: Unexpected original source revision."
    exit 1
}

[[ -z "$(git -C "$SOURCE" status --porcelain)" ]] || {
    echo "ERROR: Original source has local changes."
    exit 1
}

[[ ! -e "$TARGET" && ! -L "$TARGET" ]] || {
    echo "SAFETY STOP: Installation already exists."
    exit 1
}

mkdir -p "$WEBROOT"

STAGING="$(mktemp -d "$WEBROOT/.viciphone-stage.XXXXXXXX")"
trap 'rm -rf -- "$STAGING"' EXIT

git -C "$SOURCE" archive HEAD | tar -C "$STAGING" -xf -

for file in LICENSE src/viciphone.php src/vp_template.php; do
    [[ -s "$STAGING/$file" ]] || {
        echo "ERROR: Missing required file: $file"
        exit 1
    }
done

php -l "$STAGING/src/viciphone.php"
php -l "$STAGING/src/vp_template.php"

# Final destination check before publishing staged files.
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    echo "SAFETY STOP: Destination already exists."
    exit 1
fi

# Stage on the same filesystem, then publish without
# copying partially prepared files into the destination.
mv -T -- "$STAGING" "$TARGET"
trap - EXIT

echo "INSTALLATION COMPLETE: $TARGET"
echo "SOURCE COMMIT: $EXPECTED_COMMIT"
echo "LICENSE: AGPL-3.0"
echo "VICIdial settings and SIP configuration unchanged."
