#!/usr/bin/env bash
set -euo pipefail

echo "===================================="
echo " VoIPCentra VICIdial Integration Check"
echo " READ-ONLY MODE"
echo "===================================="

command -v mysql >/dev/null || {
    echo "ERROR: MySQL client missing"
    exit 1
}

echo
echo "=== SYSTEM WEBPHONE URL ==="

mysql --batch --skip-column-names -e "
SELECT webphone_url
FROM asterisk.system_settings;
"

echo
echo "=== WEBPHONE ENABLED PHONES ==="

mysql --batch --skip-column-names -e "
SELECT COUNT(*)
FROM asterisk.phones
WHERE is_webphone = 'Y';
"

echo
echo "=== USER GROUP URL OVERRIDES ==="

mysql --batch --skip-column-names -e "
SELECT COUNT(*)
FROM asterisk.vicidial_user_groups
WHERE webphone_url_override IS NOT NULL
AND webphone_url_override <> '';
"

echo
echo "READ-ONLY CHECK COMPLETE"
echo "No VICIdial database changes performed."
