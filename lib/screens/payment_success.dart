import 'package:flutter/material.dart';
import 'doctor_chat_list.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final DateTime appointmentDateTime;
  final String reason;

  const PaymentSuccessScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDateTime,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Appointment with Dr. $doctorName on '
              '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year} '
              'at ${appointmentDateTime.hour}:${appointmentDateTime.minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text('Reason:'),
            Text(reason, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorChatListScreen(
                        doctorId: doctorId,
                        doctorName: doctorName,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Chat with Doctor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
