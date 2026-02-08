import 'package:flutter/material.dart';
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String doctorName;
  final String doctorImage;

  const VideoCallScreen({
    super.key,
    required this.doctorName,
    required this.doctorImage,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isVideoOn = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Video (Doctor's view)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.doctorImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Top overlay with doctor name and time
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Small video preview (Patient's view)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.grey[800],
                  child: _isVideoOn
                      ? Image.network(
                          'https://img.icons8.com/fluency/96/person-female.png',
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Video toggle
                _buildControlButton(
                  icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                  onPressed: () {
                    setState(() {
                      _isVideoOn = !_isVideoOn;
                    });
                  },
                  backgroundColor: _isVideoOn ? Colors.white.withOpacity(0.3) : Colors.red.withOpacity(0.8),
                ),
                // End call
                _buildControlButton(
                  icon: Icons.call_end,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.red,
                  size: 70,
                ),
                // Mute toggle
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                  backgroundColor: _isMuted ? Colors.red.withOpacity(0.8) : Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
          // Swipe indicator
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Swipe back to menu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white70,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}