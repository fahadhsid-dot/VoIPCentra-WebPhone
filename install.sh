#!/usr/bin/env bash
set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBROOT="/srv/www/htdocs/agc"
TARGET="$WEBROOT/VoIPCentra-WebPhone"

# Explicitly supported isolated test directory only
if [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]]; then
    WEBROOT="${VOIPCENTRA_TEST_ROOT:-/tmp/voipcentra-dual-v2.2-test}"

    if [[ ! "$WEBROOT" =~ ^/tmp/voipcentra-dual-[A-Za-z0-9._-]+$ ||
          -L "$WEBROOT" ]]; then
        echo "SAFETY STOP: Invalid isolated test directory."
        exit 1
    fi

    TARGET="$WEBROOT/VoIPCentra-WebPhone"
fi
BACKUP_DIR="/root/VoIPCentra-Backups"
MODE="${1:---check}"

# Acquire a secure shared lock before entering installation modes.
# Child installers inherit the verified FD 9.
if [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" &&
      "${VOIPCENTRA_LOCK_INHERITED:-}" != "1" ]]; then
    case "$MODE" in
        --install|--install-voipcentra|--install-original|--install-both)
            exec python3 "$SOURCE/scripts/secure-deployment-lock.py" \
                "$WEBROOT" bash "$SOURCE/install.sh" "$@"
            ;;
    esac
fi

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
        [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" ]] || {
            echo "SAFETY STOP: Development installation is test-only."
            exit 1
        }

        PUBLISH_HELPER="$SOURCE/scripts/atomic-publish.py"
        PERMISSIONS_HELPER="$SOURCE/scripts/prepare-web-permissions.sh"
        source "$SOURCE/scripts/deployment-lock.sh"
        voipcentra_acquire_lock "$WEBROOT" || exit 1

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

        # Transaction markers are permitted only in isolated test mode.
        if [[ -n "${VOIPCENTRA_TRANSACTION_ID:-}" ]]; then
            [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" &&
               "$VOIPCENTRA_TRANSACTION_ID" =~ ^[0-9a-f]{32}$ ]] || {
                echo "SAFETY STOP: Invalid deployment transaction."
                exit 1
            }

            printf '%s\n' "$VOIPCENTRA_TRANSACTION_ID" > "$STAGING/.voipcentra-transaction-id"

            echo "PASS: Premium transaction marker prepared."
        fi

        bash "$PERMISSIONS_HELPER" "$STAGING"
        python3 "$PUBLISH_HELPER" "$STAGING" "$TARGET"
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

        # Shared lock inherited by both child installers.
        source "$SOURCE/scripts/deployment-lock.sh"
        voipcentra_acquire_lock "$WEBROOT" || exit 1

        PREMIUM_TARGET="$WEBROOT/VoIPCentra-WebPhone"
        ORIGINAL_TARGET="$WEBROOT/ViciPhone"

        if [[ -e "$PREMIUM_TARGET" || -L "$PREMIUM_TARGET" ]]; then
            echo "SAFETY STOP: Premium installation already exists."
            exit 1
        fi

        if [[ -e "$ORIGINAL_TARGET" || -L "$ORIGINAL_TARGET" ]]; then
            echo "SAFETY STOP: Original installation already exists."
            exit 1
        fi

        # Verify or fetch Original ViciPhone before deploying either phone.
        # The path must match scripts/install-original-viciphone.sh.
        ORIGINAL_SOURCE="/tmp/ViciPhone-Original-v2.2-Fresh"

        if ! bash "$SOURCE/scripts/fetch-original-viciphone.sh" "$ORIGINAL_SOURCE"; then
            echo "SAFETY STOP: Original ViciPhone source verification failed."
            echo "No WebPhone deployment started."
            exit 1
        fi

        # Unique identifier for this isolated dual-install transaction.
        VOIPCENTRA_TRANSACTION_ID="$(python3 -c 'import uuid; print(uuid.uuid4().hex)')"
        export VOIPCENTRA_TRANSACTION_ID

        JOURNAL_HELPER="$SOURCE/scripts/transaction-journal.py"

        journal_state() {
            VOIPCENTRA_TEST_MODE=1 python3 "$JOURNAL_HELPER"                 "$WEBROOT" "$VOIPCENTRA_TRANSACTION_ID" "$1"
        }

        echo "TRANSACTION ID: $VOIPCENTRA_TRANSACTION_ID"
        journal_state STARTED || exit 1
        echo "PREFLIGHT PASS: Both destinations available."
        echo "Installing VoIPCentra Premium..."
        if ! bash "$SOURCE/install.sh" --install; then
            journal_state FAILED || true
            echo "DUAL INSTALL FAILED: Premium deployment."
            exit 1
        fi

        journal_state PREMIUM_INSTALLED || exit 1

        # Test-only simulated failure after Premium deployment.
        # Never permitted outside isolated test mode.
        if [[ "${VOIPCENTRA_TEST_MODE:-}" == "1" &&
              "${VOIPCENTRA_TEST_FAIL_ORIGINAL:-}" == "1" ]]; then
            echo "SIMULATED FAILURE: Original deployment deliberately stopped."
            journal_state FAILED || true
            echo "PARTIAL INSTALLATION: Premium may already be deployed."
            exit 77
        fi

        echo "Installing Original ViciPhone 3.0..."
        if ! bash "$SOURCE/scripts/install-original-viciphone.sh"; then
            journal_state FAILED || true
            echo "DUAL INSTALL FAILED: Original deployment."
            exit 1
        fi

        journal_state ORIGINAL_INSTALLED || exit 1
        journal_state COMPLETE || exit 1

        echo "DUAL INSTALLATION COMPLETE"
        ;;

    --menu)
        bash "$SOURCE/scripts/installer-menu.sh"
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
        echo "Usage: bash install.sh [--check|--dry-run|--backup|--install|--install-voipcentra|--install-original|--install-both|--check-vicidial|--check-compatibility|--menu]"
        echo "NOTE: Original and dual installation modes are test-only."
        exit 1
        ;;
esac
