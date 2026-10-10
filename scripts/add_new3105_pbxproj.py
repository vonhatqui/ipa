#!/usr/bin/env python3
import os

pbx_path = os.path.join("ThreeOneOSFive.xcodeproj", "project.pbxproj")
with open(pbx_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if already added
if "LocalConfigManager.swift" in content:
    print("Files already added to project.pbxproj!")
    exit(0)

# 1. PBXBuildFile entries
build_files = """\
\t\t3105N201 /* LocalConfigManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N101; };
\t\t3105N202 /* DeviceProfileService.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N102; };
\t\t3105N203 /* New3105InjectorButton.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N103; };
\t\t3105N204 /* New3105AimTabView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N104; };
\t\t3105N205 /* New3105EspTabView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N105; };
\t\t3105N206 /* New3105MiscTabView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N106; };
\t\t3105N207 /* New3105MeTabView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N107; };
\t\t3105N208 /* New3105MainView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105N108; };
"""

# Insert into PBXBuildFile section before End PBXBuildFile
content = content.replace("/* End PBXBuildFile section */", build_files + "/* End PBXBuildFile section */")

# 2. PBXFileReference entries
file_refs = """\
\t\t3105N101 /* LocalConfigManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LocalConfigManager.swift; sourceTree = "<group>"; };
\t\t3105N102 /* DeviceProfileService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DeviceProfileService.swift; sourceTree = "<group>"; };
\t\t3105N103 /* New3105InjectorButton.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105InjectorButton.swift"; sourceTree = "<group>"; };
\t\t3105N104 /* New3105AimTabView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105AimTabView.swift"; sourceTree = "<group>"; };
\t\t3105N105 /* New3105EspTabView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105EspTabView.swift"; sourceTree = "<group>"; };
\t\t3105N106 /* New3105MiscTabView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105MiscTabView.swift"; sourceTree = "<group>"; };
\t\t3105N107 /* New3105MeTabView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105MeTabView.swift"; sourceTree = "<group>"; };
\t\t3105N108 /* New3105MainView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "New3105/New3105MainView.swift"; sourceTree = "<group>"; };
"""

# Insert into PBXFileReference section before End PBXFileReference
content = content.replace("/* End PBXFileReference section */", file_refs + "/* End PBXFileReference section */")

# 3. Add to views group
views_needle = '3105M134 /* EspAimSilentDetailDashboardView.swift */,\n'
views_insert = views_needle + """\t\t\t\t3105N103 /* New3105InjectorButton.swift */,
\t\t\t\t3105N104 /* New3105AimTabView.swift */,
\t\t\t\t3105N105 /* New3105EspTabView.swift */,
\t\t\t\t3105N106 /* New3105MiscTabView.swift */,
\t\t\t\t3105N107 /* New3105MeTabView.swift */,
\t\t\t\t3105N108 /* New3105MainView.swift */,
"""
content = content.replace(views_needle, views_insert)

# 4. Add to helpers group
helpers_needle = '3105M135 /* ZrxFeaturesConfigStore.swift */,\n'
helpers_insert = helpers_needle + """\t\t\t\t3105N101 /* LocalConfigManager.swift */,
\t\t\t\t3105N102 /* DeviceProfileService.swift */,
"""
content = content.replace(helpers_needle, helpers_insert)

# 5. Add to PBXSourcesBuildPhase
sources_needle = '3105A700 /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n'
sources_insert = sources_needle + """\t\t\t\t3105N201 /* LocalConfigManager.swift in Sources */,
\t\t\t\t3105N202 /* DeviceProfileService.swift in Sources */,
\t\t\t\t3105N203 /* New3105InjectorButton.swift in Sources */,
\t\t\t\t3105N204 /* New3105AimTabView.swift in Sources */,
\t\t\t\t3105N205 /* New3105EspTabView.swift in Sources */,
\t\t\t\t3105N206 /* New3105MiscTabView.swift in Sources */,
\t\t\t\t3105N207 /* New3105MeTabView.swift in Sources */,
\t\t\t\t3105N208 /* New3105MainView.swift in Sources */,
"""
content = content.replace(sources_needle, sources_insert)

with open(pbx_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Successfully registered 3105-New Swift files in ThreeOneOSFive.xcodeproj/project.pbxproj!")
