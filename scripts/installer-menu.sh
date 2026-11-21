#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo
echo "========================================"
echo "      VoIPCentra Universal Installer"
echo "                v2.4 DEV"
echo "========================================"
echo
echo "1) Install VoIPCentra Premium"
echo "2) Install Original ViciPhone 3.0"
echo "3) Install Both WebPhones"
echo "4) Check Server Compatibility"
echo "5) Exit"
echo

read -r -p "Select option [1-5]: " OPTION

case "$OPTION" in
    1|2|3)
        if [[ "${VOIPCENTRA_TEST_MODE:-}" != "1" ]]; then
            echo "SAFETY STOP: Installation menu is test-only."
            exit 1
        fi

        case "$OPTION" in
            1) MODE="--install-voipcentra" ;;
            2) MODE="--install-original" ;;
            3) MODE="--install-both" ;;
        esac

        exec bash "$PROJECT_DIR/install.sh" "$MODE"
        ;;
    4)
        exec bash "$PROJECT_DIR/install.sh" --check-compatibility
        ;;
    5)
        echo "Installer exited. No changes made."
        ;;
    *)
        echo "Invalid option. Nothing installed."
        exit 1
        ;;
esac
