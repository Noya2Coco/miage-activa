class UserProfile {
  const UserProfile({
    required this.login,
    this.birthday = '',
    this.address = '',
    this.postalCode = '',
    this.city = '',
  });

  final String login;
  final String birthday;
  final String address;
  final String postalCode;
  final String city;

  factory UserProfile.fromMap(String login, Map<String, dynamic>? data) {
    return UserProfile(
      login: login,
      birthday: data?['birthday'] as String? ?? '',
      address: data?['address'] as String? ?? '',
      postalCode: data?['postalCode'] as String? ?? '',
      city: data?['city'] as String? ?? '',
    );
  }

  Map<String, String> toMap() => {
    'birthday': birthday,
    'address': address,
    'postalCode': postalCode,
    'city': city,
  };
}
