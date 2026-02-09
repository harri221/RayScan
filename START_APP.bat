@echo off
echo ================================================
echo    RayScan Healthcare App - Startup Script
echo ================================================
echo.

REM Get current IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found
)
:found
set IP=%IP:~1%
echo Your current IP address: %IP%
echo.
echo Make sure this IP matches in:
echo   - lib/services/api_service.dart (line 11)
echo   - lib/services/socket_service.dart (line 12)
echo.
echo ================================================
echo.

REM Start Backend Server
echo [1/3] Starting Backend Server...
start "RayScan Backend" cmd /k "cd /d c:\Users\Admin\Downloads\flutter_application_1\backend && npm run dev"
timeout /t 3 /nobreak >nul

REM Start ML Service
echo [2/3] Starting ML Service...
start "RayScan ML Service" cmd /k "cd /d c:\Users\Admin\Downloads\flutter_application_1\Kidney\Kidney && python app.py"
timeout /t 3 /nobreak >nul

REM Start Flutter App
echo [3/3] Starting Flutter App...
echo.
echo Press any key to run Flutter app (make sure phone is connected)...
pause >nul
cd /d c:\Users\Admin\Downloads\flutter_application_1
flutter run

echo.
echo All services stopped.
pause
