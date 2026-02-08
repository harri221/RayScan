import 'package:flutter/material.dart';
import 'consultation_chat.dart';

class DoctorChatListScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorChatListScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Chats')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
              ),
            ),
            title: Text(doctorName),
            subtitle: const Text('Tap to start consultation'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConsultationChatScreen(
                    doctorId: int.tryParse(doctorId) ?? 1,
                    doctorName: doctorName,
                    doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
                    doctorSpecialty: 'Specialist',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
