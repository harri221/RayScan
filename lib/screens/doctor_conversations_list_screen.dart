import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';

class DoctorConversationsListScreen extends StatefulWidget {
  const DoctorConversationsListScreen({super.key});

  @override
  State<DoctorConversationsListScreen> createState() =>
      _DoctorConversationsListScreenState();
}

class _DoctorConversationsListScreenState
    extends State<DoctorConversationsListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSocketListeners();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final conversations = await ChatService.getDoctorConversations();

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _setupSocketListeners() {
    // Listen for new messages to update conversation list
    SocketService.onNewMessage((message) {
      _loadConversations(); // Refresh list when new message arrives
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
        title: const Text('Patient Messages'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0E807F),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading conversations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E807F),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Patients will appear here when they message you',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: const Color(0xFF0E807F),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    try {
      final patient = conversation['patient'] ?? {};
      final lastMessage = conversation['lastMessage'] ?? {};

      // Safely parse unreadCount as integer
      int unreadCount = 0;
      try {
        final rawUnreadCount = conversation['unreadCount'];
        if (rawUnreadCount is int) {
          unreadCount = rawUnreadCount;
        } else if (rawUnreadCount is String) {
          unreadCount = int.tryParse(rawUnreadCount) ?? 0;
        }
      } catch (e) {
        print('Error parsing unreadCount: $e');
      }

      DateTime? timestamp;
      try {
        if (lastMessage['createdAt'] != null) {
          timestamp = DateTime.parse(lastMessage['createdAt'].toString());
        }
      } catch (e) {
        print('Error parsing timestamp: $e');
      }

      return GestureDetector(
        onTap: () {
          // Safely parse IDs as integers
          final conversationId = conversation['id'] is int
              ? conversation['id']
              : int.tryParse(conversation['id'].toString()) ?? 0;

          final patientId = patient['id'] is int
              ? patient['id']
              : int.tryParse(patient['id'].toString()) ?? 0;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                doctorName: patient['name'] ?? 'Patient',
                doctorId: patientId,
              ),
            ),
          ).then((_) {
            // Refresh conversations when returning from chat
            _loadConversations();
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF0E807F).withOpacity(0.1),
              backgroundImage: patient['profileImage'] != null
                  ? NetworkImage(patient['profileImage'])
                  : null,
              child: patient['profileImage'] == null
                  ? Text(
                      _getInitials(patient['name'] ?? 'Patient'),
                      style: const TextStyle(
                        color: Color(0xFF0E807F),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    patient['name'] ?? 'Patient',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    timeago.format(timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage['content'] ?? 'No messages yet',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E807F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      );
    } catch (e) {
      // Return an error tile instead of crashing
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading conversation',
            style: TextStyle(color: Colors.red[700])),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }
}
