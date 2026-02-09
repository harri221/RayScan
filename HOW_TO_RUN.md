# RayScan Healthcare App - Complete Setup Guide

## 🚀 Quick Start (3 Easy Steps)

### Option 1: Automated Start (Easiest)
Double-click **`start_app.bat`** in the main folder. It will:
- Check if backend is running
- Start backend if needed
- Launch Flutter app automatically

---

## 📋 Manual Setup (Step by Step)

### Step 1: Start Backend Server

**Open Terminal 1:**
```bash
cd c:\Users\Admin\Downloads\flutter_application_1\backend
node server.js
```

**Wait for this message:**
```
🚀 RayScan Backend Server running on port 3002
```

---

### Step 2: Start Flutter App

**Open Terminal 2:**
```bash
cd c:\Users\Admin\Downloads\flutter_application_1
flutter run
```

---

### Step 3 (Optional): Train ML Model

**Open Terminal 3 (run in parallel):**

**Option A - Use Script:**
Double-click **`train_model.bat`**

**Option B - Manual:**
```bash
cd c:\Users\Admin\Downloads\flutter_application_1\Kidney
python retrain_model.py
```

**Training Time:** 10-30 minutes (runs in background, app still works)

---

## ✅ Features Implemented

### 1. Chat & Messaging System
- ✅ Real-time messaging with Socket.io
- ✅ WhatsApp-style UI
- ✅ Typing indicators
- ✅ Message timestamps (timeago format)
- ✅ Works for both patients and doctors
- ✅ Conversations list with unread counts

### 2. Audio & Video Calls
- ✅ **FREE** Jitsi Meet integration (no backend needed!)
- ✅ Audio-only calls
- ✅ Video calls with camera
- ✅ In-chat call buttons
- ✅ Incoming call notifications
- ✅ Accept/Decline call dialog

### 3. Pharmacy Finder
- ✅ **FREE** OpenStreetMap API
- ✅ GPS-based location detection
- ✅ 3-4 km search radius
- ✅ Sorted by distance
- ✅ WhatsApp contact integration
- ✅ Phone call integration
- ✅ Works anywhere in Pakistan (or worldwide)

### 4. Kidney Stone Detection AI
- ✅ TensorFlow/Keras CNN model
- ✅ Upload ultrasound image
- ✅ Real-time prediction
- ✅ Confidence scores
- ✅ Report generation

### 5. Doctor Features
- ✅ Appointment management
- ✅ Schedule settings
- ✅ Patient conversations
- ✅ Chat & video consultations
- ✅ Profile management

### 6. Patient Features
- ✅ Find nearby doctors
- ✅ Book appointments
- ✅ AI kidney stone detection
- ✅ Find nearby pharmacies
- ✅ Chat with doctors
- ✅ Audio/Video consultations

---

## 🎯 How to Use Chat & Calls

### For Patients:
1. **Start Chat:**
   - Go to "Doctors" tab
   - Select a doctor
   - Click **"Chat with Doctor"** button
   - Start messaging!

2. **Or from Messages:**
   - Click "Messages" icon (bottom nav)
   - See all conversations
   - Tap any conversation

3. **Make Calls:**
   - Open any chat
   - Click **phone icon** (audio call)
   - Or **videocam icon** (video call)

### For Doctors:
1. **View Messages:**
   - Click "Messages" tab (3rd icon)
   - See all patient conversations
   - Tap to open chat

2. **Reply & Call:**
   - Type and send messages
   - Click call buttons to video/audio call patients

---

## 🔧 Troubleshooting

### Backend Already Running Error
```
Error: listen EADDRINUSE: address already in use :::3002
```

**Solution:**
```bash
# Find the process
netstat -ano | findstr :3002

# Kill it (replace 12345 with actual PID)
taskkill /PID 12345 /F

# Then restart
cd backend
node server.js
```

### Red Screen in Messages
**Fixed!** The app now handles all data type mismatches automatically.

### Pharmacy Shows Wrong Location
**Fixed!** The app now uses real GPS location.

**For testing in emulator:**
- Android Studio → Tools → Device Manager → Extended Controls → Location
- Set to Islamabad: 33.6844, 73.0479

### Chat Not Working
1. Check backend is running: `http://localhost:3002/api/health`
2. Check Socket.io connection in backend logs: `👤 User connected`
3. Try logging out and back in

---

## 📱 Test Credentials

### Patient Account:
- Email: test@test.com
- Password: test123

### Doctor Account:
- Email: doctor@test.com
- Password: test123

---

## 🎨 UI Improvements Made

### Chat Screen:
- WhatsApp-style message bubbles
- Clean, modern interface
- Smooth animations
- Color-coded messages (patient vs doctor)
- Typing indicators
- Real-time updates

### Conversations List:
- Avatar initials when no profile picture
- Last message preview
- Unread count badges
- Timeago timestamps
- Pull-to-refresh
- Empty state design

### Video/Audio Calls:
- Uses free Jitsi Meet (no costs!)
- High-quality video
- Works on any device
- No additional setup needed
- Incoming call dialog with accept/decline

---

## 🆓 All Services Are FREE

1. **Jitsi Meet** - Video/Audio calls (no cost, no limits)
2. **OpenStreetMap** - Pharmacy location (free API)
3. **Socket.io** - Real-time chat (self-hosted, free)
4. **PostgreSQL** - Database (self-hosted, free)
5. **Node.js** - Backend server (self-hosted, free)

**Total Monthly Cost:** $0.00 (until you deploy to cloud)

---

## 📞 Need Help?

If you encounter any issues:
1. Check backend logs for errors
2. Check Flutter console for errors
3. Try hot reload: press `r` in Flutter terminal
4. Try hot restart: press `R` in Flutter terminal
5. Close and restart everything

---

## 🎉 You're All Set!

Your complete healthcare app is now ready with:
- ✅ Real-time chat
- ✅ Audio/Video calls
- ✅ Pharmacy finder
- ✅ AI diagnosis
- ✅ Appointment booking
- ✅ Doctor-patient communication

**Enjoy building!** 🚀
