# VoIPCentra v3.0 - Development Deployment Notice

**Universal Installer v2.9 DEV - NOT PRODUCTION READY.**

Premium, Original and Both modes passed isolated ViciBox 12
installation, locking, failure and recovery tests.

Production installation remains disabled.

Existing instructions below include legacy staging guidance.
Do not use retired theme installers or deploy this development
branch directly over an existing production WebPhone.

All installation modes require VOIPCENTRA_TEST_MODE=1
and an isolated /tmp/voipcentra-dual-* directory.

Real SIP/WebRTC calls, codecs, browser interoperability
and other ViciBox versions remain unverified.

---

> **VoIPCentra Universal Installer v2.9 DEV:** Premium, Original ViciPhone 3.0, and dual installation have passed isolated ViciBox 12 tests. Original and dual installation modes remain test-only. Manual recovery is test-only, production integration requires separate verification, and compatibility with other ViciBox versions is not yet established. Do not use these development installation workflows against a production VICIdial system.

> **VoIPCentra Premium v1.0:** This document contains legacy starter instructions. For current installation instructions, see [INSTALL-PREMIUM.md](INSTALL-PREMIUM.md). Do not use the retired theme installer to deploy Premium v1.0.

# Safe deployment and validation

## Legacy deployment instructions — NOT FOR CURRENT INSTALLER

**WARNING:** The following steps describe a retired theme-first workflow. Do not run them against production or use them as installation instructions for Universal Installer v2.9 DEV.



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
