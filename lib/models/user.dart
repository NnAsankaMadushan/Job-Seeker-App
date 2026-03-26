class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? location;
  final String? address;
  final String? gender;
  final String? dateOfBirth;
  final bool? profileCompleted;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.location,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.profileCompleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      location: json['location'],
      address: json['address'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'],
      profileCompleted: json['profileCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'location': location,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'profileCompleted': profileCompleted,
    };
  }
}
