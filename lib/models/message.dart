enum MessageType { all, group, private }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  // New properties for message history
  final String? doctorId;
  final String? doctorName;
  final String? doctorImage;
  final String? lastMessage;
  final String? timeString;
  final bool? isUnread;
  final MessageType? messageType;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.doctorId,
    this.doctorName,
    this.doctorImage,
    this.lastMessage,
    this.timeString,
    this.isUnread,
    this.messageType,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}
