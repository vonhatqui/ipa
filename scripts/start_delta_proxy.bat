@echo off
chcp 65001 >nul
title CHEATVN IPA - Máy Chủ Ghép Đôi iOS
cls
echo ========================================================
echo       CHEATVN IPA - REMOTE PAIRING HOST FOR iOS
echo ========================================================
echo.
echo Đang kiểm tra môi trường Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [LỖI] Máy tính chưa cài đặt Python!
    echo Vui lòng tải và cài đặt Python từ https://www.python.org/ (Nhớ tích 'Add Python to PATH')
    pause
    exit /b
)

python -c "import zeroconf" >nul 2>&1
if %errorlevel% neq 0 (
    echo Đang cài đặt thư viện phát sóng Bonjour (zeroconf)...
    pip install zeroconf
)

echo.
echo Đang khởi động máy chủ CHEATVN IPA...
python "%~dp0delta_proxy_pc.py"
pause
