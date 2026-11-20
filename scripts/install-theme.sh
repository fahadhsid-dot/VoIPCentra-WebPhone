#!/usr/bin/env bash
set -euo pipefail
# Run on the VICIdial web server after cloning the original/forked ViciPhone.
TARGET="${1:-/srv/www/htdocs/agc/ViciPhone}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ ! -f "$TARGET/src/viciphone.php" ]]; then
  echo "ERROR: ViciPhone entry point not found at $TARGET/src/viciphone.php" >&2
  echo "Clone the upstream/fork first, then provide its directory to this script." >&2
  exit 1
fi
install -d -m 755 "$TARGET/src/css" "$TARGET/src/images"
install -m 644 "$ROOT/theme/voipcentra.css" "$TARGET/src/css/voipcentra.css"
install -m 644 "$ROOT/theme/voipcentra-logo.svg" "$TARGET/src/images/voipcentra-logo.svg"
echo "Installed VoIPCentra theme to $TARGET/src/css/voipcentra.css"
echo "Next: VICIdial Admin > Phones > Webphone Layout: voipcentra.css"
echo "Optional logo: configure existing logo image reference after checking your specific ViciPhone version."
echo "No SIP or PHP files were altered; no root-owned web files are required."
