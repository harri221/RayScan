class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'createdAt': createdAt,
    };
  }
}

class AuthResponse {
  final String message;
  final User user;
  final String token;

  AuthResponse({
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'token': token,
    };
  }
}

class ApiResponse {
  final String message;
  final String? error;

  ApiResponse({
    required this.message,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      message: json['message'] as String,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'error': error,
    };
  }
}