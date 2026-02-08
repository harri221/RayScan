import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'consultation_chat.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _pastAppointments = [];
  bool _isLoadingUpcoming = false;
  bool _isLoadingPast = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingUpcoming = true;
      _isLoadingPast = true;
    });

    try {
      final upcoming = AppointmentService.getUpcomingAppointments();
      final past = AppointmentService.getPastAppointments();

      final results = await Future.wait([upcoming, past]);

      setState(() {
        _upcomingAppointments = results[0];
        _pastAppointments = results[1];
        _isLoadingUpcoming = false;
        _isLoadingPast = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUpcoming = false;
        _isLoadingPast = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your appointment with ${appointment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AppointmentService.cancelAppointment(
          appointment.id,
          reason: 'Cancelled by patient',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully')),
          );
          _loadAppointments(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  void _openChat(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationChatScreen(
          doctorId: appointment.doctorId,
          doctorName: appointment.doctorName,
          doctorImage: appointment.doctorImage,
          doctorSpecialty: appointment.doctorSpecialty,
        ),
      ),
    );
  }

  void _viewAppointmentDetails(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  Future<void> _showRatingDialog(Appointment appointment) async {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Rate Your Experience'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Doctor info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          appointment.doctorImage ??
                              'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.doctorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              appointment.doctorSpecialty,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'How was your experience?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = index + 1;
                          });
                        },
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 36,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(selectedRating),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Comment field
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() {
                          isSubmitting = true;
                        });
                        try {
                          await AppointmentService.submitFeedback(
                            appointmentId: appointment.id,
                            rating: selectedRating,
                            feedback: commentController.text.isNotEmpty
                                ? commentController.text
                                : null,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                                backgroundColor: Color(0xFF0E807F),
                              ),
                            );
                            _loadAppointments(); // Refresh to show rating
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to submit feedback: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E807F),
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUpcomingTab(), _buildPastTab()],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No upcoming appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Book an appointment with a doctor to see it here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
          return _buildAppointmentCard(appointment, isUpcoming: true);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_isLoadingPast) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pastAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No past appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pastAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _pastAppointments[index];
          return _buildAppointmentCard(appointment, isUpcoming: false);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
    Appointment appointment, {
    required bool isUpcoming,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    appointment.doctorImage ??
                        'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.doctorSpecialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(appointment.formattedDate),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(appointment.formattedTime),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '\$${appointment.consultationFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Payment: ${appointment.paymentStatus}',
                  style: TextStyle(
                    fontSize: 12,
                    color: appointment.paymentStatus == 'paid'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Call Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: appointment.doctorPhone != null
                        ? () => _makePhoneCall(appointment.doctorPhone!)
                        : null,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E807F),
                      side: const BorderSide(color: Color(0xFF0E807F)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Chat Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(appointment),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E807F),
                      side: const BorderSide(color: Color(0xFF0E807F)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // View Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewAppointmentDetails(appointment),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E807F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Rate button for completed appointments, Cancel for upcoming
                if (!isUpcoming && appointment.isCompleted)
                  Expanded(
                    child: appointment.hasRating
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Rated ${appointment.feedbackRating}/5',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _showRatingDialog(appointment),
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text('Rate Doctor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (isUpcoming && !appointment.isCancelled)
                          ? () => _cancelAppointment(appointment)
                          : null,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text(isUpcoming ? 'Cancel' : (appointment.isCancelled ? 'Cancelled' : 'Past')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        displayStatus = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        displayStatus = 'Confirmed';
        break;
      case 'completed':
        color = Colors.green;
        displayStatus = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        displayStatus = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            appointment.doctorImage ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(appointment.doctorName)}&background=0E807F&color=fff',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.doctorName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                appointment.doctorSpecialty,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              if (appointment.doctorPhone != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appointment.doctorPhone!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Appointment Details Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Appointment ID', '#${appointment.id}'),
                    _buildDetailRow('Date', appointment.formattedDate),
                    _buildDetailRow('Time', appointment.formattedTime),
                    _buildDetailRow(
                      'Type',
                      appointment.appointmentType ?? 'consultation',
                    ),
                    _buildDetailRow(
                      'Mode',
                      appointment.consultationMode ?? 'video_call',
                    ),
                    _buildDetailRow(
                      'Status',
                      appointment.status,
                      statusColor: _getStatusColor(appointment.status),
                    ),
                    _buildDetailRow('Reason', appointment.reason),
                    if (appointment.notes != null &&
                        appointment.notes!.isNotEmpty)
                      _buildDetailRow('Notes', appointment.notes!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0E807F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Consultation Fee',
                      '\$${appointment.consultationFee.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Payment Status',
                      appointment.paymentStatus,
                      statusColor: _getPaymentStatusColor(
                        appointment.paymentStatus,
                      ),
                    ),
                    _buildDetailRow(
                      'Created',
                      _formatDateTime(appointment.createdAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    if (appointment.doctorPhone != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(appointment.doctorPhone!),
                          icon: const Icon(Icons.phone),
                          label: const Text('Call Doctor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E807F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openChat(context, appointment),
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E807F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E807F),
                      side: const BorderSide(color: Color(0xFF0E807F)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openChat(BuildContext context, Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationChatScreen(
          doctorId: appointment.doctorId,
          doctorName: appointment.doctorName,
          doctorImage: appointment.doctorImage,
          doctorSpecialty: appointment.doctorSpecialty,
        ),
      ),
    );
  }
}
