class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String time;
  final double budget;
  final String providerId;
  final String providerName;
  final String status; // 'available', 'in_progress', 'completed', 'cancelled'
  final DateTime createdAt;
  final String? assignedTo;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.budget,
    required this.providerId,
    required this.providerName,
    required this.status,
    required this.createdAt,
    this.assignedTo,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      date: _parseDate(json['date']),
      time: json['time'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      status: json['status'] ?? 'available',
      createdAt: _parseDate(json['createdAt']),
      assignedTo: json['assignedTo'],
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
        // Try to call toDate() method if it exists
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
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'time': time,
      'budget': budget,
      'providerId': providerId,
      'providerName': providerName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'assignedTo': assignedTo,
    };
  }

  bool isAvailable() => status == 'available';
  bool isInProgress() => status == 'in_progress';
  bool isCompleted() => status == 'completed';
}
