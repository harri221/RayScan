import 'package:flutter/material.dart';
import 'verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEmailSelected = true;
  bool _attemptedSubmit = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_isEmailSelected) {
      return _emailController.text.trim().isNotEmpty &&
             _emailController.text.contains('@');
    } else {
      return _phoneController.text.trim().isNotEmpty &&
             _phoneController.text.length >= 10;
    }
  }

  void _resetPassword() {
    setState(() {
      _attemptedSubmit = true;
    });

    if (_isFormValid) {
      final contactInfo = _isEmailSelected
          ? _emailController.text.trim()
          : _phoneController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationCodeScreen(
            contactInfo: contactInfo,
            isEmail: _isEmailSelected,
          ),
        ),
      );
    }
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
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Enter your email or your phone number, we will send you confirmation code',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),

            // Tab selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEmailSelected = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isEmailSelected ? const Color(0xFF0E807F) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isEmailSelected ? Colors.white : Colors.grey[700],
                            fontWeight: _isEmailSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEmailSelected = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isEmailSelected ? const Color(0xFF0E807F) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isEmailSelected ? Colors.white : Colors.grey[700],
                            fontWeight: !_isEmailSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Input field
            if (_isEmailSelected) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0E807F)),
                  suffixIcon: _emailController.text.trim().isNotEmpty &&
                             _emailController.text.contains('@')
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  hintText: 'jamesschleifer@gmail.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  errorText: _attemptedSubmit && !_isFormValid
                      ? 'Please enter a valid email'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0E807F)),
                  hintText: '085281882151',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  errorText: _attemptedSubmit && !_isFormValid
                      ? 'Please enter a valid phone number'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 30),

            // Reset Password button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color(0xFF0E807F)
                      : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}