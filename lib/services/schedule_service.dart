import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart'; 

class ScheduleService {
  final DatabaseService _databaseService = DatabaseService(); 

  
  Future<int> addClassSchedule(ClassSchedule classSchedule) async {
    try {
      final existing = await getClassScheduleById(classSchedule.id);
      if (existing != null) {
        throw Exception('Já existe um horário com este ID');
      }

      if (classSchedule.teacherId.isEmpty) {
        throw Exception('ID do professor não pode ser vazio');
      }

      return await _databaseService.insertClassSchedule(classSchedule);
    } catch (e) {
      throw Exception('Falha ao adicionar horário: ${e.toString()}');
    }
  }

  
  Future<bool> updateClassSchedule(ClassSchedule classSchedule) async {
    try {
      final existing = await getClassScheduleById(classSchedule.id);
      if (existing == null) {
        throw Exception('Horário não encontrado para atualização');
      }

      final rowsAffected = await _databaseService.updateClassSchedule(classSchedule);

      if (rowsAffected == 0) {
        throw Exception('Nenhum registro foi atualizado');
      }

      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Falha ao atualizar horário: ${e.toString()}');
    }
  }

  
  Future<bool> deleteClassSchedule(String classId) async {
    try {
      final existing = await getClassScheduleById(classId);
      if (existing == null) {
        throw Exception('Horário não encontrado para exclusão');
      }

      final rowsAffected = await _databaseService.deleteClassSchedule(classId);

      if (rowsAffected == 0) {
        throw Exception('Nenhum registro foi removido');
      }

      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Falha ao excluir horário: ${e.toString()}');
    }
  }

  
  Future<List<ClassSchedule>> getTeacherSchedules(String teacherId) async {
    try {
      if (teacherId.isEmpty) {
        throw Exception('ID do professor não pode ser vazio');
      }

      final db = await _databaseService.database; 

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='class_schedules'",
      );

      if (tables.isEmpty) {
        throw Exception('Tabela class_schedules não existe');
      }

      return await _databaseService.getClassSchedulesByTeacher(teacherId);
    } catch (e) {
      throw Exception('Falha ao buscar horários: ${e.toString()}');
    }
  }

  
  Future<ClassSchedule?> getClassScheduleById(String classId) async {
    try {
      if (classId.isEmpty) {
        throw Exception('ID do horário não pode ser vazio');
      }

      final db = await _databaseService.database; 
      final List<Map<String, dynamic>> result = await db.query(
        'class_schedules',
        where: 'id = ?',
        whereArgs: [classId],
        limit: 1,
      );

      if (result.isEmpty) return null;

      if (result.first['teacherId'] == null) {
        throw Exception('Dados inválidos retornados do banco');
      }

      return ClassSchedule.fromMap(result.first);
    } catch (e) {
      throw Exception('Falha ao buscar horário: ${e.toString()}');
    }
  }

  
  Future<List<ClassSchedule>> getStudentEnrolledClasses(String studentId) async {
    final db = await _databaseService.database; 

    
    final enrollments = await db.query(
      'class_enrollments',
      where: 'studentId = ? AND status = ?',
      whereArgs: [studentId, 'active'],
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
}
