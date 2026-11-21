# Build evidence — BongbongAI 0.1.0

## Confirmed on 2026-11-21

- Source HEAD at first compiled DEB: `b8829a4b2479db4dabbee8d8ca36db9e82b5e44d` (source functionally same as `69829099`; workflow diagnostic only).
- GitHub Actions run 44894887652: host-source-checks PASS, genuine Theos/Xcode compile/link/sign/package PASS.
- `dpkg-deb --contents` confirms prefix `var/jb/`, `BongbongAI.dylib`, injection filter `BongbongAI.plist` and `BongbongAIConfig.app`. The old check failed **only because it expected `./var/jb/` whereas macOS dpkg-deb printed `var/jb/`**. Do not interpret as invalid rootless package.
- Independently downloaded and extracted compiled DEB in our working container. Both binaries are genuine Mach-O universal arm64/arm64e. Filter plist: CarPlayApp only.
- DEB SHA-256: `ec1d789ec8df4dc3ce451a9367410db32cb68941cd829f0ed126fe77ca2d82f5` (35,016 bytes).
- New regression checker normalizes paths, rejects any binary outside var/jb, checks package architecture and Mach-O slices.

## Not yet verified

**DEVICE PENDING:** actual CarPlay external UIWindowScene, bubble z-order/interaction, Config->CarPlayApp CFPreferences transport, microphone (not implemented), Gemini API behavior and full audible output. Do not call it product-ready. The companion preferences are not a secure Keychain or verified cross-process transport; only use a disposable limited test key.

## Replay build

`./tests/run_host.sh` then `make clean package FINALPACKAGE=1` then `python3 tests/check_deb.py packages/*.deb`.
GitHub Actions artifacts are marked **NOT DEVICE TESTED** and are not a production release.
