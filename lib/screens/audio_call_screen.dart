import 'package:flutter/material.dart';
import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final String doctorName;
  final String doctorImage;

  const AudioCallScreen({
    super.key,
    required this.doctorName,
    required this.doctorImage,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5FB3B1),
              Color(0xFF0E807F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Doctor Avatar
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(widget.doctorImage),
                ),
              ),
              const SizedBox(height: 24),
              // Doctor Name
              Text(
                widget.doctorName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Call Duration
              Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speaker Button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                    backgroundColor: _isSpeakerOn ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                  ),
                  // End Call Button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.red,
                    size: 70,
                  ),
                  // Mute Button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                    backgroundColor: _isMuted ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Swipe back to menu
              const Text(
                'Swipe back to menu',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white70,
                size: 30,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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