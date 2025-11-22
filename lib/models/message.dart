class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: _parseDate(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }
    // Handle Firestore Timestamp
    if (dateValue is Map && dateValue.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        dateValue['_seconds'] * 1000 + (dateValue['_nanoseconds'] ?? 0) ~/ 1000000,
      );
    }
    // Handle Timestamp object with toDate method
    if (dateValue.toString().contains('Timestamp')) {
      try {
        return (dateValue as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }
    // Handle String
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }
    // Handle DateTime
    if (dateValue is DateTime) {
      return dateValue;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class Conversation {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImage: json['userImage'],
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
