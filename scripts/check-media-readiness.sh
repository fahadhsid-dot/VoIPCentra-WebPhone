#!/usr/bin/env bash
# Read-only Asterisk/VICIdial media readiness checks. No secrets, changes or restarts.
set -uo pipefail
say() { printf '\n== %s ==\n' "$1"; }
if ! command -v asterisk >/dev/null 2>&1; then
  echo 'Asterisk command not found. Run this check on the PBX host; no changes made.'
  exit 2
fi
say 'Asterisk version'
asterisk -rx 'core show version' 2>&1 || true
say 'Codec modules (look for opus, ulaw, alaw, res_format_attr_opus)'
asterisk -rx 'module show like opus' 2>&1 || true
asterisk -rx 'module show like codec_ulaw' 2>&1 || true
asterisk -rx 'module show like codec_alaw' 2>&1 || true
say 'Core supported codecs'
asterisk -rx 'core show codecs audio' 2>&1 | grep -Ei '^( *[0-9]+ +)?(opus|ulaw|alaw|slin|g722)|codec|format|name' | head -45 || true
say 'WebRTC / media transport modules'
asterisk -rx 'module show like res_http_websocket' 2>&1 || true
asterisk -rx 'module show like res_ari' 2>&1 || true
asterisk -rx 'module show like chan_websocket' 2>&1 || true
say 'WebRTC transport status (review before publishing)'
asterisk -rx 'http show status' 2>&1 | sed -E 's#(https?://)[^ /]+#\1[host-redacted]#g' | head -30 || true
printf '\nRead-only checks finished. No changes were made. Do not share public outputs containing endpoints or credentials.\n'
