@echo off
echo ========================================
echo Starting ML Model Training
echo ========================================
echo.
echo This will train the kidney stone detection model
echo Training may take 10-30 minutes depending on your hardware
echo.
pause

cd "c:\Users\Admin\Downloads\flutter_application_1\Kidney"
python retrain_model.py

echo.
echo ========================================
echo Training Complete!
echo ========================================
pause
