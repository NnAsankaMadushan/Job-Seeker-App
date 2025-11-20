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
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : DateTime.now(),
    );
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
