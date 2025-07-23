import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart'; // Corrigido

class ScheduleService {
  final DatabaseService _databaseService = DatabaseService(); // Corrigido

  // Método para adicionar um horário de aula
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

  // Método para atualizar o horário de aula
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

  // Método para excluir um horário de aula
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

  // Método para buscar as aulas do professor
  Future<List<ClassSchedule>> getTeacherSchedules(String teacherId) async {
    try {
      if (teacherId.isEmpty) {
        throw Exception('ID do professor não pode ser vazio');
      }

      final db = await _databaseService.database; // Correção aqui

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

  // Método para buscar o horário de uma aula por ID
  Future<ClassSchedule?> getClassScheduleById(String classId) async {
    try {
      if (classId.isEmpty) {
        throw Exception('ID do horário não pode ser vazio');
      }

      final db = await _databaseService.database; // Correção aqui
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

  // Método para buscar as aulas em que o aluno está matriculado
  Future<List<ClassSchedule>> getStudentEnrolledClasses(String studentId) async {
    final db = await _databaseService.database; // Correção aqui

    // Buscando as aulas nas quais o aluno está matriculado
    final enrollments = await db.query(
      'class_enrollments',
      where: 'studentId = ? AND status = ?',
      whereArgs: [studentId, 'active'],
    );

    if (enrollments.isEmpty) return [];

    // Pegando os IDs das aulas em que o aluno está matriculado
    final classIds = enrollments.map((e) => e['classId']).toList();

    // Buscando os detalhes dessas aulas
    final classes = await db.query(
      'class_schedules',
      where: 'id IN (${List.filled(classIds.length, '?').join(',')})',
      whereArgs: classIds,
    );

    return classes.map((map) => ClassSchedule.fromMap(map)).toList();
  }
}
