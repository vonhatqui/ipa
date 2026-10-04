import os

pbx_path = os.path.join("ThreeOneOSFive.xcodeproj", "project.pbxproj")
with open(pbx_path, "r", encoding="utf-8") as f:
    c = f.read()

target = '\t\t3105A150 /* AirliftPairingSectionView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirliftPairingSectionView.swift; sourceTree = "<group>"; };\n'
insert = target + '\t\t3105A151 /* DeltaStyleSettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DeltaStyleSettingsView.swift; sourceTree = "<group>"; };\n'

if 'DeltaStyleSettingsView.swift; sourceTree' not in c:
    c = c.replace(target, insert, 1)
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(c)
    print("Inserted PBXFileReference successfully!")
else:
    print("Already present!")
