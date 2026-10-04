import os

def add_file_to_pbx(pbx_path):
    if not os.path.exists(pbx_path):
        print("Path does not exist:", pbx_path)
        return
    with open(pbx_path, "r", encoding="utf-8") as f:
        c = f.read()

    # 1. PBXBuildFile
    target1 = "\t\t3105A252 /* AirliftPairingGateView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105A152; };\n"
    insert1 = target1 + "\t\t3105A253 /* SnapchatFluidLiquidBackgroundView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 3105A153; };\n"
    if target1 in c and "3105A253" not in c:
        c = c.replace(target1, insert1, 1)

    # 2. PBXFileReference
    target2 = '\t\t3105A152 /* AirliftPairingGateView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirliftPairingGateView.swift; sourceTree = "<group>"; };\n'
    insert2 = target2 + '\t\t3105A153 /* SnapchatFluidLiquidBackgroundView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SnapchatFluidLiquidBackgroundView.swift; sourceTree = "<group>"; };\n'
    if target2 in c and "SnapchatFluidLiquidBackgroundView.swift" not in c:
        c = c.replace(target2, insert2, 1)

    # 3. Group (views)
    target3 = "\t\t\t\t3105A152 /* AirliftPairingGateView.swift */,\n"
    insert3 = target3 + "\t\t\t\t3105A153 /* SnapchatFluidLiquidBackgroundView.swift */,\n"
    if target3 in c and "3105A153 /* SnapchatFluidLiquidBackgroundView.swift */," not in c:
        c = c.replace(target3, insert3, 1)

    # 4. PBXSourcesBuildPhase
    target4 = "\t\t\t\t3105A252 /* AirliftPairingGateView.swift in Sources */,\n"
    insert4 = target4 + "\t\t\t\t3105A253 /* SnapchatFluidLiquidBackgroundView.swift in Sources */,\n"
    if target4 in c and "3105A253 /* SnapchatFluidLiquidBackgroundView.swift in Sources */," not in c:
        c = c.replace(target4, insert4, 1)

    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(c)

    print("Updated:", pbx_path)

if __name__ == "__main__":
    add_file_to_pbx(r"ThreeOneOSFive.xcodeproj/project.pbxproj")
    add_file_to_pbx(r"D:/update_file/3105-2.0/3105-2.0/ThreeOneOSFive.xcodeproj/project.pbxproj")
