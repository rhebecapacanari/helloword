import '../models/class_model.dart';
import '../models/enrollment_model.dart';
import 'database_service.dart';


class EnrollmentService {
  final DatabaseService _databaseService = DatabaseService();


  Future<bool> enrollStudentInClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      final enrollment = ClassEnrollment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        classId: classId,
        studentId: studentId,
        enrollmentDate: DateTime.now(),
        status: 'active',
      );
      await _databaseService.enrollStudent(enrollment);
      return true;
    } catch (e) {
      throw Exception('Falha na matrícula: $e');
    }
  }


  Future<bool> cancelEnrollment(String enrollmentId) async {
    try {
      return await _databaseService.cancelEnrollment(enrollmentId);
    } catch (e) {
      throw Exception('Falha ao cancelar matrícula: $e');
    }
  }


  Future<List<ClassSchedule>> getAvailableClasses(String studentId) async {
    try {
      return await _databaseService.getAvailableClassesForStudent(studentId);
    } catch (e) {
      throw Exception('Falha ao carregar aulas disponíveis: $e');
    }
  }


  Future<List<ClassSchedule>> getStudentEnrolledClasses(
    String studentId,
  ) async {
    try {
      return await _databaseService.getStudentEnrolledClasses(studentId);
    } catch (e) {
      throw Exception('Falha ao carregar suas matrículas: $e');
    }
  }


  Future<List<ClassEnrollment>> getStudentEnrollments(String studentId) async {
    try {
      return await _databaseService.getStudentEnrollments(studentId);
    } catch (e) {
      throw Exception('Falha ao carregar matrículas: $e');
    }
  }


  Future<List<ClassEnrollment>> getEnrollmentsByClassAndStudent(
    String classId,
    String studentId,
  ) async {
    try {
      final allEnrollments = await _databaseService.getStudentEnrollments(
        studentId,
      );
      return allEnrollments.where((e) => e.classId == classId).toList();
    } catch (e) {
      throw Exception('Falha ao buscar matrícula específica: $e');
    }
  }

  
}



