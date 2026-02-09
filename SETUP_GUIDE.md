# RayScan Healthcare App - Complete Setup Guide

## ✅ What's Already Done

### 1. Backend Server
- **Status:** ✅ Running on port 3002
- **Features:**
  - User authentication (JWT)
  - Doctor profiles & appointments
  - Chat messaging (REST API + Socket.io)
  - ML prediction endpoints
  - PostgreSQL database

### 2. Flutter App Features
- ✅ Patient & Doctor login/signup
- ✅ Doctor search & booking
- ✅ Real-time chat with doctors
- ✅ Video/Audio calling (Jitsi Meet)
- ✅ Profile management (loads real user data)
- ✅ Ultrasound AI upload UI
- ✅ Appointment management

### 3. Video/Audio Calling
- **Technology:** Jitsi Meet (FREE, no API key needed)
- **Features:**
  - HD video calling
  - Audio-only calls
  - Screen sharing
  - Chat during call
  - Raise hand feature

---

## 🔧 What You Need to Do Now

### Step 1: Train the ML Model (REQUIRED)

The kidney stone detection AI needs to be trained. This is a **ONE-TIME** setup.

**Open a NEW terminal and run:**

```bash
cd Kidney
python retrain_model.py
```

**What happens:**
- Training runs for 15 epochs
- Takes approximately 15-20 minutes
- You'll see progress like:
  ```
  Epoch 1/15
  Training accuracy: 95.41% - Validation accuracy: 46.87%
  Epoch 2/15
  Training accuracy: 96.23% - Validation accuracy: 52.34%
  ...
  ```

**When complete, you'll see:**
```
✅ Model saved as kidney_stone_cnn_new.h5
```

**DO NOT close this terminal!**

---

### Step 2: Start the ML Service

**After training completes, in the SAME terminal:**

```bash
python ml_service.py
```

**What happens:**
- Flask server starts on port 5000
- Loads the trained model
- You'll see:
  ```
  * Running on http://127.0.0.1:5000
  ✅ Model loaded successfully!
  ```

**Keep this terminal open!**

---

### Step 3: Run the Flutter App

**Open ANOTHER NEW terminal:**

```bash
flutter run
```

Or just click the "Run" button in VS Code.

---

## 🎮 Testing the Complete App

### Test 1: User Profile ✅
1. Login as patient
2. Go to Profile tab
3. **Expected:** Shows your real name from database (not "Amelia Renata")

### Test 2: Chat with Doctor ✅
1. Go to Appointments tab
2. Click "Chat" button on any appointment
3. Type a message and send
4. **Expected:** Message appears, updates every 5 seconds

### Test 3: Video Call ✅
1. Open chat with a doctor
2. Click the 📹 **video camera icon** in the top right
3. **Expected:** Jitsi Meet window opens
4. You can see yourself and wait for doctor to join

### Test 4: Audio Call ✅
1. Open chat with a doctor
2. Click the 📞 **phone icon** in the top right
3. **Expected:** Jitsi Meet opens with video off (audio only)

### Test 5: ML Kidney Detection 🔄 (After ML service is running)
1. Home → Click "Ultrasound"
2. Select "Kidney"
3. Click "Select Scan Image"
4. Pick an ultrasound image
5. Click "Analyze"
6. **Expected:**
   - Shows processing indicator
   - Returns: "Stone Detected" or "Normal Kidney"
   - Shows confidence percentage
   - Displays medical recommendations

---

## 📋 Checklist - What Should Be Running

Before testing, make sure you have **3 things running**:

- [x] **Backend Server** (Port 3002) - Already running ✅
- [ ] **ML Service** (Port 5000) - Start after training
- [ ] **Flutter App** - Run with `flutter run`

---

## 🎯 How Video Calling Works

### For Patients:
1. Book appointment with doctor
2. Go to Appointments → Click "Chat"
3. Click video/audio icon in chat
4. Jitsi Meet opens automatically
5. Wait for doctor to join (they get same room link)

### Technical Details:
- **Platform:** Jitsi Meet (open source, free)
- **Room names:** Unique per conversation (e.g., `rayscan-appt123-dr5-pt8`)
- **Privacy:** Rooms are temporary, deleted after call ends
- **No account needed:** Works instantly, no signup
- **Features available:**
  - Toggle camera/mic
  - Share screen
  - Text chat during call
  - Raise hand
  - End call

---

## 🐛 Troubleshooting

### Chat not working?
**Check:** Is backend server running?
```bash
curl http://localhost:3002/api/health
```
Expected: `{"status":"OK",...}`

### Video call button does nothing?
**Check:** Did you run `flutter pub get` after adding Jitsi package?
```bash
flutter pub get
```

### ML upload fails?
**Check:** Is ML service running on port 5000?
```bash
curl http://localhost:5000/health
```
Expected: `{"status":"OK","model_loaded":true}`

### Can't train model?
**Check:** Python and dependencies installed?
```bash
python --version
pip list | grep tensorflow
```

---

## 🚀 Quick Start Commands

**Terminal 1 - ML Training & Service:**
```bash
cd Kidney
python retrain_model.py
# Wait 15-20 minutes
python ml_service.py
# Keep running
```

**Terminal 2 - Flutter App:**
```bash
flutter run
```

**Backend is already running in background on port 3002** ✅

---

## 📞 Feature Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Patient Login/Signup | ✅ | Working |
| Doctor Login/Signup | ✅ | Working |
| Doctor Search | ✅ | Working |
| Appointment Booking | ✅ | Working |
| Chat Messaging | ✅ | Real-time polling every 5s |
| Video Calling | ✅ | Jitsi Meet integration |
| Audio Calling | ✅ | Jitsi Meet audio-only |
| Profile Management | ✅ | Loads real user data |
| ML Kidney Detection | 🔄 | Needs training + service |
| Appointment History | ✅ | Working |
| Doctor Dashboard | ✅ | Real statistics |

---

## 🎉 You're Almost Done!

Just complete:
1. ⏳ Train ML model (Step 1)
2. ⏳ Start ML service (Step 2)
3. ✅ Everything else is ready!

**Total setup time remaining: ~20 minutes**

---

## 💡 Tips

- Video calls work between any 2 users who click the same appointment's video button
- You can test video calling by opening the app on 2 devices/emulators
- Chat messages sync every 5 seconds automatically
- ML predictions are saved to database with timestamps
- Doctor dashboard shows live statistics from database

Good luck! 🚀
