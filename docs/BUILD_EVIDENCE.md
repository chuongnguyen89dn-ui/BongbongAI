# BongbongAI source / build evidence

As of 2026-11-21:
- Parent source commit: \`881a6793f671ed884e552ba71c2a2ef13103d8e7\`
- Local Linux/clang portable WAV suite: **23/23 PASS**; static isolated-source checks: **21/21 PASS**
- Local \`make package\`: **BLOCKED** — no Theos installed; actual error \`/makefiles/common.mk: No such file or directory\`
- GitHub Actions macOS+Theos workflow created for real rootless compile. A workflow existing in source does **not** mean CI passed.
- Compiled DEB: **NOT VERIFIED**. CarPlay scene/audio route and Gemini API: **NOT VERIFIED ON DEVICE**.

Critical findings:
- Gemini TTS 3.1 preview shut down on 2026-11-17; use 3.8 Flash TTS.
- 3.8 non-streaming TTS returns WAV by default. Require \`response_format.mime_type=audio/l16\`, sample_rate=24000, and parse \`output_audio.data\`; do not treat WAV bytes as raw PCM.
- \`status=completed\` is not an acoustic transcript guarantee: only car-speaker verification of last words can close the device gate.

See https://ai.google.dev/gemini-api/docs/speech-generation and https://theos.dev/docs/rootless

Current credential transport is CFPreferences: *not Keychain*, may not cross Config/CarPlay sandbox, and is **NOT RELEASE-READY**.
