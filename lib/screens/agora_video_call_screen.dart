import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora_video_call_service.dart';
import 'dart:developer' as dev;

class AgoraVideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userName;
  final String otherUserName;
  final bool isVideoEnabled;

  const AgoraVideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
    required this.otherUserName,
    this.isVideoEnabled = true,
  });

  @override
  State<AgoraVideoCallScreen> createState() => _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends State<AgoraVideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Initialize Agora if not already done
      await AgoraVideoCallService.initialize();

      // Set up event handlers
      _setupEventHandlers();

      // Join the call
      await AgoraVideoCallService.joinCall(
        channelName: widget.channelName,
        isVideoEnabled: widget.isVideoEnabled,
      );

      setState(() {
        _localUserJoined = true;
        _isCameraEnabled = widget.isVideoEnabled;
      });
    } catch (e) {
      dev.log('Error initializing call: $e');
      if (mounted) {
        _showError('Failed to join call: $e');
      }
    }
  }

  void _setupEventHandlers() {
    final engine = AgoraVideoCallService.engine;
    if (engine == null) return;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          dev.log('✅ Local user ${connection.localUid} joined channel successfully');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          dev.log('✅ Remote user $remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
            _isCallConnected = true;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          dev.log('❌ Remote user $remoteUid left channel');
          setState(() {
            _remoteUid = null;
            _isCallConnected = false;
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          dev.log('👋 Left channel');
          setState(() {
            _localUserJoined = false;
            _remoteUid = null;
            _isCallConnected = false;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          dev.log('❌ Agora error: $err - $msg');
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleMicrophone() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    await AgoraVideoCallService.toggleMicrophone(_isMicEnabled);
  }

  Future<void> _toggleCamera() async {
    if (!widget.isVideoEnabled) return;

    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    await AgoraVideoCallService.toggleCamera(_isCameraEnabled);
  }

  Future<void> _switchCamera() async {
    await AgoraVideoCallService.switchCamera();
  }

  Future<void> _endCall() async {
    await AgoraVideoCallService.leaveCall();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (or audio-only placeholder)
          Center(
            child: _remoteVideo(),
          ),

          // Local video preview (top-right corner)
          if (widget.isVideoEnabled && _isCameraEnabled)
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: AgoraVideoCallService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),

          // Call info overlay (top)
          Positioned(
            top: 50,
            left: 16,
            right: 140,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isCallConnected
                        ? (widget.isVideoEnabled ? 'Video Call' : 'Audio Call')
                        : 'Connecting...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control buttons (bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Microphone toggle
                _buildControlButton(
                  icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                  label: _isMicEnabled ? 'Mute' : 'Unmute',
                  onPressed: _toggleMicrophone,
                  backgroundColor: _isMicEnabled ? Colors.white : Colors.red,
                  iconColor: _isMicEnabled ? Colors.black : Colors.white,
                ),

                // Camera toggle (only for video calls)
                if (widget.isVideoEnabled)
                  _buildControlButton(
                    icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                    label: _isCameraEnabled ? 'Camera Off' : 'Camera On',
                    onPressed: _toggleCamera,
                    backgroundColor: _isCameraEnabled ? Colors.white : Colors.red,
                    iconColor: _isCameraEnabled ? Colors.black : Colors.white,
                  ),

                // Switch camera (only for video calls)
                if (widget.isVideoEnabled && _isCameraEnabled)
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    label: 'Switch',
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white,
                    iconColor: Colors.black,
                  ),

                // End call
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'End Call',
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      if (widget.isVideoEnabled) {
        // Show remote video
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: AgoraVideoCallService.engine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        );
      } else {
        // Audio-only call - show avatar
        return _buildAudioOnlyView();
      }
    } else {
      // Waiting for other user
      return _buildWaitingView();
    }
  }

  Widget _buildAudioOnlyView() {
    return Container(
      color: const Color(0xFF0E807F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Color(0xFF0E807F),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Audio Call',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: const Color(0xFF0E807F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Waiting for ${widget.otherUserName}...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
