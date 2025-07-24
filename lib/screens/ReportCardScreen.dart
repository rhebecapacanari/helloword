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
  Map<String, List<String>> _classStudents =
      {}; 
  Map<String, Map<String, String>> _attendance =
      {}; 


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


  
  Future<void> _loadStudentData(String studentId) async {
    setState(() => _isLoading = true);
    try {
      final scheduleService = ScheduleService();


      
      final classes = await scheduleService.getStudentEnrolledClasses(
        studentId,
      );


      Map<String, List<String>> classStudentsMap =
          {}; 
      Map<String, Map<String, String>> attendanceMap =
          {}; 


      for (var classSchedule in classes) {
        print("Carregando aulas para o aluno com ID: ${classSchedule.id}");


        
        final studentNames = await _getStudentNamesByClassId(classSchedule.id);
        classStudentsMap[classSchedule.id] = studentNames;


        
        attendanceMap[classSchedule.id] = {
          for (var student in studentNames) student: 'A',
        };


        
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


  
  Future<void> _loadTeacherData(String teacherId) async {
    setState(() => _isLoading = true);
    try {
      final scheduleService = ScheduleService();
      final classes = await scheduleService.getTeacherSchedules(teacherId);


      Map<String, List<String>> classStudentsMap =
          {}; 
      Map<String, Map<String, String>> attendanceMap =
          {}; 


      for (var classSchedule in classes) {
        print("Carregando alunos para a aula com ID: ${classSchedule.id}");


        
        final studentNames = await _getStudentNamesByClassId(classSchedule.id);
        classStudentsMap[classSchedule.id] = studentNames;


        
        attendanceMap[classSchedule.id] = {
          for (var student in studentNames) student: 'A',
        };


        
        print(
          "Alunos carregados para a aula ${classSchedule.id}: $studentNames",
        );
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


  
  Future<List<String>> _getStudentNamesByClassId(String classId) async {
    final db = await _db.database;


    
    final enrollments = await db.query(
      'class_enrollments',
      where: 'classId = ? AND status = ?',
      whereArgs: [classId, 'active'],
    );


    if (enrollments.isEmpty) {
      print("Nenhum aluno matriculado nesta aula.");
      return [];
    }


    final studentIds = enrollments
        .map((e) => e['studentId'].toString())
        .toList();


    
    print("IDs de alunos extraídos para a aula $classId: $studentIds");


    
    final result = await db.rawQuery('''
      SELECT u.name FROM users u
      WHERE u.id IN (${List.filled(studentIds.length, '?').join(',')})
    ''', studentIds);


    
    print("Resultado da consulta de alunos para a aula $classId: $result");


    
    if (result.isEmpty) {
      print("Nenhum nome de aluno encontrado na consulta SQL.");
    }


    
    return result.map((map) => map['name'] as String).toList();
  }


  
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
      backgroundColor: const Color.fromARGB(
        255,
        166,
        116,
        150,
      ), 
      appBar: AppBar(
        title: const Text(
          'Report Card',
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        elevation: 0, 
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), 
      ),
      body: ListView(
        padding: const EdgeInsets.all(12), 
        children: [
          for (var classSchedule in _teacherClasses) ...[
            Text(
              'Class: ${classSchedule.className} - ${DateFormat('dd/MM/yyyy').format(classSchedule.date)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white, 
              ),
            ),
            const SizedBox(height: 8),
            _classStudents[classSchedule.id]?.isEmpty ?? true
                ? const Center(
                    child: Text(
                      'Nenhum aluno matriculado.',
                      style: TextStyle(color: Colors.white), 
                    ),
                  )
                : DataTable(
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Student',
                          style: TextStyle(color: Colors.white), 
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Attendance',
                          style: TextStyle(color: Colors.white), 
                        ),
                      ),
                    ],
                    rows:
                        _classStudents[classSchedule.id]?.map((studentName) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ), 
                                ),
                              ),
                              widget.user.type == 'teacher'
                                  ? DataCell(
                                      DropdownButton<String>(
                                        value:
                                            _attendance[classSchedule
                                                .id]![studentName],
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'A',
                                            child: Text(
                                              'A - Ausente',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ), 
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'P',
                                            child: Text(
                                              'P - Presente',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ), 
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            _updateAttendance(
                                              classSchedule.id,
                                              studentName,
                                              value,
                                            );
                                          }
                                        },
                                        dropdownColor: const Color.fromARGB(
                                          255,
                                          200,
                                          70,
                                          110,
                                        ), 
                                      ),
                                    )
                                  : DataCell(
                                      Text(
                                        _attendance[classSchedule
                                                .id]![studentName] ??
                                            'A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ), 
                                      ),
                                    ),
                            ],
                          );
                        }).toList() ??
                        [],
                  ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}



