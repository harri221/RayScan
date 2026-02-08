import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  // ============================================================
  // DEPLOYMENT MODE: Match these settings with api_service.dart
  // ============================================================
  static const bool useCloud = true; // Set to true for cloud deployment
  static const bool useRealDevice = true; // Set to false for emulator (when useCloud is false)
  static const String laptopIp = '192.168.1.9'; // Your laptop's IP (when useCloud is false)

  // Cloud backend URL (Replit deployment)
  static const String cloudUrl = 'https://2437fde8-4439-4d07-9a95-0033d9c8ffe7-00-2t0kggkzxvw86.sisko.replit.dev';

  // Get Socket.io server URL
  static String get socketUrl {
    // If using cloud deployment, always use cloud URL
    if (useCloud) {
      return cloudUrl;
    }

    // Local development mode
    if (kIsWeb) {
      return 'http://localhost:3002';
    } else if (Platform.isAndroid) {
      // For physical Android device
      if (useRealDevice) {
        return 'http://$laptopIp:3002';
      }
      // For Android emulator
      return 'http://10.0.2.2:3002';
    } else if (Platform.isIOS) {
      // For physical iOS device
      if (useRealDevice) {
        return 'http://$laptopIp:3002';
      }
      return 'http://localhost:3002';
    } else {
      return 'http://localhost:3002';
    }
  }

  // Initialize and connect to Socket.io
  static Future<void> connect() async {
    if (_socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('No auth token found, cannot connect to socket');
        return;
      }

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(999999)
            .setReconnectionDelay(1000)
            .setAuth({'token': token})
            .build(),
      );

      _socket!.on('connect', (_) async {
        _isConnected = true;
        print('Socket connected: ${_socket!.id}');

        // Authenticate with user ID after connection
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');
        final userType = prefs.getString('user_type') ?? 'user';

        if (userId != null) {
          _socket!.emit('authenticate', {
            'userId': userId,
            'userType': userType,
          });
          print('Authenticated as $userType: $userId');
        }
      });

      _socket!.on('disconnect', (_) {
        _isConnected = false;
        print('Socket disconnected');
      });

      _socket!.on('connect_error', (error) {
        print('Socket connection error: $error');
        _isConnected = false;
      });

      _socket!.connect();
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  // Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('Socket disconnected and disposed');
    }
  }

  // Join a conversation room
  static void joinConversation(int conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_conversation', conversationId);
      print('Joined conversation: $conversationId');
    }
  }

  // Leave a conversation room
  static void leaveConversation(int conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_conversation', conversationId);
      print('Left conversation: $conversationId');
    }
  }

  // Send a message
  static void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send-message', {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
      });
      print('Message sent to conversation $conversationId');
    }
  }

  // Listen for new messages
  static void onNewMessage(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('new_message', (data) {
        print('New message received: $data');
        callback(data as Map<String, dynamic>);
      });
    }
  }

  // Listen for typing indicator
  static void onTyping(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('user_typing', (data) {
        callback(data as Map<String, dynamic>);
      });
    }
  }

  // Listen for stop typing
  static void onStopTyping(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('user_stop_typing', (data) {
        callback(data as Map<String, dynamic>);
      });
    }
  }

  // Send typing indicator
  static void sendTypingStart(int conversationId, String userName) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_start', {
        'conversationId': conversationId,
        'userName': userName,
      });
    }
  }

  // Send stop typing
  static void sendTypingStop(int conversationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing_stop', {
        'conversationId': conversationId,
      });
    }
  }

  // Listen for incoming call
  static void onIncomingCall(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('incoming_call', (data) {
        print('Incoming call: $data');
        callback(data as Map<String, dynamic>);
      });
    }
  }

  // Listen for call response
  static void onCallResponse(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('call_response', (data) {
        print('Call response: $data');
        callback(data as Map<String, dynamic>);
      });
    }
  }

  // Send call request
  static void requestCall({
    required int targetUserId,
    required int conversationId,
    required String callType,
    required String callerName,
    required String roomId,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('call_request', {
        'targetUserId': targetUserId,
        'conversationId': conversationId,
        'callType': callType,
        'callerName': callerName,
        'roomId': roomId,
      });
      print('Call request sent: $callType');
    }
  }

  // Send call response
  static void respondToCall({
    required int callerId,
    required bool accepted,
    int? callLogId,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('call_response', {
        'callerId': callerId,
        'accepted': accepted,
        'callLogId': callLogId,
      });
      print('📞 Call response sent: ${accepted ? "accepted" : "declined"}, callLogId: $callLogId');
    } else {
      print('❌ Cannot send call response - socket not connected');
    }
  }

  // Check if socket is connected
  static bool get isConnected => _isConnected;

  // Get socket instance
  static IO.Socket? get socket => _socket;
}
