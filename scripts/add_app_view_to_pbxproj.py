with open('ThreeOneOSFive.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
    c = f.read()

# 1. PBXBuildFile section
build_file_entry = '\t\tCSAV0300B /* CheatStoreAppView.swift in Sources */ = {isa = PBXBuildFile; fileRef = CSAV0300F /* CheatStoreAppView.swift */; };\n'
idx_bf = c.find('/* Begin PBXBuildFile section */')
assert idx_bf != -1
c = c[:idx_bf + len('/* Begin PBXBuildFile section */\n')] + build_file_entry + c[idx_bf + len('/* Begin PBXBuildFile section */\n'):]

# 2. PBXFileReference section
file_ref_entry = '\t\tCSAV0300F /* CheatStoreAppView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CheatStoreAppView.swift; sourceTree = "<group>"; };\n'
idx_fr = c.find('/* Begin PBXFileReference section */')
assert idx_fr != -1
c = c[:idx_fr + len('/* Begin PBXFileReference section */\n')] + file_ref_entry + c[idx_fr + len('/* Begin PBXFileReference section */\n'):]

# 3. Add to views group (next to CheatStoreLoginView.swift)
idx_group = c.find('3105M102 /* CheatStoreLoginView.swift */,')
assert idx_group != -1
c = c[:idx_group] + 'CSAV0300F /* CheatStoreAppView.swift */,\n\t\t\t\t' + c[idx_group:]

# 4. Add to PBXSourcesBuildPhase
idx_sources = c.find('3105M202,')
assert idx_sources != -1
c = c[:idx_sources] + 'CSAV0300B /* CheatStoreAppView.swift in Sources */,\n\t\t\t\t' + c[idx_sources:]

with open('ThreeOneOSFive.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
    f.write(c)

print('Added CheatStoreAppView.swift to project.pbxproj successfully!')
