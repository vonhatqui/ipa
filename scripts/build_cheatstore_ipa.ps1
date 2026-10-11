# ==============================================================================
# Script đóng gói & biên dịch IPA hoàn chỉnh: CheatStore VN (CheatStoreVN.ipa)
# ==============================================================================

param(
    [string]$BaseIpa = "base_delta/DELTA_CLIENT.ipa",
    [string]$OutIpa = "CheatStoreVN.ipa",
    [string]$PatchSource = "ThreeOneOSFive/Assembly-CSharp-patch.bytes",
    [string]$ConfigSource = "ThreeOneOSFive/AppCore/new123/localConfig.json",
    [string]$IconSource = "ThreeOneOSFive/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.Drawing

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       BẮT ĐẦU ĐÓNG GÓI BẢN PHÁT HÀNH: CheatStoreVN.ipa  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kiểm tra file nguồn
if (-not (Test-Path $BaseIpa)) {
    Write-Error "Không tìm thấy base IPA: $BaseIpa"
    exit 1
}
if (-not (Test-Path $PatchSource)) {
    Write-Error "Không tìm thấy file patch: $PatchSource"
    exit 1
}
if (-not (Test-Path $ConfigSource)) {
    Write-Error "Không tìm thấy file config: $ConfigSource"
    exit 1
}

$patchBytes = [System.IO.File]::ReadAllBytes($PatchSource)
$configBytes = [System.IO.File]::ReadAllBytes($ConfigSource)
Write-Host " [OK] Đã tải Assembly-CSharp-patch.bytes: $($patchBytes.Length) bytes" -ForegroundColor Green
Write-Host " [OK] Đã tải localConfig.json: $($configBytes.Length) bytes" -ForegroundColor Green

# 2. Xử lý Icon
$icon120 = $null
$icon152 = $null
$icon180 = $null

if (Test-Path $IconSource) {
    Write-Host " [OK] Tạo bộ AppIcon đa kích thước từ: $IconSource" -ForegroundColor Green
    $srcImg = [System.Drawing.Image]::FromFile((Resolve-Path $IconSource).Path)
    
    function Resize-Image($img, [int]$w, [int]$h) {
        $dest = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($dest)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($img, 0, 0, $w, $h)
        $g.Dispose()
        $ms = New-Object System.IO.MemoryStream
        $dest.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $dest.Dispose()
        $bytes = $ms.ToArray()
        $ms.Dispose()
        return $bytes
    }
    
    $icon120 = Resize-Image $srcImg 120 120
    $icon152 = Resize-Image $srcImg 152 152
    $icon180 = Resize-Image $srcImg 180 180
    $srcImg.Dispose()
}

# 3. Mở Base IPA và tạo Output IPA
if (Test-Path $OutIpa) {
    Remove-Item $OutIpa -Force
}

$zipSrc = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $BaseIpa).Path)
$fsOut = [System.IO.File]::Create($OutIpa)
$zipOut = New-Object System.IO.Compression.ZipArchive($fsOut, [System.IO.Compression.ZipArchiveMode]::Create)

$appFolder = "Payload/Zrxipa.app"

# Replacement Table cho Binary
$binaryReplacements = @(
    @{ Old = "discord.gg/deltaclient"; New = "discord.gg/jinwwostore" },
    @{ Old = "discord.gg/zrxsoftware"; New = "discord.gg/jinwwostore" },
    @{ Old = "t.me/dovietphuog";       New = "t.me/jinwwostore" }
)

Write-Host " Đang ghi gói IPA và cập nhật binary..." -ForegroundColor Yellow

foreach ($entry in $zipSrc.Entries) {
    $name = $entry.FullName
    
    # Bỏ qua chữ ký cũ và provisioning profile cũ để ESign / TrollStore ký sạch
    if ($name -match "_CodeSignature" -or $name -match "SignedByEsign" -or $name -match "embedded\.mobileprovision") {
        continue
    }
    
    # 3.1. Cập nhật Info.plist
    if ($name -eq "$appFolder/Info.plist") {
        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $plistContent = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        
        # Cập nhật tên hiển thị thành CheatStore VN
        $plistContent = $plistContent -replace "<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>", "<key>CFBundleDisplayName</key>`n`t<string>CheatStore VN</string>"
        $plistContent = $plistContent -replace "<key>CFBundleShortVersionString</key>\s*<string>[^<]*</string>", "<key>CFBundleShortVersionString</key>`n`t<string>1.0.0</string>"
        $plistContent = $plistContent -replace "<key>CFBundleVersion</key>\s*<string>[^<]*</string>", "<key>CFBundleVersion</key>`n`t<string>1.0.0</string>"
        
        $newEntry = $zipOut.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $newEntry.Open()
        $sw = New-Object System.IO.StreamWriter($es, [System.Text.Encoding]::UTF8)
        $sw.Write($plistContent)
        $sw.Close()
        $es.Close()
        continue
    }
    
    # 3.2. Cập nhật Binary Zrxipa
    if ($name -eq "$appFolder/Zrxipa") {
        $stream = $entry.Open()
        $ms = New-Object System.IO.MemoryStream
        $stream.CopyTo($ms)
        $binBytes = $ms.ToArray()
        $stream.Close()
        $ms.Close()
        
        $binStr = [System.Text.Encoding]::ASCII.GetString($binBytes)
        foreach ($r in $binaryReplacements) {
            $idx = $binStr.IndexOf($r.Old)
            if ($idx -ge 0) {
                $newBytes = [System.Text.Encoding]::ASCII.GetBytes($r.New)
                for ($k = 0; $k -lt $newBytes.Length; $k++) {
                    $binBytes[$idx + $k] = $newBytes[$k]
                }
                Write-Host "   -> Đã thay thế URL '$($r.Old)' thành '$($r.New)' tại offset $idx" -ForegroundColor Green
            }
        }
        
        $newEntry = $zipOut.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $newEntry.Open()
        $es.Write($binBytes, 0, $binBytes.Length)
        $es.Close()
        continue
    }
    
    # 3.3. Thay thế Icons nếu có
    if ($icon120 -and $name -eq "$appFolder/AppIcon60x60@2x.png") {
        $newEntry = $zipOut.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $newEntry.Open()
        $es.Write($icon120, 0, $icon120.Length)
        $es.Close()
        continue
    }
    if ($icon152 -and $name -eq "$appFolder/AppIcon76x76@2x~ipad.png") {
        $newEntry = $zipOut.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $newEntry.Open()
        $es.Write($icon152, 0, $icon152.Length)
        $es.Close()
        continue
    }
    
    # Sao chép các entry khác
    $newEntry = $zipOut.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal)
    $inStream = $entry.Open()
    $outStream = $newEntry.Open()
    $inStream.CopyTo($outStream)
    $inStream.Close()
    $outStream.Close()
}

# 4. Nhúng toàn bộ file Patch & Config mới vào App
Write-Host " Nhúng Assembly-CSharp-patch.bytes & localConfig.json vào bundle..." -ForegroundColor Yellow

$patchLocations = @(
    "$appFolder/Assembly-CSharp-patch.bytes",
    "$appFolder/localConfig.json",
    "$appFolder/AppCore/Assembly-CSharp-patch.bytes",
    "$appFolder/AppCore/localConfig.json",
    "$appFolder/AppCore/new123/Assembly-CSharp-patch.bytes",
    "$appFolder/AppCore/new123/localConfig.json",
    "$appFolder/BundledPatches/CheatVN_External_Files/Documents/Assembly-CSharp-patch.bytes",
    "$appFolder/BundledPatches/CheatVN_External_Files/Documents/localConfig.json",
    "$appFolder/BundledPatches/CheatVN External/Documents/Assembly-CSharp-patch.bytes",
    "$appFolder/BundledPatches/CheatVN External/Documents/localConfig.json"
)

foreach ($loc in $patchLocations) {
    $newEntry = $zipOut.CreateEntry($loc, [System.IO.Compression.CompressionLevel]::Optimal)
    $es = $newEntry.Open()
    if ($loc.EndsWith(".bytes")) {
        $es.Write($patchBytes, 0, $patchBytes.Length)
    } else {
        $es.Write($configBytes, 0, $configBytes.Length)
    }
    $es.Close()
}

# Nhúng logo ảnh bổ sung
$logoFiles = @(
    @{ Path = "$appFolder/cheatvn_logo.png"; File = "ThreeOneOSFive/cheatvn_logo.png" },
    @{ Path = "$appFolder/cheatvn_external.png"; File = "ThreeOneOSFive/cheatvn_external.png" },
    @{ Path = "$appFolder/CheatStoreLogo.jpg"; File = "ThreeOneOSFive/CheatStoreLogo.jpg" },
    @{ Path = "$appFolder/CheatLogo.png"; File = "ThreeOneOSFive/CheatLogo.png" }
)

foreach ($lf in $logoFiles) {
    if (Test-Path $lf.File) {
        $lBytes = [System.IO.File]::ReadAllBytes($lf.File)
        $newEntry = $zipOut.CreateEntry($lf.Path, [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $newEntry.Open()
        $es.Write($lBytes, 0, $lBytes.Length)
        $es.Close()
    }
}

$zipOut.Dispose()
$fsOut.Close()
$zipSrc.Dispose()

# Sao chép vào thư mục CheatStoreVN
$copyDest = "CheatStoreVN/CheatStoreVN.ipa"
Copy-Item $OutIpa $copyDest -Force

$ipaSize = (Get-Item $OutIpa).Length
$sizeMB = [Math]::Round($ipaSize / 1048576, 2)
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "       THANH CONG! DA XUAT FILE IPA HOAN CHINH:           " -ForegroundColor Green
Write-Host "       1. $OutIpa ($sizeMB MB)" -ForegroundColor Green
Write-Host "       2. $copyDest" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

