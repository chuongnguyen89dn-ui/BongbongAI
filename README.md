# BongbongAI — independent CarPlay AI bubble

**SOURCE PROTOTYPE ONLY. NO VERIFIED DEB OR CARPLAY DEVICE PASS.**

- Bundle/package: \`com.chuong.bongbongai\`, iOS 16+ arm64 rootless, Theos.
- No dependency on DuoCar/Omnicar; injection filter: \`com.apple.CarPlayApp\` only.
- Purple floating CarPlay bubble + simple text input and fixed-sentence diagnostic.
- BYOK: user enters their own Gemini API key on iPhone. **No Cloudflare Worker or hardcoded API key.**
- **v0.1.1 key-entry fix:** Copy API key on the iPhone, open BongbongAI Config (screen title must say v0.1.1). First try system Paste / Dán. If it is unavailable, tap **Dán API key (cách 2)** and, if iOS requests paste permission, allow it. Tap **Lưu API key**. Status only reports character count, never key content. Saving now confirms a local CFPreferences read-back, not a cross-process CarPlay read.
- Gemini returns complete text; Gemini 3.8 Flash TTS generates audio; queue full audio for one WAV/AVAudioPlayer playback, never play incomplete turns.
- \`Đọc thử\` plays one built-in Apple TTS sentence to diagnose the CarPlay audio route without an API call. Text/fixed prompt only in v0.1, **no voice input yet**.

### Evidence (not device validation)

\`\`\`sh
chmod +x tests/run_host.sh
./tests/run_host.sh
make package FINALPACKAGE=1
python3 tests/check_deb.py packages/*.deb
\`\`\`

Local host checks: 23 portable PCM/WAV assertions and 21 static source isolation checks. This environment has **no Theos**, so native package compilation is blocked locally. A macOS GitHub Actions workflow will attempt a real build and upload an UNTESTED artifact only if its checks succeed.

**Security blocker:** Config currently uses CFPreferences for the user's test API key; not secure Keychain storage and cross-process readability not validated. Do not put a valuable production key into a test build. A Keychain + authenticated IPC broker is needed for release.

See [build evidence](docs/BUILD_EVIDENCE.md), [device gate](docs/DEVICE_GATE.md), [implementation limitations](docs/IMPLEMENTATION_NOTES.md). Use only while the car is parked.
