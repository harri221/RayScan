import 'package:flutter/material.dart';
import 'dart:async';
import 'create_new_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String contactInfo;
  final bool isEmail;

  const VerificationCodeScreen({
    super.key,
    required this.contactInfo,
    required this.isEmail,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  Timer? _timer;
  int _remainingTime = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _remainingTime = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
        timer.cancel();
      }
    });
  }

  void _resendCode() {
    if (_canResend) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent!')),
      );
    }
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    _checkCodeComplete();
  }

  void _checkCodeComplete() {
    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled) {
      _verifyCode();
    }
  }

  void _verifyCode() {
    String code = _controllers.map((controller) => controller.text).join();

    // Simulate verification - in real app, you'd validate with backend
    if (code.length == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateNewPasswordScreen(),
        ),
      );
    }
  }

  String get _maskedContactInfo {
    if (widget.isEmail) {
      final parts = widget.contactInfo.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        if (username.length > 3) {
          return '${username.substring(0, 3)}***@$domain';
        }
      }
    } else {
      if (widget.contactInfo.length > 6) {
        return '${widget.contactInfo.substring(0, 3)}***${widget.contactInfo.substring(widget.contactInfo.length - 4)}';
      }
    }
    return widget.contactInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Enter code that we have sent to your number $_maskedContactInfo',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Code input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0E807F)),
                      ),
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E807F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend code section
            _ResendCodeWidget(
              canResend: _canResend,
              remainingTime: _remainingTime,
              onResend: _resendCode,
            ),

            const Spacer(),

            // Number pad (placeholder)
            Container(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  ...List.generate(9, (index) {
                    final number = index + 1;
                    return _buildNumberKey(number.toString());
                  }),
                  _buildNumberKey('*'),
                  _buildNumberKey('0'),
                  _buildNumberKey('⌫', isBackspace: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberKey(String value, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          // Find the last filled controller and clear it
          for (int i = _controllers.length - 1; i >= 0; i--) {
            if (_controllers[i].text.isNotEmpty) {
              _controllers[i].clear();
              _focusNodes[i].requestFocus();
              break;
            }
          }
        } else if (value != '*') {
          // Find the first empty controller and fill it
          for (int i = 0; i < _controllers.length; i++) {
            if (_controllers[i].text.isEmpty) {
              _controllers[i].text = value;
              if (i < _controllers.length - 1) {
                _focusNodes[i + 1].requestFocus();
              }
              _checkCodeComplete();
              break;
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Separate widget to isolate timer rebuilds from the text fields
class _ResendCodeWidget extends StatelessWidget {
  final bool canResend;
  final int remainingTime;
  final VoidCallback onResend;

  const _ResendCodeWidget({
    required this.canResend,
    required this.remainingTime,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          if (!canResend) ...[
            Text(
              'Resend code in ${remainingTime}s',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Didn\'t receive the code? ',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                GestureDetector(
                  onTap: onResend,
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      color: Color(0xFF0E807F),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}