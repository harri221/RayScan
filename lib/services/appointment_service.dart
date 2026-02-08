import '../models/appointment.dart';
import 'api_service.dart';

class AppointmentService {

  // Book a new appointment
  static Future<Appointment> bookAppointment({
    required int doctorId,
    required String appointmentDate,
    required String appointmentTime,
    required String reason,
    double? consultationFee,
  }) async {
    final response = await ApiService.post('/appointments', {
      'doctorId': doctorId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'reason': reason,
      if (consultationFee != null) 'consultationFee': consultationFee,
    });

    return Appointment.fromJson(response['appointment']);
  }

  // Get all user appointments
  static Future<List<Appointment>> getAllAppointments({
    String? status,
    bool? upcoming,
  }) async {
    String endpoint = '/appointments';

    List<String> queryParams = [];
    if (status != null) queryParams.add('status=$status');
    if (upcoming != null) queryParams.add('upcoming=$upcoming');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await ApiService.get(endpoint);
    final appointmentsData = response['appointments'] as List;

    return appointmentsData.map((data) => Appointment.fromJson(data)).toList();
  }

  // Get appointment by ID
  static Future<AppointmentDetail> getAppointmentById(int id) async {
    final response = await ApiService.get('/appointments/$id');
    return AppointmentDetail.fromJson(response['appointment']);
  }

  // Cancel appointment
  static Future<void> cancelAppointment(int id, {String? reason}) async {
    await ApiService.put('/appointments/$id/cancel', {
      if (reason != null) 'reason': reason,
    });
  }

  // Reschedule appointment
  static Future<void> rescheduleAppointment(
    int id, {
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    await ApiService.put('/appointments/$id/reschedule', {
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
    });
  }

  // Update payment status
  static Future<void> updatePaymentStatus(
    int id, {
    required String paymentStatus,
    String? paymentId,
  }) async {
    await ApiService.put('/appointments/$id/payment', {
      'paymentStatus': paymentStatus,
      if (paymentId != null) 'paymentId': paymentId,
    });
  }

  // Get doctor availability for a specific date
  static Future<List<TimeSlot>> getDoctorAvailability(
    int doctorId,
    String date,
  ) async {
    final response = await ApiService.get('/doctors/$doctorId/availability/$date');

    if (response['available'] == false) {
      return [];
    }

    final timeSlotsData = response['timeSlots'] as List;
    return timeSlotsData.map((data) => TimeSlot.fromJson(data)).toList();
  }

  // Check if a specific time slot is available
  static Future<bool> isTimeSlotAvailable(
    int doctorId,
    String date,
    String time,
  ) async {
    try {
      final timeSlots = await getDoctorAvailability(doctorId, date);
      final timeSlot = timeSlots.firstWhere(
        (slot) => slot.time == time,
        orElse: () => TimeSlot(time: time, available: false),
      );
      return timeSlot.available;
    } catch (e) {
      return false;
    }
  }

  // Get upcoming appointments
  static Future<List<Appointment>> getUpcomingAppointments() async {
    return getAllAppointments(upcoming: true);
  }

  // Get past appointments
  static Future<List<Appointment>> getPastAppointments() async {
    final now = DateTime.now();
    final allAppointments = await getAllAppointments();

    return allAppointments.where((appointment) {
      try {
        // appointmentDate is already a full ISO timestamp, so just parse it directly
        final appointmentDateTime = DateTime.parse(appointment.appointmentDate);
        return appointmentDateTime.isBefore(now);
      } catch (e) {
        // If parsing fails, assume it's a future appointment to be safe
        return false;
      }
    }).toList();
  }

  // Get appointments by status
  static Future<List<Appointment>> getAppointmentsByStatus(String status) async {
    return getAllAppointments(status: status);
  }

  // Submit feedback for an appointment
  static Future<Map<String, dynamic>> submitFeedback({
    required int appointmentId,
    required int rating,
    String? feedback,
  }) async {
    final response = await ApiService.post('/appointments/$appointmentId/feedback', {
      'rating': rating,
      if (feedback != null) 'feedback': feedback,
    });
    return response;
  }

  // Get doctor reviews
  static Future<Map<String, dynamic>> getDoctorReviews(int doctorId) async {
    final response = await ApiService.get('/appointments/doctor/$doctorId/reviews');
    return response;
  }
}

class TimeSlot {
  final String time;
  final bool available;

  TimeSlot({
    required this.time,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] as String,
      available: json['available'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'available': available,
    };
  }
}