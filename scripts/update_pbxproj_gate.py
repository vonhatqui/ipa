import os

pbx_path = os.path.join("ThreeOneOSFive.xcodeproj", "project.pbxproj")
with open(pbx_path, "r", encoding="utf-8") as f:
    c = f.read()

# 1. PBXBuildFile
target1 = "\t\t3105A251 /* DeltaStyleSettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105A151; };\n"
insert1 = target1 + "\t\t3105A252 /* AirliftPairingGateView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105A152; };\n"
if target1 in c and "3105A252" not in c:
    c = c.replace(target1, insert1, 1)

# 2. PBXFileReference
target2 = '\t\t3105A151 /* DeltaStyleSettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DeltaStyleSettingsView.swift; sourceTree = "<group>"; };\n'
insert2 = target2 + '\t\t3105A152 /* AirliftPairingGateView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirliftPairingGateView.swift; sourceTree = "<group>"; };\n'
if target2 in c and "path = AirliftPairingGateView.swift;" not in c:
    c = c.replace(target2, insert2, 1)

# 3. Group (views)
target3 = "\t\t\t\t3105A151 /* DeltaStyleSettingsView.swift */,\n"
insert3 = target3 + "\t\t\t\t3105A152 /* AirliftPairingGateView.swift */,\n"
if target3 in c and "3105A152 /* AirliftPairingGateView.swift */," not in c:
    c = c.replace(target3, insert3, 1)

# 4. PBXSourcesBuildPhase
target4 = "\t\t\t\t3105A251 /* DeltaStyleSettingsView.swift in Sources */,\n"
insert4 = target4 + "\t\t\t\t3105A252 /* AirliftPairingGateView.swift in Sources */,\n"
if target4 in c and "3105A252 /* AirliftPairingGateView.swift in Sources */," not in c:
    c = c.replace(target4, insert4, 1)

with open(pbx_path, "w", encoding="utf-8") as f:
    f.write(c)

print("Added AirliftPairingGateView.swift to project.pbxproj successfully!")
