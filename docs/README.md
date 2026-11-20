# VoIPCentra WebPhone — starter v0.2

A **theme-first** custom VICIdial/ViciPhone project. This package includes **branding/theme assets, a preview, and an installer**; it does **not** contain the upstream ViciPhone code or a complete reimplemented dialer.

## Brand and AI-media roadmap

VoIPCentra WebPhone · https://voipcentra.net

This package adds a visible branding footer, a non-functional design preview, a read-only Asterisk media diagnostics script and an AI-media architecture/codec readiness guide. It does **not** implement an AI bot or guarantee codec interoperability on all deployments. See `docs/AI-CODEC-READINESS.md`.

## Why theme-first?

ViciPhone 3.0 supports selecting an alternate CSS layout in VICIdial phone settings. A custom CSS theme is safer than rewriting SIP.js, login/registration, or call handling before testing against a live VICIdial/Asterisk setup.

## Structure

- `theme/voipcentra.css` — responsive VoIPCentra style for documented ViciPhone DOM IDs/classes.
- `theme/voipcentra-logo.svg` — optional branding asset; does not automatically replace logo.
- `scripts/install-theme.sh` — checks target path and installs assets only.
- `preview/index.html` — **static visual concept** (not SIP-connected, not functional).
- `docs/DEPLOY.md` — deployment guide.
- `docs/AI-CODEC-READINESS.md` — codecs and AI integration design.
- `scripts/check-media-readiness.sh` — read-only Asterisk diagnostics.

## Quick installation on a test/staging VICIdial server

```bash
cd /srv/www/htdocs/agc
# Use your own fork when created; upstream URL below is example
 git clone https://github.com/vicimikec/ViciPhone.git
# Upload this VoIPCentra-WebPhone folder to the server first
bash /path/to/VoIPCentra-WebPhone/scripts/install-theme.sh /srv/www/htdocs/agc/ViciPhone
```

In VICIdial go to **Admin > Phones > relevant phone > Webphone Layout**, and set `voipcentra.css` (if your release supports that layout option). Keep the Webphone URL and SIP configuration unchanged. Test both inbound/outbound calling, DTMF, mic mute, speaker, registration, conference flow, and browser permissions.

**Important:** No live connection has been tested here. CSS selectors are based on ViciPhone's published customization guide; exact compatibility must be checked against your deployed revision. This package intentionally does not patch your live `viciphone.php`.

## Licensing / attribution

ViciPhone is AGPL-3.0. If you fork/modify/distribute its code, retain license/copyright notices and comply with the AGPL's source availability requirements. Read the upstream LICENSE before publishing your combined distribution: https://github.com/vicimikec/ViciPhone

## Next milestones

1. Test theme on an isolated server and inspect current HTML IDs.
2. Adapt selectors for exact release and replace logo by supported config/template method.
3. Fork ViciPhone to GitHub under your ownership; commit modifications and LICENSE.
4. QA across browsers and real SIP/WebRTC connections; then tag a release.
