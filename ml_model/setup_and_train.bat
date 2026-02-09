@echo off
echo ============================================================
echo RayScan ML Model - Setup and Training
echo ============================================================
echo.

cd /d "%~dp0"

echo [Step 1/4] Creating virtual environment...
if not exist "venv" (
    python -m venv venv
    echo Virtual environment created!
) else (
    echo Virtual environment already exists.
)

echo.
echo [Step 2/4] Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo [Step 3/4] Installing dependencies...
pip install --upgrade pip
pip install tensorflow==2.15.0 opencv-python==4.8.1.78 numpy==1.24.3 scikit-learn==1.3.2 xgboost==2.0.3 matplotlib==3.8.2 tqdm==4.66.1

echo.
echo [Step 4/4] Starting training...
echo ============================================================
python train_model.py

echo.
echo ============================================================
echo Training complete! Check the models folder for output.
echo ============================================================
pause
