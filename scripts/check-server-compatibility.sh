#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " VoIPCentra Universal Compatibility Check"
echo " READ-ONLY - v2.0 Development"
echo "========================================"

echo
echo "=== OPERATING SYSTEM ==="
if [[ -r /etc/os-release ]]; then
    grep -E '^(NAME|VERSION)=' /etc/os-release
else
    echo "UNKNOWN: OS information unavailable"
fi

echo
echo "=== VICIBOX PACKAGE DETECTION ==="
if command -v rpm >/dev/null 2>&1; then
    packages="$(rpm -qa | grep -Ei '^vicibox|^vicidial' || true)"
    if [[ -n "$packages" ]]; then
        printf '%s\n' "$packages"
    else
        echo "No matching RPM package found"
        echo "ViciBox release needs separate verification"
    fi
else
    echo "RPM unavailable"
fi

echo
echo "=== ASTERISK ==="
if command -v asterisk >/dev/null 2>&1; then
    asterisk -V
else
    echo "MISSING: Asterisk command"
fi

echo
echo "=== PHP ==="
if command -v php >/dev/null 2>&1; then
    php -r 'echo PHP_VERSION, PHP_EOL;'
    for module in curl mysqli openssl; do
        if php -m | grep -iq "^${module}$"; then
            echo "PASS: PHP module $module"
        else
            echo "CHECK: PHP module $module missing"
        fi
    done
else
    echo "MISSING: PHP command"
fi

echo
echo "=== DATABASE CLIENT ==="
if command -v mysql >/dev/null 2>&1; then
    mysql --version
else
    echo "MISSING: MySQL/MariaDB client"
fi

echo
echo "=== VICIDIAL WEB DIRECTORY ==="
if [[ -d /srv/www/htdocs/agc ]]; then
    echo "FOUND: /srv/www/htdocs/agc"
else
    echo "CHECK: Standard VICIdial web directory not found"
fi

echo
echo "=== VOIPCENTRA WEBPHONE ==="
if [[ -f /srv/www/htdocs/agc/VoIPCentra-WebPhone/src/viciphone.php ]]; then
    echo "FOUND: VoIPCentra WebPhone"
else
    echo "NOT INSTALLED at standard location"
fi

echo
echo "=== RESULT ==="
echo "Environment detection completed."
echo "Compatibility and live calling are NOT certified by this check."
echo "No files, database records, or services changed."

echo
echo "=== VICIBOX RELEASE IDENTIFICATION ==="

if [[ -r /etc/vicibox-version ]]; then
    VERSION_LINE="$(grep -m1 -E 'ViciBox v\.[0-9]+' /etc/vicibox-version || true)"
    VICIBOX_VERSION="$(printf '%s\n' "$VERSION_LINE" |
        sed -nE 's/.*ViciBox v\.([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"

    if [[ -n "$VICIBOX_VERSION" ]]; then
        echo "DETECTED: ViciBox $VICIBOX_VERSION"
    else
        echo "UNKNOWN: Unable to parse ViciBox release"
    fi
else
    echo "UNKNOWN: /etc/vicibox-version not available"
fi

echo
echo "=== SIP / WEBSOCKET MODULE CHECK ==="

if command -v asterisk >/dev/null 2>&1; then
    for module in chan_sip.so chan_pjsip.so res_http_websocket.so; do
        result="$(asterisk -rx "module show like $module" 2>/dev/null || true)"

        if printf '%s\n' "$result" |
           grep -F "$module" | grep -q 'Running'; then
            echo "PASS: $module running"
        else
            echo "CHECK: $module not confirmed running"
        fi
    done
else
    echo "CHECK: Asterisk CLI unavailable"
fi

echo
echo "VICIBOX DETECTION COMPLETE"
echo "No live settings modified."

echo
echo "=== ACTIVE SIP CHANNEL TECHNOLOGIES ==="

if command -v asterisk >/dev/null 2>&1; then
    channels="$(asterisk -rx 'core show channels concise' 2>/dev/null || true)"

    if [[ -n "$channels" ]]; then
        printf '%s\n' "$channels" |
            awk -F'!' 'NF>5 {split($1,a,"/"); print a[1]}' |
            sort | uniq -c
    else
        echo "No active channel data available"
    fi

    echo
    echo "Channel detection is informational only."
    echo "Existing chan_sip/PJSIP configuration will be preserved."
else
    echo "Asterisk CLI unavailable"
fi

echo
echo "SIP CHANNEL AUDIT COMPLETE"

echo
echo "=== UNIVERSAL COMPATIBILITY STATUS ==="

case "${VICIBOX_VERSION:-UNKNOWN}" in
    12.*)
        echo "STATUS: VICIBOX 12 DETECTED"
        echo "Current environment validated on ViciBox 12.0.2."
        echo "Other 12.x builds require testing."
        ;;
    9.*|10.*|11.*|13.*)
        echo "STATUS: NOT YET VERIFIED"
        echo "Version detected; installation compatibility not certified."
        ;;
    *)
        echo "STATUS: UNKNOWN VERSION"
        echo "Manual compatibility review required."
        ;;
esac

echo "No SIP driver migration or configuration changes performed."
