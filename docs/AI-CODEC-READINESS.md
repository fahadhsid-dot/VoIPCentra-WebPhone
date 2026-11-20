# VoIPCentra WebPhone — AI / Codec Readiness (v0.2)

Website: https://voipcentra.net

## Scope and truth in advertising

This repository ships a UI/theme overlay and read-only diagnostics; it does NOT ship an AI bot, Asterisk configuration modifications, or a SIP media stack. Do not promise zero codec problems across arbitrary customer environments.

## Media pipeline for a future AI agent

Browser WebRTC ViciPhone (unchanged SIP.js) <-> Asterisk/VICIdial <-> External Media bridge (ARI / supported AudioSocket or WebSocket) <-> VAD / STT / LLM / TTS service.

Do not connect browser audio directly to an AI service with exposed API keys. Run the AI bridge in a server-side isolated service, with authentication and appropriate recording consent.

## Codec compatibility profiles

* Opus: prefer for browser-to-Asterisk WebRTC where `codec_opus` and negotiation are available.
* G.711 μ-law (`ulaw` / PCMU) and A-law (`alaw` / PCMA): reliable fallbacks, subject to the provider/endpoint codec list.
* For AI media, use a *defined* linear PCM target (for example `slin16` where supported) and transcode in Asterisk / the bridge as required. An AI model's PCM format is not a WebRTC SIP codec.
* Do not blindly inject codec configuration into a running VICIdial template. Actual negotiation depends on the installed chan_sip/chan_pjsip, codec modules, carrier, and browser.
* Avoid forced Opus-only policies for endpoints without the requisite transcoder or Opus module.

## Verify on staging

1. Note Asterisk and VICIdial versions; review SIP stack (`chan_sip` vs `chan_pjsip`).
2. Run `bash scripts/check-media-readiness.sh` on the *Asterisk host*; it makes no edits.
3. Confirm HTTPS/WSS and DTLS-SRTP, browser microphone permissions, ICE, and TURN for remote agents.
4. Confirm `rtcp_mux=yes` in the correct WebRTC phone template as required by ViciPhone 3.0.
5. Test registrations, inbound/outbound calls, two-way audio, DTMF, reconnect, mute, transfer/conference, NAT traversal.
6. Negotiate Opus where available; repeat with a G.711-only carrier and verify server-side transcoding.
7. Prototype ARI media bridging *separately*, measure AI roundtrip time and packet loss/jitter, test simultaneous calls and cancellation/barge-in.
8. Ensure your Asterisk build supports the media transport you choose. Newer WebSocket external-media is not automatically available on older Asterisk builds.
9. Implement rate limits, access control, tenant separation, data retention and consent before client rollouts.

## Useful references

- ViciPhone v3 upstream: https://github.com/vicimikec/ViciPhone
- WebRTC setup: https://docs.asterisk.org/Configuration/WebRTC/Configuring-Asterisk-for-WebRTC-Clients/
- External media: https://docs.asterisk.org/Development/Reference-Information/Asterisk-Framework-and-API-Examples/External-Media-and-ARI/
- Asterisk WebSocket media (version-specific): https://docs.asterisk.org/Configuration/Channel-Drivers/WebSocket/
