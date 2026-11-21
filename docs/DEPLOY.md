> **VoIPCentra Premium v1.0:** This document contains legacy starter instructions. For current installation instructions, see [INSTALL-PREMIUM.md](INSTALL-PREMIUM.md). Do not use the retired theme installer to deploy Premium v1.0.

# Safe deployment and validation

1. Back up relevant VICIdial configuration, and work on **staging** first.
2. Confirm that existing original ViciPhone works, including SIP registration and calls.
3. Fork upstream at https://github.com/vicimikec/ViciPhone (retain AGPL license and notices).
4. On staging, clone your fork under `/srv/www/htdocs/agc/VoIPCentra-WebPhone` (or preferred directory).
5. Copy this starter's `theme/` and `scripts/` into your fork, then run:
   `bash scripts/install-theme.sh /srv/www/htdocs/agc/VoIPCentra-WebPhone`
6. In VICIdial Admin > Phones > Webphone Layout, select `voipcentra.css` for a test phone. If your install uses a different setting mechanism, consult your exact release/template; don't force-edit core code blindly.
7. Confirm that CSS asset returns HTTP 200 over HTTPS in the browser. If Webphone Layout expects a URL, supply the correct HTTPS CSS URL.
8. Logo is included but needs specific version-dependent integration. Do not assume copying the SVG replaces the built-in logo.
9. Verify browser console / network, mic permissions, registration, inbound/outbound, hold/mute (as supported), DTMF, transfer/conference (if supported), and disconnect/reconnect.
10. Roll back by restoring prior Webphone Layout value; unmodified SIP/PHP core remains intact.

Security: avoid `chmod -R 777`, don't grant root access to the phone process, restrict directory ownership, and use valid TLS/WSS. Check ViciPhone 3.0 requirements (`rtcp_mux=yes`) against your Asterisk version and template.

## AI / codec readiness (v0.2)

Run `bash scripts/check-media-readiness.sh` on the *Asterisk host* to inspect codecs, version, and media modules without changing any files. See `docs/AI-CODEC-READINESS.md` for the deployment checklist and important limits. The site `https://voipcentra.net` is included in the theme footer and UI concept.
