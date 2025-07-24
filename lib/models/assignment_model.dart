
class Assignment {
  final String id;
  final String? studentId;
  final String? studentName;
  final String teacherId;
  final String classId;
  final String? className;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final DateTime? submissionDate; 
  final DateTime dueDate;
  final String? description;
  final String? feedback;
  final double? grade;
  final bool isGraded;
  final String assignmentTitle;
  final bool isOpen;
  final String? correctionImagePath; 

  Assignment({
    required this.id,
    this.studentId,
    this.studentName,
    required this.teacherId,
    required this.classId,
    this.className,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.submissionDate,
    required this.dueDate,
    this.description,
    this.feedback,
    this.grade,
    this.isGraded = false,
    required this.assignmentTitle,
    this.isOpen = true,
    this.correctionImagePath, 
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
      'submissionDate': submissionDate?.toIso8601String(), 
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'feedback': feedback,
      'grade': grade,
      'isGraded': isGraded ? 1 : 0, 
      'assignmentTitle': assignmentTitle,
      'isOpen': isOpen ? 1 : 0, 
      'correctionImagePath': correctionImagePath, 
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] ?? '',
      studentId: map['studentId'],
      studentName: map['studentName'],
      teacherId: map['teacherId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      submissionDate: map['submissionDate'] != null ? DateTime.parse(map['submissionDate']) : null,
      dueDate: DateTime.parse(map['dueDate']),
      description: map['description'],
      feedback: map['feedback'],
      grade: map['grade'] != null ? map['grade'].toDouble() : null,
      isGraded: map['isGraded'] == 1, 
      assignmentTitle: map['assignmentTitle'] ?? '',
      isOpen: map['isOpen'] == 1, 
      correctionImagePath: map['correctionImagePath'], 
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
    bool? isOpen,
    String? correctionImagePath, 
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
      isOpen: isOpen ?? this.isOpen,
      correctionImagePath: correctionImagePath ?? this.correctionImagePath, 
    );
  }

  
  bool get isLate {
    
    if (submissionDate == null) return false;
    return submissionDate!.isAfter(dueDate);
  }

  
  String get status {
    if (isGraded) return 'Avaliado';
    if (studentId != null && isLate) return 'Atrasado'; 
    if (studentId != null) return 'Pendente de Avaliação'; 
    if (isOpen) return 'Atividade Aberta'; 
    return 'Atividade Fechada'; 
  }

  @override
  String toString() {
    return 'Assignment(id: $id, student: $studentName, class: $className, title: $assignmentTitle, grade: ${grade ?? "N/A"}, status: $status, isOpen: $isOpen)';
  }
}