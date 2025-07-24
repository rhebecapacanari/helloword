import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../models/enrollment_model.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'english_school.db');
    return await openDatabase(
      path,
      version: 7, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN email TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_schedules(
          id TEXT PRIMARY KEY,
          teacherId TEXT NOT NULL,
          dayOfWeek TEXT NOT NULL,
          date TEXT NOT NULL,
          startTime TEXT NOT NULL,
          className TEXT NOT NULL,
          description TEXT,
          classes TEXT NOT NULL,
          FOREIGN KEY (teacherId) REFERENCES teachers (userId)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_enrollments(
          id TEXT PRIMARY KEY,
          classId TEXT NOT NULL,
          studentId INTEGER NOT NULL, -- Corrigido para INTEGER
          enrollmentDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          FOREIGN KEY (classId) REFERENCES class_schedules(id),
          FOREIGN KEY (studentId) REFERENCES students(userId),
          UNIQUE(classId, studentId)
        )
      ''');
      
      
      
    }

    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_grades(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classId TEXT NOT NULL,
        studentId INTEGER NOT NULL,
        isPresent INTEGER NOT NULL,
        grade TEXT,
        UNIQUE(classId, studentId),
        FOREIGN KEY (classId) REFERENCES class_schedules(id),
        FOREIGN KEY (studentId) REFERENCES students(userId)
      )
    ''');
    }

    if (oldVersion < 7) {
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance_records (
          id TEXT PRIMARY KEY, -- UUID ou timestamp para unicidade
          classId TEXT NOT NULL,
          studentId INTEGER NOT NULL,
          date TEXT NOT NULL, -- Data específica da aula
          status TEXT NOT NULL, -- 'P' para Presente, 'A' para Ausente
          FOREIGN KEY (classId) REFERENCES class_schedules(id),
          FOREIGN KEY (studentId) REFERENCES students(userId)
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT NOT NULL,
        type TEXT NOT NULL,
        isApproved INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
    CREATE TABLE attendance_grades(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      classId TEXT NOT NULL,
      studentId INTEGER NOT NULL,
      isPresent INTEGER NOT NULL,
      grade TEXT,
      UNIQUE(classId, studentId),
      FOREIGN KEY (classId) REFERENCES class_schedules(id),
      FOREIGN KEY (studentId) REFERENCES students(userId)
    )
    ''');

    
    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        classId TEXT NOT NULL,
        studentId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (classId) REFERENCES class_schedules(id),
        FOREIGN KEY (studentId) REFERENCES students(userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE teachers(
        userId INTEGER PRIMARY KEY,
        classes TEXT,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE students(
        userId INTEGER PRIMARY KEY,
        level TEXT NOT NULL,
        registrationDate TEXT,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE class_schedules(
        id TEXT PRIMARY KEY,
        teacherId TEXT NOT NULL,
        dayOfWeek TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        className TEXT NOT NULL,
        description TEXT,
        classes TEXT NOT NULL,
        FOREIGN KEY (teacherId) REFERENCES teachers (userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE class_enrollments(
        id TEXT PRIMARY KEY,
        classId TEXT NOT NULL,
        studentId INTEGER NOT NULL, -- Corrigido para INTEGER
        enrollmentDate TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        FOREIGN KEY (classId) REFERENCES class_schedules(id),
        FOREIGN KEY (studentId) REFERENCES students(userId),
        UNIQUE(classId, studentId)
      )
    ''');

    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assignments (
        id TEXT PRIMARY KEY,
        teacherId TEXT,
        classId TEXT,
        className TEXT,
        assignmentTitle TEXT,
        description TEXT,
        dueDate TEXT,
        fileUrl TEXT,
        fileName TEXT,
        fileType TEXT,
        studentId INTEGER, -- Corrigido para INTEGER
        studentName TEXT,
        submissionDate TEXT,
        status TEXT, -- 'pending', 'submitted', 'late'
        grade REAL,
        feedback TEXT,
        correctionImagePath TEXT,
        isGraded INTEGER, -- 0 for false, 1 for true
        isOpen INTEGER -- 0 for false, 1 for true (para atividades do professor)
      )
    ''');
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('attendance_records'); 
    await db.delete('attendance_grades');
    await db.delete('assignments'); 
    await db.delete('class_enrollments');
    await db.delete('class_schedules');
    await db.delete('teachers');
    await db.delete('students');
    await db.delete('users');
  }

  Future<int> insertClassSchedule(ClassSchedule schedule) async {
    final db = await database;
    return await db.insert(
      'class_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ClassSchedule>> getClassSchedulesByTeacher(
    String teacherId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'class_schedules',
      where: 'teacherId = ?',
      whereArgs: [teacherId],
    );
    return List.generate(maps.length, (i) => ClassSchedule.fromMap(maps[i]));
  }

  Future<int> updateClassSchedule(ClassSchedule schedule) async {
    final db = await database;
    return await db.update(
      'class_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteClassSchedule(String id) async {
    final db = await database;
    return await db.delete('class_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ClassSchedule>> getAllClassSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('class_schedules');
    return List.generate(maps.length, (i) => ClassSchedule.fromMap(maps[i]));
  }

  Future<ClassSchedule?> getClassById(String classId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'class_schedules',
      where: 'id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    return maps.isNotEmpty ? ClassSchedule.fromMap(maps.first) : null;
  }

  Future<int> enrollStudent(ClassEnrollment enrollment) async {
    final db = await database;
    
    return await db.insert(
      'class_enrollments',
      {
        'id': enrollment.id,
        'classId': enrollment.classId,
        'studentId': int.parse(enrollment.studentId), 
        'enrollmentDate': enrollment.enrollmentDate.toIso8601String(),
        'status': enrollment.status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> enrollStudentMat(String classId, String studentId) async {
    final db = await database;
    try {
      await db.insert('class_enrollments', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'classId': classId,
        'studentId': int.parse(studentId), 
        'enrollmentDate': DateTime.now().toIso8601String(),
        'status': 'active',
      });
      return true;
    } catch (e) {
      print('Erro ao matricular aluno: $e');
      return false;
    }
  }

  Future<bool> cancelEnrollment(String enrollmentId) async {
    final db = await database;
    final count = await db.delete(
      'class_enrollments',
      where: 'id = ?',
      whereArgs: [enrollmentId],
    );
    return count > 0;
  }

  Future<List<ClassEnrollment>> getStudentEnrollments(String studentId) async {
    final db = await database;
    final result = await db.query(
      'class_enrollments',
      where: 'studentId = ?',
      whereArgs: [int.parse(studentId)], 
    );
    return result.map((map) => ClassEnrollment.fromMap(map)).toList();
  }

  Future<List<ClassSchedule>> getAvailableClassesForStudent(
    String studentId,
  ) async {
    final db = await database;

    final enrollments = await db.query(
      'class_enrollments',
      where: 'studentId = ? AND status = ?',
      whereArgs: [int.parse(studentId), 'active'], 
      columns: ['classId'],
    );

    final enrolledClassIds = enrollments.map((e) => e['classId']).toList();

    final query = enrolledClassIds.isEmpty
        ? 'SELECT * FROM class_schedules'
        : 'SELECT * FROM class_schedules WHERE id NOT IN (${List.filled(enrolledClassIds.length, '?').join(',')})';

    final result = await db.rawQuery(
      query,
      enrolledClassIds.isEmpty ? [] : enrolledClassIds,
    );

    return result.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<List<ClassSchedule>> getStudentEnrolledClasses(
    String studentId,
  ) async {
    final db = await database;

    final enrollments = await db.query(
      'class_enrollments',
      where: 'studentId = ? AND status = ?',
      whereArgs: [int.parse(studentId), 'active'], 
    );

    if (enrollments.isEmpty) return [];

    final classIds = enrollments.map((e) => e['classId']).toList();

    final classes = await db.query(
      'class_schedules',
      where: 'id IN (${List.filled(classIds.length, '?').join(',')})',
      whereArgs: classIds,
    );

    return classes.map((map) => ClassSchedule.fromMap(map)).toList();
  }

  Future<bool> hasScheduleConflict(
    String studentId,
    ClassSchedule newClass,
  ) async {
    final enrolledClasses = await getStudentEnrolledClasses(studentId);

    for (final enrolledClass in enrolledClasses) {
      if (enrolledClass.date == newClass.date &&
          enrolledClass.startTime == newClass.startTime) {
        return true;
      }
    }
    return false;
  }

  Future<void> updateUser(User user) async {
    final db = await database;

    await db.update(
      'users',
      {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'password': user.password,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return users.isNotEmpty ? users.first : null;
  }

  Future<List<Student>> getStudentsByClassId(String classId) async {
    final db = await database;

    final enrollments = await db.query(
      'class_enrollments',
      where: 'classId = ? AND status = ?',
      whereArgs: [classId, 'active'],
    );

    if (enrollments.isEmpty) return [];

    final studentIds = enrollments.map((e) => e['studentId'] as int).toList();

    final result = await db.rawQuery('''
    SELECT s.*, u.name FROM students s
    INNER JOIN users u ON s.userId = u.id
    WHERE s.userId IN (${List.filled(studentIds.length, '?').join(',')})
  ''', studentIds);

    return result.map((map) => Student.fromMap(map)).toList();
  }

  
  Future<void> upsertAttendanceGrade({
    required String classId,
    required int studentId,
    required bool isPresent,
    required String grade,
  }) async {
    final db = await database;

    int updated = await db.update(
      'attendance_grades',
      {'isPresent': isPresent ? 1 : 0, 'grade': grade},
      where: 'classId = ? AND studentId = ?',
      whereArgs: [classId, studentId],
    );

    if (updated == 0) {
      await db.insert('attendance_grades', {
        'classId': classId,
        'studentId': studentId,
        'isPresent': isPresent ? 1 : 0,
        'grade': grade,
      });
    }
  }

  Future<Map<int, Map<String, dynamic>>> getAttendanceGradesByClass(
    String classId,
  ) async {
    final db = await database;

    final results = await db.query(
      'attendance_grades',
      where: 'classId = ?',
      whereArgs: [classId],
    );

    return {
      for (var row in results)
        row['studentId'] as int: {
          'isPresent': (row['isPresent'] as int) == 1,
          'grade': row['grade'] as String? ?? '',
        },
    };
  }

  Future<Map<String, dynamic>?> getAttendanceGrade({
    required String classId,
    required int studentId,
  }) async {
    final db = await database;

    final result = await db.query(
      'attendance_grades',
      where: 'classId = ? AND studentId = ?',
      whereArgs: [classId, studentId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'isPresent': (row['isPresent'] as int) == 1,
      'grade': row['grade'] as String? ?? '',
    };
  }

  

  Future<void> saveAttendanceRecord({
    required String id,
    required String classId,
    required int studentId,
    required DateTime date,
    required String status,
  }) async {
    final db = await database;
    await db.insert(
      'attendance_records',
      {
        'id': id,
        'classId': classId,
        'studentId': studentId,
        'date': date.toIso8601String(),
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getStudentAttendanceRecords(String studentId, String classId) async {
    final db = await database;
    final records = await db.query(
      'attendance_records',
      where: 'studentId = ? AND classId = ?',
      whereArgs: [int.parse(studentId), classId], 
      orderBy: 'date ASC',
    );
    return records;
  }

  
}