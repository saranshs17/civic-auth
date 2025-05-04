class User {
  final String? id;
  final String? name;
  final String? email;
  final String? username;
  final String? profileImage;
  final Map<String, dynamic>? wallet;

  User({
    this.id,
    this.name,
    this.email,
    this.username,
    this.profileImage,
    this.wallet,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      profileImage: json['profileImage'] as String?,
      wallet: json['wallet'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'profileImage': profileImage,
      'wallet': wallet,
    };
  }
}