class AppNotification {
  final String id;
  final String userId;
  final String type; // 'job', 'message', 'application', 'system'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data like jobId, applicationId, etc.

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
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
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
