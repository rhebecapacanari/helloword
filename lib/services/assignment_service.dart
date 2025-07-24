
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'; 

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
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'assignments.db');

    print("AssignmentService: Inicializando o banco de dados em $path");

    return openDatabase(
      path,
      version: 4, 
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            studentId INTEGER, -- Alterado para INTEGER
            studentName TEXT,
            teacherId TEXT NOT NULL,
            classId TEXT NOT NULL,
            className TEXT,
            fileUrl TEXT,
            fileName TEXT,
            fileType TEXT,
            submissionDate TEXT,
            dueDate TEXT NOT NULL,
            description TEXT,
            feedback TEXT,
            grade REAL,
            isGraded INTEGER DEFAULT 0,
            assignmentTitle TEXT NOT NULL,
            isOpen INTEGER DEFAULT 1,
            correctionImagePath TEXT
          )
        ''');
        print("AssignmentService: Tabela $_tableName criada com sucesso.");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE $_tableName ADD COLUMN isOpen INTEGER DEFAULT 1");
          print("AssignmentService: Coluna 'isOpen' adicionada (versão 2).");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE $_tableName ADD COLUMN correctionImagePath TEXT");
          print("AssignmentService: Coluna 'correctionImagePath' adicionada (versão 3).");
        }
        if (oldVersion < 4) {
          
          
          
          
          
          
          
          
          
          
          
          
          
          try {
            
            
            
            await db.execute("CREATE TEMPORARY TABLE temp_assignments AS SELECT * FROM $_tableName");
            await db.execute("DROP TABLE $_tableName");
            await db.execute('''
              CREATE TABLE $_tableName (
                id TEXT PRIMARY KEY,
                studentId INTEGER, -- Alterado para INTEGER
                studentName TEXT,
                teacherId TEXT NOT NULL,
                classId TEXT NOT NULL,
                className TEXT,
                fileUrl TEXT,
                fileName TEXT,
                fileType TEXT,
                submissionDate TEXT,
                dueDate TEXT NOT NULL,
                description TEXT,
                feedback TEXT,
                grade REAL,
                isGraded INTEGER DEFAULT 0,
                assignmentTitle TEXT NOT NULL,
                isOpen INTEGER DEFAULT 1,
                correctionImagePath TEXT
              )
            ''');
            await db.execute("INSERT INTO $_tableName SELECT id, CAST(studentId AS INTEGER), studentName, teacherId, classId, className, fileUrl, fileName, fileType, submissionDate, dueDate, description, feedback, grade, isGraded, assignmentTitle, isOpen, correctionImagePath FROM temp_assignments");
            await db.execute("DROP TABLE temp_assignments");
            print("AssignmentService: Coluna 'studentId' alterada para INTEGER (versão 4).");
          } catch (e) {
            print("AssignmentService: ERRO ao alterar tipo da coluna 'studentId': $e");
            
            
          }
        }
      },
    );
  }

  Future<void> addAssignment(Assignment assignment) async {
    final db = await database;
    
    
    final Map<String, dynamic> mapToInsert = assignment.toMap();

    
    if (assignment.studentId != null) {
      mapToInsert['studentId'] = int.tryParse(assignment.studentId!) ?? null;
    } else {
      mapToInsert['studentId'] = null;
    }

    print("AssignmentService: Tentando inserir/atualizar atividade: $mapToInsert");

    try {
      final existingRecord = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [assignment.id],
        limit: 1,
      );

      if (existingRecord.isNotEmpty) {
        await db.update(
          _tableName,
          mapToInsert, 
          where: 'id = ?',
          whereArgs: [assignment.id],
        );
        print("AssignmentService: Atividade atualizada (ID: ${assignment.id}).");
      } else {
        await db.insert(
          _tableName,
          mapToInsert, 
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("AssignmentService: Nova atividade inserida (ID: ${assignment.id}).");
      }
    } catch (e) {
      print("AssignmentService: ERRO ao inserir/atualizar atividade: $e");
    }
    _printAllAssignmentsInDb(); 
  }

  Future<List<Assignment>> getClassAssignments(String classId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'classId = ?',
      whereArgs: [classId],
    );
    final assignments = List.generate(maps.length, (i) => Assignment.fromMap(maps[i]));
    print("AssignmentService: getClassAssignments para $classId. Encontradas ${assignments.length} atividades.");
    _printAllAssignmentsInDb(); 
    return assignments;
  }

  Future<Assignment?> getOpenAssignment(String classId) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'isOpen = ? AND classId = ? AND studentId IS NULL',
      whereArgs: [1, classId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final assignment = Assignment.fromMap(result.first);
      print("AssignmentService: Atividade aberta do professor encontrada: ${assignment.assignmentTitle} (ID: ${assignment.id}).");
      return assignment;
    }
    print("AssignmentService: Nenhuma atividade aberta do professor encontrada para classId: $classId.");
    return null;
  }

  Future<List<Assignment>> getStudentSubmissionsForOriginalAssignment(String originalAssignmentTitle, String classId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'assignmentTitle = ? AND classId = ? AND studentId IS NOT NULL',
      whereArgs: [originalAssignmentTitle, classId],
    );
    final submissions = maps.map((map) => Assignment.fromMap(map)).toList();
    print("AssignmentService: getStudentSubmissionsForOriginalAssignment para '$originalAssignmentTitle' em $classId. Encontradas ${submissions.length} submissões.");
    return submissions;
  }

  Future<Assignment?> getStudentSubmissionForAssignment(String studentId, String originalAssignmentId) async {
    final db = await database;

    final originalAssignmentResult = await db.query(
      _tableName,
      where: 'id = ? AND studentId IS NULL',
      whereArgs: [originalAssignmentId],
      limit: 1,
    );

    if (originalAssignmentResult.isEmpty) {
      print("AssignmentService: Atividade original do professor com ID $originalAssignmentId não encontrada.");
      return null;
    }

    final originalAssignmentMap = originalAssignmentResult.first;
    final originalTitle = originalAssignmentMap['assignmentTitle'];
    final originalClassId = originalAssignmentMap['classId'];
    final originalTeacherId = originalAssignmentMap['teacherId'];

    final studentSubmissionResult = await db.query(
      _tableName,
      
      where: 'studentId = ? AND assignmentTitle = ? AND classId = ? AND teacherId = ? AND fileUrl IS NOT NULL',
      whereArgs: [int.parse(studentId), originalTitle, originalClassId, originalTeacherId],
      limit: 1,
    );

    if (studentSubmissionResult.isNotEmpty) {
      final submission = Assignment.fromMap(studentSubmissionResult.first);
      print("AssignmentService: Submissão do aluno encontrada para estudante $studentId e atividade original '$originalTitle'.");
      return submission;
    }
    print("AssignmentService: Nenhuma submissão de aluno encontrada para estudante $studentId para a atividade original com ID $originalAssignmentId.");
    return null;
  }

  Future<void> gradeAssignment({
    required String? submissionId,
    required String feedback,
    required double grade,
    String? correctionImagePath,
  }) async {
    final db = await database;
    if (submissionId == null) {
      print("AssignmentService: submissionId é nulo. Não é possível avaliar.");
      return;
    }

    final int rowsAffected = await db.update(
      _tableName,
      {
        'feedback': feedback,
        'grade': grade,
        'isGraded': 1,
        'correctionImagePath': correctionImagePath,
      },
      where: 'id = ?',
      whereArgs: [submissionId],
    );
    if (rowsAffected > 0) {
      print('AssignmentService: Atividade (ID: $submissionId) avaliada com sucesso (nota: $grade).');
    } else {
      print('AssignmentService: Nenhuma submissão encontrada com ID: $submissionId para avaliação.');
    }
    _printAllAssignmentsInDb();
  }

  
  Future<List<Assignment>> getRelevantAssignmentsForStudentInClass(int studentId, String classId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'classId = ? AND (studentId = ? OR studentId IS NULL)',
      whereArgs: [classId, studentId],
      orderBy: 'assignmentTitle ASC, studentId ASC', 
    );

    final List<Assignment> relevantAssignments = [];
    final Map<String, Assignment> finalAssignments = {}; 

    for (var map in maps) {
      final assignment = Assignment.fromMap(map);
      
      if (assignment.studentId != null && int.tryParse(assignment.studentId!) == studentId) {
        finalAssignments[assignment.assignmentTitle!] = assignment;
      } else if (assignment.studentId == null) {
        
        
        if (!finalAssignments.containsKey(assignment.assignmentTitle!)) {
          finalAssignments[assignment.assignmentTitle!] = assignment;
        }
      }
    }
    return finalAssignments.values.toList();
  }


  Future<void> _printAllAssignmentsInDb() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    print('\n--- Conteúdo Atual da Tabela $_tableName ---');
    if (maps.isEmpty) {
      print('A tabela está vazia.');
    } else {
      for (var map in maps) {
        print('   ID: ${map['id']} | Título: ${map['assignmentTitle']} | Turma: ${map['classId']} | Teacher: ${map['teacherId']} | Student: ${map['studentId'] ?? 'N/A'} | Aberta: ${map['isOpen']} | Avaliada: ${map['isGraded']} | Nota: ${map['grade'] ?? 'N/A'} | File: ${map['fileUrl'] != null && (map['fileUrl'] as String).isNotEmpty ? 'YES' : 'NO'} | FeedbackImg: ${map['correctionImagePath'] != null && (map['correctionImagePath'] as String).isNotEmpty ? 'YES' : 'NO'}');
      }
    }
    print('-------------------------------------------\n');
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [assignmentId]);
    print('AssignmentService: Atividade (ID: $assignmentId) deletada.');
    _printAllAssignmentsInDb();
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
    print('AssignmentService: Arquivo de submissão (ID: $assignmentId) atualizado.');
    _printAllAssignmentsInDb();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('AssignmentService: Banco de dados fechado.');
  }
}