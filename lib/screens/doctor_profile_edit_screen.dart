import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/doctor_profile_service.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _specializationController = TextEditingController();

  File? _profileImage;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await DoctorProfileService.getDoctorProfile();
      final doctor = profile['doctor'];

      if (!mounted) return;

      setState(() {
        _bioController.text = doctor['bio'] ?? '';
        _qualificationController.text = doctor['qualification'] ?? '';
        _experienceController.text = doctor['experienceYears']?.toString() ?? '0';
        _consultationFeeController.text = doctor['consultationFee']?.toString() ?? '0';
        _clinicAddressController.text = doctor['clinicAddress'] ?? '';
        _clinicPhoneController.text = doctor['clinicPhone'] ?? '';
        _specializationController.text = doctor['specialization'] ?? '';
        _currentProfileImageUrl = doctor['profileImage'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() => _isLoading = true);
    try {
      await DoctorProfileService.uploadProfileImage(_profileImage!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
      await _loadDoctorProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Upload image first if selected
      if (_profileImage != null) {
        await _uploadProfileImage();
      }

      // Update profile
      await DoctorProfileService.updateDoctorProfile(
        bio: _bioController.text.trim(),
        qualification: _qualificationController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()),
        consultationFee: double.tryParse(_consultationFeeController.text.trim()),
        clinicAddress: _clinicAddressController.text.trim(),
        clinicPhone: _clinicPhoneController.text.trim(),
        specialization: _specializationController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF0E807F).withValues(alpha: 0.1),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : _currentProfileImageUrl != null
                                    ? NetworkImage(_currentProfileImageUrl!)
                                    : null,
                            child: _profileImage == null && _currentProfileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF0E807F),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0E807F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Tap to change profile picture',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),

                    const SizedBox(height: 24),

                    // Specialization
                    _buildTextField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.medical_services,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter specialization';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Qualification
                    _buildTextField(
                      controller: _qualificationController,
                      label: 'Qualification',
                      icon: Icons.school,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter qualification';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Experience Years
                    _buildTextField(
                      controller: _experienceController,
                      label: 'Years of Experience',
                      icon: Icons.work,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter years of experience';
                        }
                        final years = int.tryParse(value!);
                        if (years == null || years < 0) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Consultation Fee
                    _buildTextField(
                      controller: _consultationFeeController,
                      label: 'Consultation Fee (PKR)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter consultation fee';
                        }
                        final fee = double.tryParse(value!);
                        if (fee == null || fee < 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Clinic Address
                    _buildTextField(
                      controller: _clinicAddressController,
                      label: 'Clinic Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // Clinic Phone
                    _buildTextField(
                      controller: _clinicPhoneController,
                      label: 'Clinic Phone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'About Me / Bio',
                      icon: Icons.info_outline,
                      maxLines: 4,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your bio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E807F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0E807F)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
