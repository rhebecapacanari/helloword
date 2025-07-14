class User {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String type;
  final bool isApproved;


  User({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.type,
    this.isApproved = false,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'type': type,
      'isApproved': isApproved ? 1 : 0,
    };
  }


  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
      type: map['type'],
      isApproved: map['isApproved'] == 1,
    );
  }
}



