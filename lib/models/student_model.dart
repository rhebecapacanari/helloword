import 'user_model.dart';


class Student extends User {
  final String level;
  final DateTime registrationDate;
  final List<String> enrolledClasses;


  Student({
    required int? id,
    required String name,
    required String phone,
    required String email,
    required String password,
    bool isApproved = false,
    required this.level,
    required this.registrationDate,
    this.enrolledClasses = const [],
  }) : super(
         id: id,
         name: name,
         email: email,
         password: password,
         phone: phone,
         type: 'student',
         isApproved: isApproved,
       );


  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'level': level,
      'registrationDate': registrationDate.toIso8601String(),
      'enrolledClasses': enrolledClasses.join(','),
    };
  }


  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      level: map['level'],
      registrationDate: DateTime.parse(map['registrationDate']),
      enrolledClasses: map['enrolledClasses']?.split(',') ?? [],
    );
  }
}



