"""Configure the generated iOS host without changing application sources."""
from pathlib import Path
import plistlib
import re
import subprocess

info = Path("ios/Runner/Info.plist")
with info.open("rb") as f:
    data = plistlib.load(f)
data.update({
    "CFBundleDisplayName": "Fasobiblio",
    "NSMicrophoneUsageDescription": "Enregistrer votre question pour discuter avec l'assistant Fasobiblio.",
    "NSPhotoLibraryUsageDescription": "Choisir votre photo de profil Fasobiblio.",
    "NSCameraUsageDescription": "Prendre votre photo de profil Fasobiblio.",
})
with info.open("wb") as f:
    plistlib.dump(data, f)

project = Path("ios/Runner.xcodeproj/project.pbxproj")
text = project.read_text().replace("com.fasobiblio.fasobiblio", "com.fasobiblio.app")
text = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", "IPHONEOS_DEPLOYMENT_TARGET = 15.0;", text)
project.write_text(text)
framework = Path("ios/Flutter/AppFrameworkInfo.plist")
with framework.open("rb") as f:
    data = plistlib.load(f)
data["MinimumOSVersion"] = "15.0"
with framework.open("wb") as f:
    plistlib.dump(data, f)
podfile = Path("ios/Podfile")
if podfile.exists():
    text = re.sub(r"#?\s*platform :ios, '[^']+'", "platform :ios, '15.0'", podfile.read_text())
    podfile.write_text(text)

# Use the existing app icon for every generated iOS icon size.
import json
icons = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
for entry in json.loads((icons / "Contents.json").read_text())["images"]:
    if not entry.get("filename"):
        continue
    pixels = round(float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x")))
    subprocess.run(["sips", "-z", str(pixels), str(pixels),
                    "assets/branding/icon.png", "--out", str(icons / entry["filename"])],
                   check=True, stdout=subprocess.DEVNULL)
