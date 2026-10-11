#!/bin/bash
set -e

# ==============================================================================
# Script đóng gói IPA cho HyperK External trên macOS
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/build"
SCHEME="HyperKExternal"
CONFIGURATION="Release"
IPA_NAME="HyperK-External.ipa"

echo "=== [1/4] Chuẩn bị thư mục build ==="
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

echo "=== [2/4] Kiểm tra môi trường Xcode ==="
if command -v xcodebuild &> /dev/null; then
    echo "Phát hiện xcodebuild. Bắt đầu biên dịch ứng dụng..."
    xcodebuild -project "${PROJECT_DIR}/HyperKExternal.xcodeproj" \
               -scheme "${SCHEME}" \
               -configuration "${CONFIGURATION}" \
               -sdk iphoneos \
               -derivedDataPath "${OUTPUT_DIR}/DerivedData" \
               CODE_SIGN_IDENTITY="" \
               CODE_SIGNING_REQUIRED=NO \
               CODE_SIGNING_ALLOWED=NO \
               clean build

    APP_PATH=$(find "${OUTPUT_DIR}/DerivedData" -name "${SCHEME}.app" | head -n 1)
    
    if [ -d "${APP_PATH}" ]; then
        echo "=== [3/4] Đóng gói Payload -> ${IPA_NAME} ==="
        mkdir -p "${OUTPUT_DIR}/Payload"
        cp -R "${APP_PATH}" "${OUTPUT_DIR}/Payload/"
        
        cd "${OUTPUT_DIR}"
        zip -r -q "${IPA_NAME}" Payload
        rm -rf Payload
        echo "=== [4/4] Hoàn tất! File IPA được lưu tại: ${OUTPUT_DIR}/${IPA_NAME} ==="
    else
        echo "Lỗi: Không tìm thấy ${SCHEME}.app sau khi biên dịch."
        exit 1
    fi
else
    echo "Môi trường không có xcodebuild (Windows/Linux)."
    echo "Vui lòng mở CheatStoreVN.xcodeproj trên Xcode hoặc sử dụng script PowerShell trên Windows."
fi
