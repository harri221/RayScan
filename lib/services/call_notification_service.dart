import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart';
import '../screens/agora_video_call_screen.dart';

/// Global Call Notification Service
///
/// This service listens for incoming calls across the entire app
/// and shows notifications/dialogs regardless of which screen is active.
/// This is especially important for doctors who need to receive call notifications
/// even when not in the chat screen.
class CallNotificationService {
  static BuildContext? _context;
  static bool _isListening = false;

  /// Initialize the service with the app's context
  /// Call this from the root widget or main app
  static void initialize(BuildContext context) {
    _context = context;
    if (!_isListening) {
      _setupListener();
      _isListening = true;
    }
  }

  /// Setup global incoming call listener
  static void _setupListener() {
    SocketService.onIncomingCall((callData) {
      print('🔔 Global incoming call notification: $callData');

      if (_context != null && _context!.mounted) {
        _showIncomingCallDialog(callData);
      } else {
        print('⚠️ No context available to show call dialog');
      }
    });
  }

  /// Show incoming call dialog
  static void _showIncomingCallDialog(Map<String, dynamic> callData) {
    if (_context == null || !_context!.mounted) return;

    final String callerName = callData['callerName'] ?? 'Unknown';
    final String callType = callData['callType'] ?? 'audio';
    final String roomId = callData['roomId'] ?? '';
    final int callLogId = callData['callLogId'] ?? 0;
    final int callerId = callData['callerId'] ?? 0;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false, // Prevent dismissing by back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call icon with animation
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E807F).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  callType == 'video' ? Icons.videocam : Icons.phone,
                  size: 40,
                  color: const Color(0xFF0E807F),
                ),
              ),

              const SizedBox(height: 20),

              // Caller name
              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Call type
              Text(
                'Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _declineCall(callerId, callLogId);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.call_end),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Accept button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _acceptCall(callerId, callLogId, roomId, callerName, callType);
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        callType == 'video' ? Icons.videocam : Icons.call,
                      ),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decline the call
  static void _declineCall(int callerId, int callLogId) {
    SocketService.respondToCall(
      callerId: callerId,
      accepted: false,
      callLogId: callLogId,
    );
    print('❌ Call declined, callLogId: $callLogId');
  }

  /// Accept the call and navigate to call screen
  static Future<void> _acceptCall(
    int callerId,
    int callLogId,
    String roomId,
    String callerName,
    String callType,
  ) async {
    print('🎯 Accepting call from $callerName, type: $callType, roomId: $roomId');

    // Send acceptance via Socket.io
    SocketService.respondToCall(
      callerId: callerId,
      accepted: true,
      callLogId: callLogId,
    );

    print('📞 Response sent, getting user details...');

    // Get user name
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? prefs.getString('doctor_name') ?? 'User';

    print('👤 User name: $userName');

    // Save context before async gap
    final context = _context;

    print('🧭 Context available: ${context != null}, mounted: ${context?.mounted}');

    // Navigate to Agora call screen
    if (context != null && context.mounted) {
      try {
        print('🚀 Navigating to Agora screen...');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgoraVideoCallScreen(
              channelName: roomId,
              userName: userName,
              otherUserName: callerName,
              isVideoEnabled: callType == 'video',
            ),
          ),
        );
        print('✅ Navigation completed');
      } catch (e) {
        print('❌ Navigation error: $e');
      }
    } else {
      print('❌ Cannot navigate - context not available or not mounted');
    }
  }

  /// Dispose the service
  static void dispose() {
    _context = null;
    _isListening = false;
  }
}
