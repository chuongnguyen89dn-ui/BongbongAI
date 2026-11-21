#!/usr/bin/env python3
"""Check the actual install paths and executable architecture of a compiled rootless DEB."""
import plistlib
import re
import subprocess
import sys
import tempfile
from pathlib import Path

if len(sys.argv) != 2:
    sys.exit("Usage: python3 tests/check_deb.py <package.deb>")
pkg = Path(sys.argv[1])
if not pkg.is_file():
    sys.exit("No .deb produced")

control = subprocess.check_output(["dpkg-deb", "-f", str(pkg)], text=True)
assert re.search(r"^Package: com\.chuong\.bongbongai$", control, re.M), control
assert re.search(r"^Architecture: iphoneos-arm64$", control, re.M), control

listing = subprocess.check_output(["dpkg-deb", "--contents", str(pkg)], text=True)
entries = []
for line in listing.splitlines():
    raw = line.rsplit(maxsplit=1)[-1]
    name = raw[2:] if raw.startswith("./") else raw
    entries.append(name)

# dpkg-deb on macOS omits the "./" prefix in output. Normalize, NEVER weaken rootless requirement.
files = {name for name in entries if not name.endswith("/")}
assert files, "No files in package"
for name in files:
    assert name.startswith("var/jb/"), "Path outside rootless prefix: " + name

tweak = "var/jb/Library/MobileSubstrate/DynamicLibraries/BongbongAI.dylib"
filter_plist = "var/jb/Library/MobileSubstrate/DynamicLibraries/BongbongAI.plist"
config_app = "var/jb/Applications/BongbongAIConfig.app/BongbongAIConfig"
config_plist = "var/jb/Applications/BongbongAIConfig.app/Info.plist"
assert {tweak, filter_plist, config_app, config_plist}.issubset(files), (
    "Expected signed binary, CarPlay filter, Config app and Info.plist missing: " + str(files)
)

with tempfile.TemporaryDirectory() as directory:
    subprocess.check_call(["dpkg-deb", "-x", str(pkg), directory])
    extracted = Path(directory)
    filt = plistlib.loads((extracted / filter_plist).read_bytes())
    assert filt == {"Filter": {"Bundles": ["com.apple.CarPlayApp"]}}, filt
    for binary_name in (tweak, config_app):
        binary = extracted / binary_name
        assert binary.stat().st_size > 4096, "Missing real Mach-O: " + binary_name
        archs = set(subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split())
        assert {"arm64", "arm64e"}.issubset(archs), (binary_name, archs)

print("PASS rootless prefix + package ID + arm64/arm64e Mach-O + CarPlay-only filter")
print("SOURCE/BUILD PASS only; no API key sharing, CarPlay scene, or audio route device PASS")
