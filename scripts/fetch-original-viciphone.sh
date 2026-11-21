#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/vicimikec/ViciPhone.git"
BRANCH="v3.0"
EXPECTED="24e98fccfa7b7079fff970e02fca5f002ac1f2cc"

SOURCE="${1:-/tmp/ViciPhone-Original-3.0}"

echo "=== ORIGINAL VICIPHONE SOURCE VERIFICATION ==="

command -v git >/dev/null || {
    echo "ERROR: Git missing"
    exit 1
}

if [[ -d "$SOURCE/.git" ]]; then
    echo "EXISTING SOURCE FOUND"

elif [[ -e "$SOURCE" || -L "$SOURCE" ]]; then
    echo "SAFETY STOP: Destination already occupied"
    exit 1

else
    echo "DOWNLOADING ORIGINAL VICIPHONE 3.0"

    PARENT="$(dirname "$SOURCE")"
    [[ -d "$PARENT" && ! -L "$PARENT" ]] || {
        echo "ERROR: Source parent directory unavailable"
        exit 1
    }

    STAGING="$(mktemp -d "$PARENT/.viciphone-source.XXXXXXXX")"
    trap 'rm -rf -- "$STAGING"' EXIT

    git clone --depth 1 --branch "$BRANCH" \
        "$REPO" "$STAGING" || {
        echo "ERROR: Clone failed"
        exit 1
    }

    STAGED_COMMIT="$(git -C "$STAGING" rev-parse HEAD)"
    [[ "$STAGED_COMMIT" == "$EXPECTED" ]] || {
        echo "ERROR: Downloaded source commit mismatch"
        exit 1
    }

    [[ ! -e "$SOURCE" && ! -L "$SOURCE" ]] || {
        echo "SAFETY STOP: Source destination appeared"
        exit 1
    }

    mv -T -- "$STAGING" "$SOURCE"
    trap - EXIT
fi

ACTUAL="$(git -C "$SOURCE" rev-parse HEAD)"
REMOTE="$(git -C "$SOURCE" remote get-url origin)"

if [[ "$REMOTE" != "$REPO" ]]; then
    echo "ERROR: Unexpected source repository"
    exit 1
fi

if [[ "$ACTUAL" != "$EXPECTED" ]]; then
    echo "ERROR: Unexpected source commit"
    echo "Expected: $EXPECTED"
    echo "Actual:   $ACTUAL"
    exit 1
fi

if [[ -n "$(git -C "$SOURCE" status --porcelain)" ]]; then
    echo "ERROR: Source contains local changes"
    exit 1
fi

for FILE in LICENSE src/viciphone.php src/vp_template.php; do
    [[ -s "$SOURCE/$FILE" ]] || {
        echo "ERROR: Missing required file: $FILE"
        exit 1
    }
done

echo "SOURCE VERIFIED: $ACTUAL"
echo "LICENSE FILE: PRESENT"
echo "READY FOR ISOLATED INSTALLATION"
