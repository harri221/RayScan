import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/socket_service.dart';
import '../services/chat_service.dart';
import '../services/agora_video_call_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agora_video_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String doctorName;
  final int doctorId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.doctorName,
    required this.doctorId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;
  bool _isTyping = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _setupSocketListeners();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);

      final result = await ChatService.getMessages(
        conversationId: widget.conversationId,
      );

      setState(() {
        _messages = result['messages'];
        _isLoading = false;
      });

      // Join the conversation room via socket
      SocketService.joinConversation(widget.conversationId);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _setupSocketListeners() {
    // Listen for new messages
    SocketService.onNewMessage((message) {
      if (mounted) {
        // Only add message if it's from this conversation
        if (message['conversationId'] == widget.conversationId) {
          setState(() {
            // Check if message already exists
            bool exists = _messages.any((m) => m['id'] == message['id']);
            if (!exists) {
              // Insert at beginning since list is reversed (newest first)
              _messages.insert(0, message);
            }
          });
          _scrollToBottom();
        }
      }
    });

    // Listen for typing indicator
    SocketService.onTyping((data) {
      if (data['userId'] != _currentUserId && mounted) {
        setState(() {
          _isTyping = true;
        });
      }
    });

    // Listen for stop typing
    SocketService.onStopTyping((data) {
      if (data['userId'] != _currentUserId && mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });

    // Listen for incoming calls
    SocketService.onIncomingCall((callData) {
      if (mounted && callData['conversationId'] == widget.conversationId) {
        _showIncomingCallDialog(callData);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      _messageController.clear();

      // Send via socket for real-time
      SocketService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      // Also save via REST API
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      setState(() => _isSending = false);
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        _showAttachmentPreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        _showAttachmentPreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0E807F),
                child: Icon(Icons.image, color: Colors.white),
              ),
              title: const Text('Send Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0E807F),
                child: Icon(Icons.description, color: Colors.white),
              ),
              title: const Text('Send Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentPreview() {
    if (_selectedFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedFile!.path.endsWith('.jpg') ||
                _selectedFile!.path.endsWith('.jpeg') ||
                _selectedFile!.path.endsWith('.png'))
              Image.file(_selectedFile!, height: 200, fit: BoxFit.cover)
            else
              const Icon(Icons.description, size: 100, color: Color(0xFF0E807F)),
            const SizedBox(height: 10),
            Text(
              _selectedFile!.path.split('/').last,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedFile = null);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement file upload to server
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File upload feature coming soon!'),
                  backgroundColor: Color(0xFF0E807F),
                ),
              );
              setState(() => _selectedFile = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E807F),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _onTyping(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'User';

    if (text.isNotEmpty) {
      SocketService.sendTypingStart(widget.conversationId, userName);
    } else {
      SocketService.sendTypingStop(widget.conversationId);
    }
  }

  Future<void> _initiateCall(String callType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'User';

      // Generate unique channel name (using conversation ID for simplicity)
      final channelName = 'rayscan-conv${widget.conversationId}';

      // Notify other user via socket
      SocketService.requestCall(
        targetUserId: widget.doctorId,
        conversationId: widget.conversationId,
        callType: callType,
        callerName: userName,
        roomId: channelName,
      );

      // Navigate to Agora call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgoraVideoCallScreen(
              channelName: channelName,
              userName: userName,
              otherUserName: widget.doctorName,
              isVideoEnabled: callType == 'video',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating call: $e')),
        );
      }
    }
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              callData['callType'] == 'video' ? Icons.videocam : Icons.phone,
              color: const Color(0xFF0E807F),
            ),
            const SizedBox(width: 12),
            const Text('Incoming Call'),
          ],
        ),
        content: Text(
          '${callData['callerName'] ?? widget.doctorName} is calling you...',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Send decline response
              SocketService.respondToCall(
                callerId: callData['callerId'],
                accepted: false,
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.call_end, color: Colors.red),
            label: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Send accept response
              SocketService.respondToCall(
                callerId: callData['callerId'],
                accepted: true,
              );
              Navigator.pop(context);

              // Get user name
              final prefs = await SharedPreferences.getInstance();
              final userName = prefs.getString('user_name') ?? 'User';

              // Navigate to Agora call screen
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgoraVideoCallScreen(
                      channelName: callData['roomId'],
                      userName: userName,
                      otherUserName: callData['callerName'] ?? 'Caller',
                      isVideoEnabled: callData['callType'] == 'video',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService.leaveConversation(widget.conversationId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName),
            if (_isTyping)
              const Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          // Audio Call Button
          IconButton(
            onPressed: () => _initiateCall('audio'),
            icon: const Icon(Icons.phone),
            tooltip: 'Audio Call',
          ),
          // Video Call Button
          IconButton(
            onPressed: () => _initiateCall('video'),
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF0E807F)),
                  onPressed: _showAttachmentOptions,
                  tooltip: 'Attach file',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTyping,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0E807F),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isMe = message['senderId'] == _currentUserId;
    final timestamp = message['createdAt'] != null
        ? DateTime.parse(message['createdAt'])
        : DateTime.now();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0E807F) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
