class Assignment {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String classId;
  final String className;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime submissionDate;
  final DateTime? dueDate;
  final String? description;
  final String? feedback;
  final double? grade;
  final bool isGraded;
  final String? assignmentTitle;


  Assignment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.classId,
    required this.className,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.submissionDate,
    this.dueDate,
    this.description,
    this.feedback,
    this.grade,
    this.isGraded = false,
    this.assignmentTitle,
  });


  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'classId': classId,
      'className': className,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'submissionDate': submissionDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'description': description,
      'feedback': feedback,
      'grade': grade,
      'isGraded': isGraded,
      'assignmentTitle': assignmentTitle,
    };
  }


  
  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      submissionDate: DateTime.parse(map['submissionDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      description: map['description'],
      feedback: map['feedback'],
      grade: map['grade']?.toDouble(),
      isGraded: map['isGraded'] ?? false,
      assignmentTitle: map['assignmentTitle'],
    );
  }


  
  Assignment copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? classId,
    String? className,
    String? fileUrl,
    String? fileName,
    String? fileType,
    DateTime? submissionDate,
    DateTime? dueDate,
    String? description,
    String? feedback,
    double? grade,
    bool? isGraded,
    String? assignmentTitle,
  }) {
    return Assignment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      submissionDate: submissionDate ?? this.submissionDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      feedback: feedback ?? this.feedback,
      grade: grade ?? this.grade,
      isGraded: isGraded ?? this.isGraded,
      assignmentTitle: assignmentTitle ?? this.assignmentTitle,
    );
  }


  
  bool get isLate {
    if (dueDate == null) return false;
    return submissionDate.isAfter(dueDate!);
  }


  
  String get status {
    if (isGraded) return 'Avaliado';
    if (isLate) return 'Atrasado';
    return 'Pendente';
  }


  @override
  String toString() {
    return 'Assignment(id: $id, student: $studentName, class: $className, grade: ${grade ?? "N/A"}, status: $status)';
  }
}



