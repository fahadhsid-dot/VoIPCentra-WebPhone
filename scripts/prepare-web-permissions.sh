#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" || ! -d "$TARGET" || -L "$TARGET" ]]; then
    echo "SAFETY STOP: Invalid staging directory."
    exit 1
fi

# Development staging only.
case "$TARGET" in
    /tmp/voipcentra-dual-*/.voipcentra-install.*|\
    /tmp/voipcentra-dual-*/.viciphone-stage.*)
        ;;
    *)
        echo "SAFETY STOP: Path is not an approved staging directory."
        exit 1
        ;;
esac

# Never follow symlinks when preparing deployment files.
if find -P "$TARGET" -type l -print -quit | grep -q .; then
    echo "SAFETY STOP: Symlinks found in staging."
    exit 1
fi

find -P "$TARGET" -type d -exec chmod 755 {} +
# Preserve executable scripts while normalizing regular files.
find -P "$TARGET" -type f -perm /111 -exec chmod 755 {} +
find -P "$TARGET" -type f ! -perm /111 -exec chmod 644 {} +

echo "PASS: Staging permissions normalized."
