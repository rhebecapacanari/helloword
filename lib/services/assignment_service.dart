import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assignment_model.dart';


class AssignmentService {
  static const String _tableName = 'assignments';
  static Database? _database;


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'assignments.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            studentId TEXT NOT NULL,
            studentName TEXT NOT NULL,
            teacherId TEXT NOT NULL,
            classId TEXT NOT NULL,
            className TEXT NOT NULL,
            fileUrl TEXT NOT NULL,
            fileName TEXT NOT NULL,
            fileType TEXT NOT NULL,
            submissionDate TEXT NOT NULL,
            dueDate TEXT,
            description TEXT,
            feedback TEXT,
            grade REAL,
            isGraded INTEGER DEFAULT 0,
            assignmentTitle TEXT
          )
        ''');
      },
    );
  }


  
  Future<void> addAssignment(Assignment assignment) async {
    final db = await database;
    await db.insert(
      _tableName,
      assignment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  
  Future<List<Assignment>> getStudentAssignments(String studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => Assignment.fromMap(maps[i]));
  }


  
  Future<List<Assignment>> getClassAssignments(String classId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'classId = ?',
      whereArgs: [classId],
    );
    return List.generate(maps.length, (i) => Assignment.fromMap(maps[i]));
  }


  
  Future<List<Assignment>> getPendingAssignments(String teacherId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'teacherId = ? AND isGraded = 0',
      whereArgs: [teacherId],
    );
    return List.generate(maps.length, (i) => Assignment.fromMap(maps[i]));
  }


  
  Future<void> gradeAssignment({
    required String assignmentId,
    required String feedback,
    required double grade,
  }) async {
    final db = await database;
    await db.update(
      _tableName,
      {'feedback': feedback, 'grade': grade, 'isGraded': 1},
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }


  
  Future<void> deleteAssignment(String assignmentId) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [assignmentId]);
  }


  
  Future<void> updateAssignmentFile({
    required String assignmentId,
    required String newFileUrl,
    required String newFileName,
  }) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'fileUrl': newFileUrl,
        'fileName': newFileName,
        'submissionDate': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }


  
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}



