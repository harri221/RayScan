class Appointment {
  final int id;
  final int userId;
  final int doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorImage;
  final String? doctorPhone;
  final String appointmentDate;
  final String appointmentTime;
  final String? appointmentType;
  final String? consultationMode;
  final String reason;
  final String status;
  final double consultationFee;
  final String paymentStatus;
  final String? paymentId;
  final String? notes;
  final DateTime createdAt;
  final int? feedbackRating;
  final String? feedbackComment;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorImage,
    this.doctorPhone,
    required this.appointmentDate,
    required this.appointmentTime,
    this.appointmentType,
    this.consultationMode,
    required this.reason,
    required this.status,
    required this.consultationFee,
    required this.paymentStatus,
    this.paymentId,
    this.notes,
    required this.createdAt,
    this.feedbackRating,
    this.feedbackComment,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      doctorId: json['doctorId'] as int,
      doctorName: json['doctorName'] as String,
      doctorSpecialty: json['doctorSpecialty'] as String,
      doctorImage: json['doctorImage'] as String?,
      doctorPhone: json['doctorPhone'] as String?,
      appointmentDate: json['appointmentDate'] as String,
      appointmentTime: json['appointmentTime'] as String,
      appointmentType: json['appointmentType'] as String?,
      consultationMode: json['consultationMode'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      paymentId: json['paymentId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      feedbackRating: json['feedbackRating'] as int?,
      feedbackComment: json['feedbackComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorImage': doctorImage,
      'doctorPhone': doctorPhone,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'appointmentType': appointmentType,
      'consultationMode': consultationMode,
      'reason': reason,
      'status': status,
      'consultationFee': consultationFee,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'feedbackRating': feedbackRating,
      'feedbackComment': feedbackComment,
    };
  }

  String get formattedDate {
    final date = DateTime.parse(appointmentDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTime {
    // appointmentTime comes as "10:00:00", so extract just "10:00"
    if (appointmentTime.contains(':')) {
      final parts = appointmentTime.split(':');
      return '${parts[0]}:${parts[1]}';
    }
    return appointmentTime;
  }

  DateTime get dateTime {
    try {
      // appointmentDate is already a full ISO timestamp from the API
      return DateTime.parse(appointmentDate);
    } catch (e) {
      // Fallback: if appointmentDate is just a date, combine with appointmentTime
      return DateTime.parse('${appointmentDate}T$appointmentTime');
    }
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  bool get isPending {
    return status == 'pending';
  }

  bool get isConfirmed {
    return status == 'confirmed';
  }

  bool get hasRating {
    return feedbackRating != null;
  }
}

class AppointmentDetail extends Appointment {
  final String userName;
  final String userPhone;
  final String doctorEmail;
  final DateTime? updatedAt;

  AppointmentDetail({
    required super.id,
    required super.userId,
    required this.userName,
    required this.userPhone,
    required super.doctorId,
    required super.doctorName,
    required super.doctorSpecialty,
    super.doctorImage,
    super.doctorPhone,
    required this.doctorEmail,
    required super.appointmentDate,
    required super.appointmentTime,
    super.appointmentType,
    super.consultationMode,
    required super.reason,
    required super.status,
    required super.consultationFee,
    required super.paymentStatus,
    super.paymentId,
    super.notes,
    required super.createdAt,
    this.updatedAt,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentDetail(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userPhone: json['userPhone'] as String,
      doctorId: json['doctorId'] as int,
      doctorName: json['doctorName'] as String,
      doctorSpecialty: json['doctorSpecialty'] as String,
      doctorImage: json['doctorImage'] as String?,
      doctorPhone: json['doctorPhone'] as String?,
      doctorEmail: json['doctorEmail'] as String,
      appointmentDate: json['appointmentDate'] as String,
      appointmentTime: json['appointmentTime'] as String,
      appointmentType: json['appointmentType'] as String?,
      consultationMode: json['consultationMode'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      consultationFee: (json['consultationFee'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      paymentId: json['paymentId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'userName': userName,
      'userPhone': userPhone,
      'doctorEmail': doctorEmail,
      'updatedAt': updatedAt?.toIso8601String(),
    });
    return json;
  }
}
