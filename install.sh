#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBROOT="/srv/www/htdocs/agc"
TARGET="$WEBROOT/VoIPCentra-WebPhone"

# Explicitly supported isolated test directory only
if [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]]; then
    WEBROOT="/tmp/voipcentra-installer-test-final"
    TARGET="$WEBROOT/VoIPCentra-WebPhone"
fi
BACKUP_DIR="/root/VoIPCentra-Backups"
MODE="${1:---check}"

check() {
    echo "=== VoIPCentra WebPhone Preflight ==="

    for tool in git php tar; do
        command -v "$tool" >/dev/null || {
            echo "ERROR: Missing $tool"
            exit 1
        }
    done

    [[ -d "$WEBROOT" ]] || {
        echo "ERROR: VICIdial web directory missing"
        exit 1
    }

    for file in \
        src/viciphone.php \
        src/vp_template.php \
        src/css/voipcentra.css \
        src/images/voipcentra-logo.svg
    do
        [[ -s "$SOURCE/$file" ]] || {
            echo "ERROR: Missing $file"
            exit 1
        }
        echo "OK: $file"
    done

    php -l "$SOURCE/src/viciphone.php"
    php -l "$SOURCE/src/vp_template.php"

    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        echo "EXISTING INSTALLATION: $TARGET"
    else
        echo "FRESH INSTALLATION POSSIBLE: $TARGET"
    fi

    echo "PREFLIGHT PASSED"
}

case "$MODE" in
    --check)
        check
        echo "READ ONLY: No changes made."
        ;;

    --dry-run)
        check
        echo
        echo "=== INSTALLATION PREVIEW ==="
        if [[ -e "$TARGET" || -L "$TARGET" ]]; then
            echo "SKIP: Existing installation will not be overwritten."
        else
            echo "PLAN: Copy WebPhone files into $TARGET"
            echo "PLAN: Preserve approved Premium v1.0 defaults."
        fi
        echo "VICIdial DB / SIP / WebRTC: No changes planned."
        ;;

    --install)
        check

        if [[ -e "$TARGET" || -L "$TARGET" ]]; then
            echo "SAFETY STOP: Existing installation detected."
            echo "No files changed: $TARGET"
            exit 1
        fi

        echo "Installing VoIPCentra WebPhone..."
        STAGING="$(mktemp -d "$WEBROOT/.voipcentra-install.XXXXXXXX")"
        trap 'rm -rf -- "$STAGING"' EXIT

        tar -C "$SOURCE" \
            --exclude=.git \
            --exclude='install.sh.phase*.bak' \
            -cf - . | tar -C "$STAGING" -xf -

        php -l "$STAGING/src/viciphone.php"
        php -l "$STAGING/src/vp_template.php"

        if [[ -e "$TARGET" || -L "$TARGET" ]]; then
            echo "SAFETY STOP: Target appeared during installation."
            exit 1
        fi

        mv -T -- "$STAGING" "$TARGET"
        trap - EXIT

        echo "INSTALLATION COMPLETE: $TARGET"
        echo "VICIdial integration must be configured and tested separately."
        ;;

    --check-vicidial)
        check
        echo
        echo "=== VICIDIAL INTEGRATION ==="
        bash "$SOURCE/scripts/check-vicidial-integration.sh"
        ;;

    --backup)
        [[ -d "$TARGET" && ! -L "$TARGET" ]] || {
            echo "ERROR: Existing directory not found."
            exit 1
        }

        mkdir -p -m 700 "$BACKUP_DIR"
        umask 077

        BACKUP="$BACKUP_DIR/VoIPCentra-WebPhone-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"

        tar -czf "$BACKUP" -C "$WEBROOT" VoIPCentra-WebPhone
        tar -tzf "$BACKUP" >/dev/null

        echo "BACKUP VERIFIED: $BACKUP"
        ;;

    *)
        echo "Usage: bash install.sh [--check|--dry-run|--backup|--install|--check-vicidial]"
        exit 1
        ;;
esac
