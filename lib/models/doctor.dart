class Doctor {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String specialty;
  final String? qualification;
  final int experienceYears;
  final double rating;
  final double consultationFee;
  final String? about;
  final String? profileImage;
  final bool isAvailable;
  final String? createdAt;
  final String? distance; // This will be calculated when showing with location

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialty,
    this.qualification,
    required this.experienceYears,
    required this.rating,
    required this.consultationFee,
    this.about,
    this.profileImage,
    required this.isAvailable,
    this.createdAt,
    this.distance,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String,
      qualification: json['qualification'] as String?,
      experienceYears: json['experienceYears'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      about: json['about'] as String?,
      profileImage: json['profileImage'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      distance: json['distance'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'rating': rating,
      'consultationFee': consultationFee,
      'about': about,
      'profileImage': profileImage,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'distance': distance,
    };
  }
}
