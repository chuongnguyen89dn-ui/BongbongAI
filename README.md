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

### v0.1.2 — no-clipboard key entry (device verification pending)
If Paste and Paste (cách 2) display controls but insert no text, the config app now offers **Nhập API key từ Tệp .txt**. Copy/transfer a UTF-8 file with **one key only** onto the **same iPhone where BongbongAI is installed**, using the Apple Files app or a local transfer method such as AirDrop. Then open BongbongAI, select the file, tap **Kiểm tra số ký tự đã nhập**, and tap **Lưu API key**. Delete the source text file afterwards. No key content is printed to logs or status messages. The picker imports a copy and cleans up its sandbox copy.
For diagnosis, copy test text using **Notes on the same iPhone**, not a different device, before concluding the app's pasteboard access is broken.
This is still unverified on the target device and does not prove that the CarPlay process can read saved preferences.

### v0.1.3 — diagnostic key field (device verification pending)
Apple iOS secureTextEntry disables copying and masks all displayed characters. The previous releases always used a secure field, so a missing Copy control after typing in the key field is expected OS behavior, not proof of a paste failure.
- Use the **Gõ thử chữ** non-secret diagnostic field to test keyboard and native Copy without exposing a key.
- The API key has a visible **character count**; use **Hiện API key (cho phép Copy)** to temporarily reveal/inspect the text and enable the Copy menu, then hide it immediately. Never share a screenshot with the key visible.
- **Mở bàn phím để nhập key** explicitly tests the key field's first-responder status.
- The original native Paste, user-tap clipboard fallback, and file import remain supported.
Build/source PASS is not device PASS; actual typing, paste and CarPlay cross-process access must be verified on target hardware.
