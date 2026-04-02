class UserRating {
  final String id;
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String raterId;
  final String raterName;
  final int rating;
  final String feedback;
  final DateTime createdAt;

  const UserRating({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.raterId,
    required this.raterName,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'] ?? '',
      applicationId: json['applicationId'] ?? '',
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      raterId: json['raterId'] ?? '',
      raterName: json['raterName'] ?? 'Provider',
      rating: (json['rating'] ?? 0) is num
          ? (json['rating'] as num).round()
          : int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      feedback: json['feedback'] ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Map && dateValue.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        dateValue['_seconds'] * 1000 +
            (dateValue['_nanoseconds'] ?? 0) ~/ 1000000,
      );
    }

    if (dateValue.toString().contains('Timestamp')) {
      try {
        return (dateValue as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    return DateTime.now();
  }
}
