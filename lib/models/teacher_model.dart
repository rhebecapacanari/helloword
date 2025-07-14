import 'user_model.dart';


class Teacher extends User {
  final List<String> classes;


  Teacher({
    required int? id,
    required String name,
    required String phone,
    required String email,
    required String password,
    bool isApproved = false,
    required this.classes,
  }) : super(
         id: id,
         name: name,
         phone: phone,
         email: email,
         password: password,
         type: 'teacher',
         isApproved: isApproved,
       );


  @override
  Map<String, dynamic> toMap() {
    return super.toMap();
  }


  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      classes: List<String>.from(map['classes'] ?? []),
      password: map['password'],
      isApproved: map['isApproved'] == 1,
    );
  }
}



