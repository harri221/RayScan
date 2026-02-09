@echo off
echo ============================================================
echo RayScan VGG16 Model Training
echo Target: 99%+ Accuracy (Based on Research Paper)
echo ============================================================
echo.

cd /d "%~dp0ml_model"

REM Check if venv exists
if exist "venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo Creating virtual environment...
    python -m venv venv
    call venv\Scripts\activate.bat

    echo Installing required packages...
    pip install --upgrade pip
    pip install tensorflow numpy opencv-python scikit-learn matplotlib tqdm
)

echo.
echo Starting VGG16 model training...
echo This may take 30-60 minutes depending on your hardware.
echo.

python train_vgg16_model.py

echo.
echo ============================================================
echo Training complete! Check the output above for results.
echo The new model has been saved to assets/models/kidney_stone.tflite
echo ============================================================
pause
