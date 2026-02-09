# Agora Video/Audio Calling Setup Instructions

## What Changed

I've replaced Jitsi Meet with **Agora RTC Engine** for video and audio calling. Agora is more reliable, works better on Android/iOS, and offers **10,000 free minutes per month** which is perfect for your healthcare app.

## Why Agora Instead of Jitsi?

1. **Better Mobile Support**: Agora works flawlessly on Android and iOS
2. **No Server Required**: Agora handles all the infrastructure
3. **Free Tier**: 10,000 minutes/month free (enough for 166+ hours of calls)
4. **Better Performance**: Lower latency, better video quality
5. **Easy to Use**: Simple API, no complicated setup

## Setup Steps (IMPORTANT - DO THIS FIRST!)

### Step 1: Create Free Agora Account

1. Go to https://console.agora.io/
2. Click "Sign Up" and create a free account
3. Verify your email address
4. Login to Agora Console

### Step 2: Create a Project

1. In Agora Console, click "+ New Project"
2. Enter project name: `RayScan Healthcare`
3. Choose "Secured mode: APP ID + Token" (for testing, we'll use "Testing mode: APP ID" first)
4. Click "Submit"

### Step 3: Get Your App ID

1. After creating the project, you'll see your **App ID**
2. **COPY THIS APP ID** - you'll need it in the next step

### Step 4: Add App ID to Your Code

Open this file:
```
lib/services/agora_video_call_service.dart
```

Find line 22 and replace `YOUR_AGORA_APP_ID_HERE` with your actual App ID:

**BEFORE:**
```dart
static const String APP_ID = 'YOUR_AGORA_APP_ID_HERE';
```

**AFTER** (example):
```dart
static const String APP_ID = '0e8f7c6d5b4a3f2e1d9c8b7a6f5e4d3c';
```

### Step 5: Test the App

1. Stop the Flutter app if it's running
2. Restart the app using `flutter run`
3. Try making a video or audio call from the chat screen

## How It Works Now

### For Patients:
1. Open a conversation with a doctor
2. Click the **phone icon** for audio call or **video icon** for video call
3. You'll be taken to a call screen where you can:
   - Mute/unmute microphone
   - Turn camera on/off (video calls only)
   - Switch between front/back camera
   - End the call

### For Doctors:
Same functionality as patients - both can initiate and receive calls.

## Files Changed

### New Files Created:
1. `lib/services/agora_video_call_service.dart` - Agora service wrapper
2. `lib/screens/agora_video_call_screen.dart` - Beautiful call screen UI
3. `AGORA_SETUP_INSTRUCTIONS.md` - This file

### Modified Files:
1. `pubspec.yaml` - Added Agora and permission_handler packages
2. `lib/screens/consultation_chat.dart` - Updated to use Agora
3. `lib/screens/chat_screen.dart` - Updated to use Agora
4. `lib/screens/doctor_home_screen.dart` - Added Socket.io connection maintenance
5. `lib/services/socket_service.dart` - Added reconnection logic

## Testing Checklist

- [ ] App ID added to `agora_video_call_service.dart`
- [ ] App restarts successfully
- [ ] Patient can start video call
- [ ] Patient can start audio call
- [ ] Doctor can receive and accept calls
- [ ] Microphone mute/unmute works
- [ ] Camera on/off works (video calls)
- [ ] Camera switch works (video calls)
- [ ] End call works for both parties

## Permissions Required

The app will automatically request these permissions when you start a call:
- **Camera** - For video calls
- **Microphone** - For both audio and video calls

## Troubleshooting

### Problem: "Agora error: Invalid App ID"
**Solution**: Make sure you copied the correct App ID from Agora Console

### Problem: Camera/Microphone not working
**Solution**: Check that you granted permissions when prompted. Go to Android Settings → Apps → Your App → Permissions

### Problem: "Failed to join call"
**Solution**:
1. Check your internet connection
2. Make sure App ID is correct
3. Check Agora Console to ensure project is active

### Problem: Other user can't see/hear me
**Solution**: Both users must have the same channel name. The app automatically handles this using the conversation ID.

## Production Deployment (Later)

For production, you should:

1. **Enable Token Authentication** in Agora Console for security
2. **Create a Token Server** to generate temporary tokens
3. **Store App ID** in environment variables (not hardcoded)
4. **Monitor Usage** in Agora Console to track minutes used

## Cost Estimate

**Free Tier**: 10,000 minutes/month
- That's ~166 hours of calls per month
- Perfect for testing and small-scale deployment
- Equivalent to ~332 calls of 30 minutes each

**After Free Tier**:
- Video: $0.99 per 1,000 minutes
- Audio: $0.99 per 1,000 minutes
- Very affordable even at scale!

## Support

If you have questions about Agora setup:
- Agora Documentation: https://docs.agora.io/
- Agora Community: https://www.agora.io/en/community/

---

**Next Steps**: Follow the setup steps above to get your Agora App ID, then test the calling functionality!
