class UserModel {
  final String id;
  final String email;
  final String name;
  final bool biometricEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.biometricEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      biometricEnabled: json['biometricEnabled'] ?? false,
    );
  }
}
