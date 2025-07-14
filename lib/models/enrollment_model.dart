class ClassEnrollment {
  final String id;
  final String classId;
  final String studentId;
  final DateTime enrollmentDate;
  final String status;


  ClassEnrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.enrollmentDate,
    this.status = 'pending',
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'status': status,
    };
  }


  factory ClassEnrollment.fromMap(Map<String, dynamic> map) {
    return ClassEnrollment(
      id: map['id'],
      classId: map['classId'],
      studentId: map['studentId'],
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
      status: map['status'],
    );
  }
}



