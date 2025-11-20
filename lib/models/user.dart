class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String userType; // 'Job Seeker' or 'Job Provider'
  final String? location;
  final String? address;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.userType,
    this.location,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      userType: json['userType'] ?? 'Job Seeker',
      location: json['location'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType,
      'location': location,
      'address': address,
    };
  }

  bool isJobSeeker() => userType == 'Job Seeker';
  bool isJobProvider() => userType == 'Job Provider';
}
