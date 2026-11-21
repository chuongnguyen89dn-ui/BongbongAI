#!/usr/bin/env python3
"""Static-only source checks; never replace Theos build/device tests."""
from pathlib import Path
import plistlib,re
root=Path(__file__).resolve().parents[1]
overlay="\n".join(p.read_text() for p in (root/"overlay").glob("*.m"))
settings="\n".join(p.read_text() for p in (root/"settings").glob("*.m"))
src=overlay+settings
filter_=plistlib.loads((root/"overlay"/"BongbongAI.plist").read_bytes())
control=(root/"control").read_text()
checks={
 "package-id":"Package: com.chuong.bongbongai" in control,
 "carplay-only-filter":filter_["Filter"]["Bundles"]==["com.apple.CarPlayApp"],
 "no-duocar-dependencies":not re.search(r"(DuoCar|OmniCar|DuoNavi|com\.chuong\.duocar)",src),
 "no-cloudflare-worker":"workers.dev" not in src and "/v1/answer" not in src,
 "direct-gemini-endpoint":"https://generativelanguage.googleapis.com/v1beta/interactions" in src,
 "byok-header":"x-goog-api-key" in src and "geminiAPIKey" in src,
 "stateless-no-history":'@"store":@NO' in src,
 "complete-gate":'@"completed"' in src and '@"steps"' in src,
 "no-silent-cut":"trimmed.length>500" in src,
 "single-tts-block":"blocks!=1" in src,
 "full-wav":"WAVEfmt" in src and "initWithData:wav" in src,
 "no-live-streaming":"AVAudioPlayerNode" not in src,
 "no-phone-bubble":"if (!windowScene.screen || windowScene.screen==phone) continue" in src,
 "passthrough":"pointInside:" in src and "bubbleHit" in src,
 "user-triggered":"- (void)ask:(id)sender" in src,
 "no-embedded-key":not re.search(r"AIza[\w-]{20,}",src),
 "device-pending":"DEVICE PENDING" in (root/"docs"/"DEVICE_GATE.md").read_text(),
}
for name,ok in checks.items():print(("PASS " if ok else "FAIL ")+name)
if not all(checks.values()):raise SystemExit(1)
print(f"{len(checks)} static-only checks PASS; BUILD/DEVICE NOT TESTED")
