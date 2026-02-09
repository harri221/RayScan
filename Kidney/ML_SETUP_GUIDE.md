# 🧠 ML Service Setup Guide

## Prerequisites

You need Python 3.9 or 3.10 installed on your system.

### Step 1: Install Python

**Option A: Microsoft Store (Recommended for Windows)**
1. Open Microsoft Store
2. Search for "Python 3.10"
3. Click "Get" to install
4. Python will be added to PATH automatically

**Option B: Official Website**
1. Go to https://www.python.org/downloads/
2. Download Python 3.10.x installer
3. **IMPORTANT**: Check "Add Python to PATH" during installation
4. Run installer

### Step 2: Verify Python Installation

Open Command Prompt or PowerShell and run:
```bash
python --version
```

You should see: `Python 3.10.x` or `Python 3.9.x`

### Step 3: Install Dependencies

Navigate to the Kidney folder and install requirements:

```bash
cd "C:\Users\Admin\Downloads\flutter_application_1\Kidney"
pip install -r requirements.txt
```

This will install:
- Flask (Web framework)
- TensorFlow (ML library)
- OpenCV (Image processing)
- NumPy (Numerical computing)
- Flask-CORS (Cross-origin requests)

**Installation may take 5-10 minutes** as TensorFlow is a large package.

### Step 4: Verify Model File

Make sure the model file exists:
```
C:\Users\Admin\Downloads\flutter_application_1\Kidney\Kidney\kidney_stone_cnn.h5
```

### Step 5: Start ML Service

Run the Flask ML service:

```bash
cd "C:\Users\Admin\Downloads\flutter_application_1\Kidney"
python ml_service.py
```

You should see:
```
Loading model from: C:\Users\Admin\Downloads\flutter_application_1\Kidney\Kidney\kidney_stone_cnn.h5
Model loaded successfully!
Starting ML Service on port 5000
 * Running on http://0.0.0.0:5000
```

### Step 6: Test ML Service

Open a new terminal and test the health endpoint:

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "service": "Kidney Stone Detection ML Service"
}
```

---

## 🚀 Running Both Services

You need to run TWO services simultaneously:

### Terminal 1: Node.js Backend
```bash
cd "C:\Users\Admin\Downloads\flutter_application_1\backend"
npm run dev
```
Runs on: `http://localhost:3002`

### Terminal 2: Flask ML Service
```bash
cd "C:\Users\Admin\Downloads\flutter_application_1\Kidney"
python ml_service.py
```
Runs on: `http://localhost:5000`

---

## 📱 Using in Flutter App

Once both services are running:

1. Open the Flutter app
2. Login as a patient
3. Go to "Ultrasound" or scan option
4. Click "Upload Image"
5. Select a kidney ultrasound image
6. Click "Analyze Image"
7. Wait for AI prediction
8. View results with confidence score

---

## 🔧 Troubleshooting

### Error: "Python not found"
- Reinstall Python and check "Add to PATH"
- Restart your terminal/IDE

### Error: "ML service is not available"
- Make sure Flask service is running on port 5000
- Check firewall settings

### Error: "Model failed to load"
- Verify kidney_stone_cnn.h5 file exists
- Check file is not corrupted (should be ~85MB)

### Error: "TensorFlow installation failed"
- Try: `pip install --upgrade pip`
- Then: `pip install tensorflow==2.15.0`
- For CPU-only version: `pip install tensorflow-cpu==2.15.0`

### Error: "Port 5000 already in use"
- Change port in ml_service.py line 202
- Update ML_SERVICE_URL in backend/.env

---

## 🎯 API Endpoints

### ML Service (Port 5000)
- `GET /` - Service info
- `GET /health` - Health check
- `POST /predict` - Upload image for prediction

### Node.js Backend (Port 3002)
- `POST /api/ml/predict/kidney-stone` - Full prediction + save to DB
- `GET /api/ml/reports` - Get user's reports
- `GET /api/ml/reports/:id` - Get single report
- `GET /api/ml/ml-service/health` - Check ML service status

---

## 📊 Test with Sample Images

Use images from:
```
C:\Users\Admin\Downloads\flutter_application_1\Kidney\Kidney\Dataset\
```

- `normal/` - Normal kidney images
- `stone/` - Kidney stone images

---

## ✅ Verification Checklist

- [ ] Python 3.9+ installed
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Model file exists (`kidney_stone_cnn.h5`)
- [ ] ML service starts without errors
- [ ] Health endpoint returns success
- [ ] Node.js backend running
- [ ] Backend can connect to ML service
- [ ] Flutter app can upload images
- [ ] Predictions are displayed correctly

---

## 🎉 Success!

If all checks pass, your ML-powered kidney stone detection is ready!

The system uses a Convolutional Neural Network (CNN) trained on ultrasound images to detect kidney stones with high accuracy.

**Remember**: This is an AI-assisted diagnostic tool for preliminary screening. Always consult qualified medical professionals for final diagnosis.
