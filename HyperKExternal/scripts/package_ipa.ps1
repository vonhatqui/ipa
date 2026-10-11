# ==============================================================================
# Script đóng gói & nén dự án HyperK External độc lập trên Windows
# ==============================================================================

$ProjectDir = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $ProjectDir "build"
$ZipFile = Join-Path $ProjectDir "HyperKExternal_Independent_Project.zip"

Write-Host "=== [1/3] Kiểm tra tính toàn vẹn cấu trúc file HyperK External ===" -ForegroundColor Cyan

$RequiredFiles = @(
    "HyperKExternal\App\HyperKExternalApp.swift",
    "HyperKExternal\Core\Theme.swift",
    "HyperKExternal\Core\LocalConfigManager.swift",
    "HyperKExternal\Core\LicenseManager.swift",
    "HyperKExternal\Core\ContainerManager.swift",
    "HyperKExternal\Core\DeviceProfileService.swift",
    "HyperKExternal\Views\Components\UIComponents.swift",
    "HyperKExternal\Views\Components\InjectorBarButton.swift",
    "HyperKExternal\Views\Tabs\AimTabView.swift",
    "HyperKExternal\Views\Tabs\EspTabView.swift",
    "HyperKExternal\Views\Tabs\MiscTabView.swift",
    "HyperKExternal\Views\Tabs\MeTabView.swift",
    "HyperKExternal\Views\Main\MainDashboardView.swift",
    "HyperKExternal\Views\Login\LoginView.swift",
    "HyperKExternal\Resources\Assembly-CSharp-patch.bytes",
    "HyperKExternal\Resources\localConfig.json",
    "HyperKExternal\Resources\Info.plist",
    "HyperKExternal.xcodeproj\project.pbxproj"
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

Compress-Archive -Path "$ProjectDir\HyperKExternal", "$ProjectDir\HyperKExternal.xcodeproj", "$ProjectDir\scripts" -DestinationPath $ZipFile -Force
Write-Host "Đã xuất file dự án: $ZipFile" -ForegroundColor Green

Write-Host "`n=== [3/3] Hướng dẫn sử dụng & Ký IPA ===" -ForegroundColor Cyan
Write-Host "1. Dự án HyperK External hoàn toàn độc lập, không còn phụ thuộc vào 3105."
Write-Host "2. Để build trực tiếp trên macOS: Mở HyperKExternal.xcodeproj bằng Xcode hoặc chạy sh scripts/package_ipa.sh"
Write-Host "3. Để cài đặt qua ESign / Scarlet / GBox / TrollStore: Ký file IPA xuất ra bằng chứng chỉ doanh nghiệp hoặc cá nhân."
