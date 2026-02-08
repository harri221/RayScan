import 'package:flutter/material.dart';
import '../models/message.dart';
import 'consultation_chat.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

class MessageHistoryScreen extends StatefulWidget {
  const MessageHistoryScreen({super.key});

  @override
  State<MessageHistoryScreen> createState() => _MessageHistoryScreenState();
}

class _MessageHistoryScreenState extends State<MessageHistoryScreen> {
  int _selectedTab = 0;

  final List<Message> _allMessages = [
    Message(
      id: '1',
      senderId: '1',
      senderName: 'Dr. Marcus Horizon',
      content: 'I don\'t have any fever, but headache...',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: '1',
      doctorName: 'Dr. Marcus Horizon',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
      lastMessage: 'I don\'t have any fever, but headache...',
      timeString: '10:24',
      isUnread: true,
      messageType: MessageType.all,
    ),
    Message(
      id: '2',
      senderId: '2',
      senderName: 'Dr. Alysa Hana',
      content: 'Hello, How can I help you?',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: '2',
      doctorName: 'Dr. Alysa Hana',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
      lastMessage: 'Hello, How can I help you?',
      timeString: '09:04',
      isUnread: false,
      messageType: MessageType.all,
    ),
    Message(
      id: '3',
      senderId: '3',
      senderName: 'Dr. Maria Elena',
      content: 'Do you have fever?',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: '3',
      doctorName: 'Dr. Maria Elena',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
      lastMessage: 'Do you have fever?',
      timeString: '08:57',
      isUnread: false,
      messageType: MessageType.all,
    ),
  ];

  final List<Message> _groupMessages = [
    Message(
      id: 'group_1',
      senderId: 'group_1',
      senderName: 'Cardiology Group',
      content: 'Dr. Smith: Let\'s discuss the case...',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: 'group_1',
      doctorName: 'Cardiology Group',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Gp',
      lastMessage: 'Dr. Smith: Let\'s discuss the case...',
      timeString: '11:30',
      isUnread: true,
      messageType: MessageType.group,
    ),
  ];

  final List<Message> _privateMessages = [
    Message(
      id: '1',
      senderId: '1',
      senderName: 'Dr. Marcus Horizon',
      content: 'I don\'t have any fever, but headache...',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: '1',
      doctorName: 'Dr. Marcus Horizon',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
      lastMessage: 'I don\'t have any fever, but headache...',
      timeString: '10:24',
      isUnread: true,
      messageType: MessageType.private,
    ),
    Message(
      id: '2',
      senderId: '2',
      senderName: 'Dr. Alysa Hana',
      content: 'Hello, How can I help you?',
      timestamp: DateTime.now(),
      isMe: false,
      doctorId: '2',
      doctorName: 'Dr. Alysa Hana',
      doctorImage: 'https://via.placeholder.com/96x96/0E807F/FFFFFF?text=Dr',
      lastMessage: 'Hello, How can I help you?',
      timeString: '09:04',
      isUnread: false,
      messageType: MessageType.private,
    ),
  ];

  List<Message> get _currentMessages {
    switch (_selectedTab) {
      case 0:
        return _allMessages;
      case 1:
        return _groupMessages;
      case 2:
        return _privateMessages;
      default:
        return _allMessages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Message',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search messages')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildTabButton('All', 0),
                _buildTabButton('Group', 1),
                _buildTabButton('Private', 2),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: _currentMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _currentMessages.length,
                    itemBuilder: (context, index) {
                      final message = _currentMessages[index];
                      return _buildMessageTile(message);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start new conversation')),
          );
        },
        backgroundColor: const Color(0xFF0E807F),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0E807F) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(message.doctorImage ?? ''),
        ),
        title: Text(
          message.doctorName ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          message.lastMessage ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.timeString ?? '',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            if (message.isUnread == true)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E807F),
                  shape: BoxShape.circle,
                ),
              ),
            if (message.isUnread == false)
              const Icon(
                Icons.done,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsultationChatScreen(
                doctorId: int.tryParse(message.doctorId ?? '1') ?? 1,
                doctorName: message.doctorName ?? '',
                doctorImage: message.doctorImage,
                doctorSpecialty: 'Specialist', // You can add this to Message model
                onAudioCall: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioCallScreen(
                        doctorName: message.doctorName ?? '',
                        doctorImage: message.doctorImage ?? '',
                      ),
                    ),
                  );
                },
                onVideoCall: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallScreen(
                        doctorName: message.doctorName ?? '',
                        doctorImage: message.doctorImage ?? '',
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}