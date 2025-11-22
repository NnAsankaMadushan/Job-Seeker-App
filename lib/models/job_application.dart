class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String? applicantImage;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    this.applicantImage,
    required this.message,
    required this.status,
    required this.appliedAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      applicantId: json['applicantId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantImage: json['applicantImage'],
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      appliedAt: _parseDate(json['appliedAt']),
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
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantImage': applicantImage,
      'message': message,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  bool isPending() => status == 'pending';
  bool isAccepted() => status == 'accepted';
  bool isRejected() => status == 'rejected';
}
