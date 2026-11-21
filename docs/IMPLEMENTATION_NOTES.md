# Design constraints and open blockers

BongbongAI is a *separate* package with CarPlayApp-only injection filter; no changes to DuoCar, no Cloudflare Worker.
Text response is retrieved from the Gemini Interactions API. A TTS request is sent for each bounded text segment. Every segment must succeed before joining raw 24kHz/16-bit/mono PCM into one valid WAV and playing. Do not silently cut sentences.

API model 2026-11-21: Gemini 3.5 Flash Lite (text), Gemini 3.8 Flash TTS (speech). Non-streaming 3.8 defaults to audio/wav; explicitly request audio/l16, 24000 Hz.

Known unresolved: iPhone config and CarPlay processes may not share CFPreferences due to sandboxing; no proper Keychain/IPC broker yet. UIWindowScene external-screen assumption and overlay z-order vs hosted layers are unverified. Microphone/STT has not been built. Real audio completion must be confirmed on vehicle.

See docs/DEVICE_GATE.md for per-profile test matrix.
