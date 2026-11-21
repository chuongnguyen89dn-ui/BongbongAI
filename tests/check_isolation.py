#!/usr/bin/env python3
"""Source-only invariants. Does not substitute build, API or device verification."""
from pathlib import Path
import plistlib, re

root=Path(__file__).resolve().parents[1]
source="\n".join(p.read_text() for p in [*(root/"overlay").glob("*.m"),*(root/"overlay").glob("*.c"),*(root/"settings").glob("*.m")])
plist=plistlib.loads((root/"overlay"/"BongbongAI.plist").read_bytes())
control=(root/"control").read_text()
checks={
 "separate-package-id":"Package: com.chuong.bongbongai" in control,
 "carplay-only-injection":plist["Filter"]["Bundles"]==["com.apple.CarPlayApp"],
 "no-duocar-hooks":not re.search(r"DuoCar|OmniCar|DuoNavi|com\.chuong\.duocar",source,re.I),
 "direct-gemini":'https://generativelanguage.googleapis.com/v1beta/interactions' in source,
 "no-cloudflare":not re.search(r"workers\.dev|/v1/answer|/chat|/tts",source),
 "key-is-user-supplied":'x-goog-api-key' in source and 'geminiAPIKey' in source,
 "native-user-initiated-key-paste":'UIPasteControl' in source and 'pasteKey.target=self.keyInput' in source,
 "explicit-tap-fallback":'pasteFromClipboard:(id)sender' in source and 'action:@selector(pasteFromClipboard:)' in source,
 "clipboard-read-in-action-only":'[UIPasteboard generalPasteboard].string' in source and 'pasteFromClipboard:(id)sender' in source,
 "local-save-readback":'CFPreferencesCopyAppValue(CFSTR("geminiAPIKey")' in source,
 "package-version-bumped":'Version: 0.1.1' in control,
 "config-version-bumped":'<string>0.1.1</string>' in (root/"settings"/"Resources"/"Info.plist").read_text(),
 "no-hardcoded-secret":not re.search(r'AIza[\w-]{20,}',source),
 "api-revision":'Api-Revision' in source and '2026-05-20' in source,
 "active-tts-model":'gemini-3.8-flash-tts' in source and 'gemini-3.1-flash-tts-preview' not in source,
 "stateless-by-default":'@"store":@NO' in source,
 "wait-for-complete":'@"completed"' in source and '@"steps"' in source,
 "text-not-silently-trimmed":'complete.length>4200' in source,
 "split-not-drop":'BBSpeechSegments' in source and 'speechAt:idx+1' in source,
 "all-pcm-before-play":'BBWrapPCM(pcm)' in source and 'initWithData:wav' in source,
 "host-testable-wav-core":'bb_pcm_to_wav' in source,
 "one-block-per-segment":'audioCount!=1' in source,
 "no-live-streaming":'AVAudioPlayerNode' not in source,
 "external-screen-only":'windowScene.screen==phone' in source,
 "touch-passthrough":'pointInside:' in source and 'bubbleHit' in source,
 "not-playing-on-stop":'- (void)stop:' in source,
 "not-complete-by-default":"DEVICE PENDING" in (root/"docs"/"DEVICE_GATE.md").read_text(),
}
for label,ok in checks.items():print(f"{'PASS' if ok else 'FAIL'} {label}")
if not all(checks.values()):raise SystemExit(1)
print(f"PASS {len(checks)}/{len(checks)} static checks; this is NOT BUILD or DEVICE PASS")
