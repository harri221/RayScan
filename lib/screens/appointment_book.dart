import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/appointment_service.dart';
import 'payment_success.dart';

class AppointmentBookScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  const AppointmentBookScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<AppointmentBookScreen> createState() => _AppointmentBookScreenState();
}

class _AppointmentBookScreenState extends State<AppointmentBookScreen> {
  final _reasonController = TextEditingController();
  bool _attemptedSubmit = false;
  bool _isBooking = false;

  Future<void> _bookAppointment() async {
    setState(() {
      _attemptedSubmit = true;
      _isBooking = true;
    });

    if (!_reasonController.text.trim().isNotEmpty) {
      setState(() => _isBooking = false);
      return;
    }

    try {
      final formattedDate = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';
      final formattedTime = '${widget.selectedTime.hour.toString().padLeft(2, '0')}:${widget.selectedTime.minute.toString().padLeft(2, '0')}';

      // Check if the time slot is still available before booking
      final isAvailable = await AppointmentService.isTimeSlotAvailable(
        widget.doctor.id,
        formattedDate,
        formattedTime,
      );

      if (!isAvailable) {
        setState(() => _isBooking = false);

        if (mounted) {
          // Show popup dialog for booked slot
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Slot Not Available'),
                  ],
                ),
                content: Text(
                  'Sorry, this time slot (${widget.selectedTime.format(context)}) has already been booked by another patient. Please select a different time slot.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Go back to doctor detail screen
                    },
                    child: const Text('Choose Another Slot'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      await AppointmentService.bookAppointment(
        doctorId: widget.doctor.id,
        appointmentDate: formattedDate,
        appointmentTime: formattedTime,
        reason: _reasonController.text.trim(),
        consultationFee: widget.doctor.consultationFee,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              doctorId: widget.doctor.id.toString(),
              doctorName: widget.doctor.name,
              appointmentDateTime: widget.selectedDate.copyWith(
                hour: widget.selectedTime.hour,
                minute: widget.selectedTime.minute,
              ),
              reason: _reasonController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBooking = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      widget.selectedTime.hour,
      widget.selectedTime.minute,
    );

    final isFormValid = _reasonController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.doctor.specialty,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & Time
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year} | ${widget.selectedTime.format(context)}',
            ),
            const SizedBox(height: 24),

            // Reason
            const Text(
              'Reason',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Describe your symptoms (e.g. chest pain)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            if (_attemptedSubmit && !isFormValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please describe your symptoms',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            const SizedBox(height: 24),

            // Payment
            const Text(
              'Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPaymentDetailRow('Consultation', '\$${(widget.doctor.consultationFee ?? 0).toStringAsFixed(2)}'),
            _buildPaymentDetailRow('Admin Fee', '\$1.00'),
            const Divider(),
            _buildPaymentDetailRow('Total', '\$${((widget.doctor.consultationFee ?? 0) + 1).toStringAsFixed(2)}', isBold: true),
            const SizedBox(height: 24),

            // Confirm Payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid && !_isBooking ? null : Colors.grey,
                ),
                child: _isBooking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Booking...'),
                        ],
                      )
                    : const Text('Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
