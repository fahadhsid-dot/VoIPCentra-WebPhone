# VoIPCentra WebPhone Premium v1.0

Website: https://voipcentra.net

Based on ViciPhone v3.0.

## Installation

Clone the v3.0 GitHub branch into the VICIdial agc directory.
Premium CSS, logo and PHP template are already included.

## Installer commands

bash install.sh --check
bash install.sh --dry-run
bash install.sh --backup
bash install.sh --install

Existing installations are never overwritten.
VICIdial database, SIP, WebRTC and AI bot configuration are separate.

## License

Retain upstream ViciPhone AGPL license and copyright notices.

## VICIdial integration check

Run this read-only command to inspect the current WebPhone URL, enabled phone count and user-group URL overrides:

    bash install.sh --check-vicidial

This check does not modify the VICIdial database or SIP/WebRTC settings.

## Universal compatibility check v2.0

Run: bash install.sh --check-compatibility

Reports ViciBox release, PHP, Asterisk, SIP modules and active channel technologies. Detection does not certify versions 9-13 or modify server configuration.
