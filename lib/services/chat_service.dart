import 'api_service.dart';

class ChatService {
  // Create or get existing conversation with a doctor
  static Future<Map<String, dynamic>> createConversation({
    required int doctorId,
    String type = 'consultation',
  }) async {
    final response = await ApiService.post('/chat/conversations', {
      'doctorId': doctorId,
      'type': type,
    });
    return response['conversation'];
  }

  // Get all user conversations
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await ApiService.get('/chat/conversations');
    return List<Map<String, dynamic>>.from(response['conversations']);
  }

  // Get all doctor conversations (for doctors only)
  static Future<List<Map<String, dynamic>>> getDoctorConversations() async {
    final response = await ApiService.get('/chat/doctor/conversations');
    return List<Map<String, dynamic>>.from(response['conversations']);
  }

  // Get messages for a specific conversation
  static Future<Map<String, dynamic>> getMessages({
    required int conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiService.get(
      '/chat/conversations/$conversationId/messages?page=$page&limit=$limit',
    );
    return {
      'messages': List<Map<String, dynamic>>.from(response['messages']),
      'pagination': response['pagination'],
    };
  }

  // Send a text message
  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    final response = await ApiService.post(
      '/chat/conversations/$conversationId/messages',
      {
        'content': content,
        'messageType': messageType,
      },
    );
    return response['data'];
  }

  // Send a file message
  static Future<Map<String, dynamic>> sendFileMessage({
    required int conversationId,
    required String filePath,
    String messageType = 'image',
  }) async {
    final response = await ApiService.uploadFile(
      '/chat/conversations/$conversationId/messages/file',
      filePath,
      fileFieldName: 'file',
      additionalData: {
        'messageType': messageType,
      },
    );
    return response['data'];
  }

  // Close a conversation
  static Future<void> closeConversation(int conversationId) async {
    await ApiService.put('/chat/conversations/$conversationId/close', {});
  }

  // Get unread message count
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/chat/unread-count');
    return response['unreadCount'] ?? 0;
  }
}
