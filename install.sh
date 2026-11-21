#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBROOT="/srv/www/htdocs/agc"
TARGET="$WEBROOT/VoIPCentra-WebPhone"

# Explicitly supported isolated test directory only
if [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]]; then
    WEBROOT="/tmp/voipcentra-dual-v2.2-test"
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

        # Install tracked repository files only.
        # Refuse dirty source changes to avoid deploying an unreviewed mix.
        if [[ -n "$(git -C "$SOURCE" status --porcelain --untracked-files=no)" ]]; then
            echo "ERROR: Tracked source files have uncommitted changes."
            echo "Commit or restore changes before installation."
            exit 1
        fi

        git -C "$SOURCE" archive --format=tar HEAD |
            tar -C "$STAGING" -xf -

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

    --install-voipcentra)
        [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]] || {
            echo "SAFETY STOP: Dual installer development is test-only."
            exit 1
        }
        bash "$SOURCE/install.sh" --install
        ;;

    --install-original)
        [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]] || {
            echo "SAFETY STOP: Original installation is test-only."
            exit 1
        }
        bash "$SOURCE/scripts/install-original-viciphone.sh"
        ;;

    --install-both)
        [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]] || {
            echo "SAFETY STOP: Dual installation is test-only."
            exit 1
        }
        echo "=== DUAL WEBPHONE PREFLIGHT ==="

        PREMIUM_TARGET="$WEBROOT/VoIPCentra-WebPhone"
        ORIGINAL_TARGET="/tmp/voipcentra-dual-v2.2-test/ViciPhone"

        if [[ -e "$PREMIUM_TARGET" || -L "$PREMIUM_TARGET" ]]; then
            echo "SAFETY STOP: Premium installation already exists."
            exit 1
        fi

        if [[ -e "$ORIGINAL_TARGET" || -L "$ORIGINAL_TARGET" ]]; then
            echo "SAFETY STOP: Original installation already exists."
            exit 1
        fi

        [[ -d /tmp/ViciPhone-Original-3.0/.git ]] || {
            echo "ERROR: Original ViciPhone source missing."
            exit 1
        }

        echo "PREFLIGHT PASS: Both destinations available."
        echo "Installing VoIPCentra Premium..."
        bash "$SOURCE/install.sh" --install

        echo "Installing Original ViciPhone 3.0..."
        bash "$SOURCE/scripts/install-original-viciphone.sh"

        echo "DUAL INSTALLATION COMPLETE"
        ;;

    --check-compatibility)
        echo "=== UNIVERSAL SERVER COMPATIBILITY ==="
        bash "$SOURCE/scripts/check-server-compatibility.sh"
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
        echo "Usage: bash install.sh [--check|--dry-run|--backup|--install|--check-vicidial|--check-compatibility]"
        exit 1
        ;;
esac
