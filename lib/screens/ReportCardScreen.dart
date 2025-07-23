import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/schedule_service.dart';

class ReportCardScreen extends StatefulWidget {
  final User user;

  const ReportCardScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ReportCardScreenState createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  bool _isLoading = true;
  List<ClassSchedule> _teacherClasses = [];
  Map<String, List<String>> _classStudents = {}; // Lista de alunos por ID da aula
  Map<String, Map<String, String>> _attendance = {}; // Armazena presença de cada aluno

  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.user.type == 'teacher') {
      _loadTeacherData(widget.user.id.toString());
    } else if (widget.user.type == 'student') {
      _loadStudentData(widget.user.id.toString());
    }
  }

  // Função para carregar os dados do aluno
  Future<void> _loadStudentData(String studentId) async {
    setState(() => _isLoading = true);
    try {
      final scheduleService = ScheduleService();

      // Buscando as aulas do aluno, você já tem a função getStudentEnrolledClasses para isso
      final classes = await scheduleService.getStudentEnrolledClasses(studentId);

      Map<String, List<String>> classStudentsMap = {}; // Mapeia os alunos para cada aula
      Map<String, Map<String, String>> attendanceMap = {}; // Mapeia as presenças para cada aula

      for (var classSchedule in classes) {
        print("Carregando aulas para o aluno com ID: ${classSchedule.id}");

        // Consultar e mapear os nomes dos alunos para a aula
        final studentNames = await _getStudentNamesByClassId(classSchedule.id);
        classStudentsMap[classSchedule.id] = studentNames;

        // Inicializa a presença como 'A' (ausente) por padrão
        attendanceMap[classSchedule.id] = {for (var student in studentNames) student: 'A'};

        // Adicionar um log para verificar os resultados da consulta
        print("Aulas carregadas para o aluno ${studentId}: $studentNames");
      }

      setState(() {
        _teacherClasses = classes;
        _classStudents = classStudentsMap;
        _attendance = attendanceMap;
      });
    } catch (e) {
      print('Erro ao carregar dados do aluno: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados do aluno')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para carregar os dados do professor
  Future<void> _loadTeacherData(String teacherId) async {
    setState(() => _isLoading = true);
    try {
      final scheduleService = ScheduleService();
      final classes = await scheduleService.getTeacherSchedules(teacherId);

      Map<String, List<String>> classStudentsMap = {}; // Mapeia os alunos para cada aula
      Map<String, Map<String, String>> attendanceMap = {}; // Mapeia as presenças para cada aula

      for (var classSchedule in classes) {
        print("Carregando alunos para a aula com ID: ${classSchedule.id}");

        // Consultar e mapear os nomes dos alunos para a aula
        final studentNames = await _getStudentNamesByClassId(classSchedule.id);
        classStudentsMap[classSchedule.id] = studentNames;

        // Inicializa a presença como 'A' (ausente) por padrão
        attendanceMap[classSchedule.id] = {for (var student in studentNames) student: 'A'};

        // Adicionar um log para verificar os resultados da consulta
        print("Alunos carregados para a aula ${classSchedule.id}: $studentNames");
      }

      setState(() {
        _teacherClasses = classes;
        _classStudents = classStudentsMap;
        _attendance = attendanceMap;
      });
    } catch (e) {
      print('Erro ao carregar dados do professor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados do professor')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para buscar os alunos e seus nomes a partir do ID da aula
  Future<List<String>> _getStudentNamesByClassId(String classId) async {
    final db = await _db.database;

    // Consultar os alunos matriculados nesta aula
    final enrollments = await db.query(
      'class_enrollments',
      where: 'classId = ? AND status = ?',
      whereArgs: [classId, 'active'],
    );

    if (enrollments.isEmpty) {
      print("Nenhum aluno matriculado nesta aula.");
      return [];
    }

    final studentIds = enrollments.map((e) => e['studentId'].toString()).toList();

    // Log de diagnóstico: Verificando os IDs dos alunos
    print("IDs de alunos extraídos para a aula $classId: $studentIds");

    // Realizar a consulta para buscar os nomes dos alunos com base nos IDs extraídos
    final result = await db.rawQuery(''' 
      SELECT u.name FROM users u 
      WHERE u.id IN (${List.filled(studentIds.length, '?').join(',')})
    ''', studentIds);

    // Log de diagnóstico: Verificando se os dados dos alunos foram carregados
    print("Resultado da consulta de alunos para a aula $classId: $result");

    // Se a consulta falhar, adicione uma verificação
    if (result.isEmpty) {
      print("Nenhum nome de aluno encontrado na consulta SQL.");
    }

    // Retorna os nomes dos alunos
    return result.map((map) => map['name'] as String).toList();
  }

  // Função para atualizar a presença do aluno
  void _updateAttendance(String classId, String studentName, String value) {
    setState(() {
      _attendance[classId]![studentName] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório de Notas')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var classSchedule in _teacherClasses) ...[
            Text(
              'Aula: ${classSchedule.className} - ${DateFormat('dd/MM/yyyy').format(classSchedule.date)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _classStudents[classSchedule.id]?.isEmpty ?? true
                ? const Center(child: Text('Nenhum aluno matriculado.'))
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Aluno')),
                      DataColumn(label: Text('Presença')),
                      DataColumn(label: Text('Nota')),
                    ],
                    rows: _classStudents[classSchedule.id]?.map((studentName) {
                      return DataRow(cells: [
                        DataCell(Text(studentName)), // Exibe o nome do aluno
                        // Para o professor, exibe o dropdown para selecionar a presença
                        widget.user.type == 'teacher'
                            ? DataCell(
                                DropdownButton<String>(
                                  value: _attendance[classSchedule.id]![studentName],
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'A',
                                      child: Text('A - Ausente'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'P',
                                      child: Text('P - Presente'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _updateAttendance(classSchedule.id, studentName, value);
                                    }
                                  },
                                ),
                              )
                            : DataCell(Text(_attendance[classSchedule.id]![studentName] ?? 'A')), // Para o aluno, mostra a presença como "A" ou "P"
                        DataCell(
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: '', // Implementar a nota
                              onChanged: (val) {
                                // Lógica para alterar a nota
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                        ),
                      ]);
                    }).toList() ?? [],
                  ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
