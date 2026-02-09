@echo off
echo ========================================
echo    RayScan - Starting All Services
echo ========================================
echo.

echo Checking if Python is installed...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed!
    echo Please install Python 3.9 or 3.10 first.
    echo.
    echo Instructions:
    echo 1. Open Microsoft Store
    echo 2. Search for "Python 3.10"
    echo 3. Click "Get" to install
    echo.
    echo OR visit: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [OK] Python is installed
echo.

echo Checking if ML dependencies are installed...
python -c "import flask" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] ML dependencies not installed
    echo Installing Python dependencies...
    cd Kidney
    pip install -r requirements.txt
    cd ..
)

echo.
echo ========================================
echo  Starting Node.js Backend (Port 3002)
echo ========================================
start "RayScan Backend" cmd /k "cd backend && npm run dev"
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo  Starting ML Service (Port 5000)
echo ========================================
start "RayScan ML Service" cmd /k "cd Kidney && python ml_service.py"
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo           Services Started!
echo ========================================
echo.
echo Backend:     http://localhost:3002
echo ML Service:  http://localhost:5000
echo.
echo Two new windows have opened:
echo  1. Node.js Backend
echo  2. Flask ML Service
echo.
echo Now you can run: flutter run
echo.
echo To stop services: Close the two terminal windows
echo.
pause
