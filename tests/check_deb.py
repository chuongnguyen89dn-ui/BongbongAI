#!/usr/bin/env python3
"""Require real rootless package content, not a placeholder artifact."""
import re
import subprocess
import sys
from pathlib import Path
if len(sys.argv)!=2:sys.exit("Usage: python3 tests/check_deb.py <one .deb>")
pkg=Path(sys.argv[1])
if not pkg.is_file():sys.exit("no .deb produced")
control=subprocess.check_output(["dpkg-deb","-f",str(pkg)],text=True)
assert re.search(r"^Package: com\.chuong\.bongbongai$",control,re.M), control
assert re.search(r"^Architecture: iphoneos-arm64$",control,re.M), control
paths=subprocess.check_output(["dpkg-deb","--contents",str(pkg)],text=True)
assert "./var/jb/" in paths, "NOT ROOTLESS"
assert re.search(r"/Library/MobileSubstrate/DynamicLibraries/BongbongAI\.dylib\s*$",paths,re.M),paths
assert re.search(r"/Library/MobileSubstrate/DynamicLibraries/BongbongAI\.plist\s*$",paths,re.M),paths
assert re.search(r"/Applications/BongbongAIConfig\.app/BongbongAIConfig\s*$",paths,re.M),paths
print(f"PASS rootless package metadata/path gates: {pkg}")
print("Still NOT verified: code signing, CarPlay scene, API key transport and output route.")
