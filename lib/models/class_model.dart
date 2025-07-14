class ClassSchedule {
  final String id;
  final String teacherId;
  final String dayOfWeek;
  final DateTime date;
  final String startTime;
  final String className;
  final String? description;
  final List<String> classes;


  ClassSchedule({
    required this.id,
    required this.teacherId,
    required this.dayOfWeek,
    required this.date,
    required this.startTime,
    required this.className,
    this.description,
    required this.classes,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'dayOfWeek': dayOfWeek,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'className': className,
      'description': description,
      'classes': classes.join(','),
    };
  }


  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'],
      teacherId: map['teacherId'],
      dayOfWeek: map['dayOfWeek'],
      date: DateTime.parse(map['date']),
      startTime: map['startTime'],
      className: map['className'],
      description: map['description'],
      classes: (map['classes'] as String).split(','),
    );
  }
}



