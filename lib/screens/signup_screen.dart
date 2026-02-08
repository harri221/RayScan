import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, this.userType = 'patient'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _attemptedSubmit = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
           _emailController.text.trim().isNotEmpty &&
           _passwordController.text.trim().isNotEmpty &&
           _agreeToTerms;
  }

  Future<void> _signupUser() async {
    setState(() {
      _attemptedSubmit = true;
    });

    if (!_isFormValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success checkmark
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E807F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF0E807F),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account has been successfully registered',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E807F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Login',
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
      },
    );
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
        title: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0E807F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
                errorText: _attemptedSubmit && _nameController.text.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0E807F)),
                suffixIcon: _emailController.text.trim().isNotEmpty &&
                           _emailController.text.contains('@')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
                errorText: _attemptedSubmit && _emailController.text.trim().isEmpty
                    ? 'Email is required'
                    : _attemptedSubmit &&
                      _emailController.text.trim().isNotEmpty &&
                      !_emailController.text.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0E807F)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
                errorText: _attemptedSubmit && _passwordController.text.trim().isEmpty
                    ? 'Password is required'
                    : _attemptedSubmit &&
                      _passwordController.text.trim().isNotEmpty &&
                      _passwordController.text.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Terms and conditions checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF0E807F),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the medicos ',
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            color: Color(0xFF0E807F),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showTermsDialog(context);
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Color(0xFF0E807F),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showPrivacyDialog(context);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_attemptedSubmit && !_agreeToTerms)
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  'Please agree to the terms and conditions',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 30),

            // Sign Up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signupUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color(0xFF0E807F)
                      : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Login link
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Don\'t have an account? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: Color(0xFF0E807F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Terms of Service',
            style: TextStyle(
              color: Color(0xFF0E807F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'By using RayScan, you agree to these Terms of Service. If you do not agree, please do not use our services.',
                ),
                SizedBox(height: 16),
                Text(
                  '2. Medical Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'RayScan provides AI-assisted analysis for informational purposes only. Results should not replace professional medical advice. Always consult with qualified healthcare providers.',
                ),
                SizedBox(height: 16),
                Text(
                  '3. User Responsibilities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'You are responsible for maintaining the confidentiality of your account and for all activities under your account. Notify us immediately of any unauthorized use.',
                ),
                SizedBox(height: 16),
                Text(
                  '4. Data Usage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Uploaded medical images are processed securely and may be used anonymously to improve our AI models. You retain ownership of your data.',
                ),
                SizedBox(height: 16),
                Text(
                  '5. Service Availability',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We strive to maintain 24/7 availability but do not guarantee uninterrupted service. We may modify or discontinue features with notice.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF0E807F)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Privacy Policy',
            style: TextStyle(
              color: Color(0xFF0E807F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Information We Collect',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We collect personal information (name, email, phone), medical images, appointment data, and usage analytics to provide our services.',
                ),
                SizedBox(height: 16),
                Text(
                  '2. How We Use Your Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your data is used to: provide medical analysis, connect you with doctors, improve our AI models, send notifications, and ensure service security.',
                ),
                SizedBox(height: 16),
                Text(
                  '3. Data Security',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We use industry-standard encryption, secure cloud storage, regular security audits, and comply with healthcare data protection regulations (HIPAA-compliant).',
                ),
                SizedBox(height: 16),
                Text(
                  '4. Data Sharing',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your medical data is shared only with doctors you consult. We never sell your personal information. Anonymous data may be used for research.',
                ),
                SizedBox(height: 16),
                Text(
                  '5. Your Rights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'You can: access your data, request corrections, delete your account, opt-out of analytics, and export your medical records at any time.',
                ),
                SizedBox(height: 16),
                Text(
                  '6. Contact Us',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'For privacy concerns, email: privacy@rayscan.com or call: +92 300 1234567',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF0E807F)),
              ),
            ),
          ],
        );
      },
    );
  }
}