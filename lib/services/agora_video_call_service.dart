import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as dev;

/// Agora Video Call Service
///
/// This service provides video and audio calling functionality using Agora RTC Engine.
/// Agora offers 10,000 free minutes per month which is perfect for healthcare consultations.
///
/// Setup Instructions:
/// 1. Create free account at https://console.agora.io/
/// 2. Create a project and get your App ID
/// 3. Replace APP_ID below with your actual Agora App ID
///
/// For production, you should:
/// - Store APP_ID in environment variables or secure storage
/// - Implement token-based authentication for security
/// - Set up a token server to generate temporary tokens
class AgoraVideoCallService {
  // IMPORTANT: Replace this with your actual Agora App ID
  // Get it from https://console.agora.io/
  static const String APP_ID = 'cd28bbcbdc2f41fcb3d9acfda5ae056b';

  static RtcEngine? _engine;
  static bool _isInitialized = false;

  /// Initialize Agora Engine
  static Future<void> initialize() async {
    if (_isInitialized) {
      dev.log('Agora already initialized');
      return;
    }

    try {
      // Request permissions
      await [Permission.camera, Permission.microphone].request();

      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: APP_ID,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Enable video
      await _engine!.enableVideo();
      await _engine!.enableAudio();

      // Set video configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
        ),
      );

      _isInitialized = true;
      dev.log('✅ Agora initialized successfully');
    } catch (e) {
      dev.log('❌ Error initializing Agora: $e');
      rethrow;
    }
  }

  /// Join a video call
  ///
  /// [channelName] - Unique channel name for the call (e.g., "rayscan-appt123")
  /// [userId] - User ID (0 for auto-assignment by Agora)
  /// [isVideoEnabled] - true for video call, false for audio-only
  static Future<void> joinCall({
    required String channelName,
    int userId = 0,
    bool isVideoEnabled = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      dev.log('🎥 Joining channel: $channelName, Video: $isVideoEnabled');

      // Enable/disable video based on call type
      if (isVideoEnabled) {
        await _engine!.enableLocalVideo(true);
      } else {
        await _engine!.enableLocalVideo(false);
      }

      // Join channel
      await _engine!.joinChannel(
        token:
            '', // Use empty string for testing; implement token server for production
        channelId: channelName,
        uid: userId,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      dev.log('✅ Successfully joined channel: $channelName');
    } catch (e) {
      dev.log('❌ Error joining channel: $e');
      rethrow;
    }
  }

  /// Leave the current call
  static Future<void> leaveCall() async {
    try {
      await _engine?.leaveChannel();
      dev.log('✅ Left channel successfully');
    } catch (e) {
      dev.log('❌ Error leaving channel: $e');
    }
  }

  /// Dispose the engine
  static Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      _isInitialized = false;
      dev.log('✅ Agora engine disposed');
    } catch (e) {
      dev.log('❌ Error disposing Agora engine: $e');
    }
  }

  /// Toggle microphone
  static Future<void> toggleMicrophone(bool enabled) async {
    await _engine?.muteLocalAudioStream(!enabled);
  }

  /// Toggle camera
  static Future<void> toggleCamera(bool enabled) async {
    await _engine?.muteLocalVideoStream(!enabled);
  }

  /// Switch camera (front/back)
  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Get the RTC engine instance for event handlers
  static RtcEngine? get engine => _engine;

  /// Generate a unique channel name from appointment details
  static String generateChannelName(
    int appointmentId,
    int doctorId,
    int patientId,
  ) {
    return 'rayscan-appt$appointmentId-dr$doctorId-pt$patientId';
  }

  /// Check if engine is initialized
  static bool get isInitialized => _isInitialized;
}
