# ==============================================================================
# Script đóng gói & nén dự án CheatStoreVN độc lập trên Windows
# ==============================================================================

$ProjectDir = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectDir "build"
$ZipFile = Join-Path $ProjectDir "CheatStoreVN_Independent_Project.zip"

Write-Host "=== [1/3] Kiểm tra tính toàn vẹn cấu trúc file CheatStoreVN ===" -ForegroundColor Cyan

$RequiredFiles = @(
    "CheatStoreVN\App\CheatStoreVNApp.swift",
    "CheatStoreVN\Core\Theme.swift",
    "CheatStoreVN\Core\LocalConfigManager.swift",
    "CheatStoreVN\Core\LicenseManager.swift",
    "CheatStoreVN\Core\ContainerManager.swift",
    "CheatStoreVN\Core\DeviceProfileService.swift",
    "CheatStoreVN\Views\Components\UIComponents.swift",
    "CheatStoreVN\Views\Components\InjectorBarButton.swift",
    "CheatStoreVN\Views\Tabs\AimTabView.swift",
    "CheatStoreVN\Views\Tabs\EspTabView.swift",
    "CheatStoreVN\Views\Tabs\MiscTabView.swift",
    "CheatStoreVN\Views\Tabs\MeTabView.swift",
    "CheatStoreVN\Views\Main\MainDashboardView.swift",
    "CheatStoreVN\Views\Login\LoginView.swift",
    "CheatStoreVN\Resources\Assembly-CSharp-patch.bytes",
    "CheatStoreVN\Resources\localConfig.json",
    "CheatStoreVN\Resources\Info.plist",
    "CheatStoreVN.xcodeproj\project.pbxproj"
)

$AllOk = $true
foreach ($file in $RequiredFiles) {
    $fullPath = Join-Path $ProjectDir $file
    if (Test-Path $fullPath) {
        Write-Host " [OK] $file" -ForegroundColor Green
    } else {
        Write-Host " [MISSING] $file" -ForegroundColor Red
        $AllOk = $false
    }
}

if (-not $AllOk) {
    Write-Host "Cảnh báo: Có file chưa tồn tại!" -ForegroundColor Yellow
} else {
    Write-Host "Toàn bộ file mã nguồn và cấu hình đã đầy đủ 100%!" -ForegroundColor Green
}

Write-Host "`n=== [2/3] Nén dự án thành file ZIP độc lập ===" -ForegroundColor Cyan
if (Test-Path $ZipFile) {
    Remove-Item $ZipFile -Force
}

Compress-Archive -Path "$ProjectDir\CheatStoreVN", "$ProjectDir\CheatStoreVN.xcodeproj", "$ProjectDir\scripts" -DestinationPath $ZipFile -Force
Write-Host "Đã xuất file dự án: $ZipFile" -ForegroundColor Green

Write-Host "`n=== [3/3] Hướng dẫn sử dụng & Ký IPA ===" -ForegroundColor Cyan
Write-Host "1. Dự án hoàn toàn độc lập, không còn phụ thuộc vào 3105."
Write-Host "2. Để build trực tiếp trên macOS: Mở CheatStoreVN.xcodeproj bằng Xcode hoặc chạy sh scripts/package_ipa.sh"
Write-Host "3. Để cài đặt qua ESign / Scarlet / GBox / TrollStore: Ký file IPA xuất ra bằng chứng chỉ doanh nghiệp hoặc cá nhân."
