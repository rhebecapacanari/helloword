import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/enrollment_service.dart';
import 'student_enrollment_screen.dart';
import 'assignment_upload_screen.dart'; 


class StudentHomeScreen extends StatefulWidget {
  final Student student;


  const StudentHomeScreen({Key? key, required this.student}) : super(key: key);


  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}


class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<ClassSchedule> _enrolledClasses = [];
  bool _isLoading = true;
  String _errorMessage = '';


  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }


  Future<void> _loadEnrolledClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });


    try {
      final classes = await _enrollmentService.getStudentEnrolledClasses(
        widget.student.id.toString(),
      );


      classes.sort((a, b) {
        final dayOrder = {
          'Segunda': 1,
          'Terça': 2,
          'Quarta': 3,
          'Quinta': 4,
          'Sexta': 5,
          'Sábado': 6,
          'Domingo': 7,
        };


        final dayCompare = (dayOrder[a.dayOfWeek] ?? 8).compareTo(
          dayOrder[b.dayOfWeek] ?? 8,
        );
        if (dayCompare != 0) return dayCompare;


        return a.startTime.compareTo(b.startTime);
      });


      setState(() {
        _enrolledClasses = classes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar aulas matriculadas: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _unenrollFromClass(String classId) async {
    setState(() => _isLoading = true);
    try {
      
      final enrollments = await _enrollmentService
          .getEnrollmentsByClassAndStudent(
            classId,
            widget.student.id.toString(),
          );


      if (enrollments.isEmpty) {
        throw Exception('Matrícula não encontrada');
      }


      
      final success = await _enrollmentService.cancelEnrollment(
        enrollments.first.id,
      );


      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desmatrícula realizada com sucesso!')),
        );
        await _loadEnrolledClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao realizar desmatrícula')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  String _formatTime(String time) {
    try {
      final parsedTime = DateFormat('HH:mm').parse(time);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }


  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (Route<dynamic> route) => false,
    );
  }


  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Meu Perfil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: ${widget.student.name}'),
                Text('Email: ${widget.student.email}'),
                Text('Nível: ${widget.student.level}'),
                Text(
                  'Matriculado em: ${DateFormat('dd/MM/yyyy').format(widget.student.registrationDate)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Fechar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }


  
  void _navigateToAssignmentUpload(BuildContext context) {
    if (_enrolledClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não está matriculado em nenhuma aula'),
        ),
      );
      return;
    }


    
    final classItem = _enrolledClasses.first;


    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AssignmentUploadScreen(
              studentId: widget.student.id.toString(),
              studentName: widget.student.name,
              classId: classItem.id,
              className: classItem.className,
              teacherId: classItem.teacherId,
            ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.student.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrolledClasses,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String result) {
              switch (result) {
                case 'logout':
                  _logout(context);
                  break;
                case 'profile':
                  _showProfile(context);
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Meu Perfil'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Sair'),
                  ),
                ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAssignmentUpload(context),
        child: const Icon(Icons.upload_file),
        tooltip: 'Enviar Trabalho',
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Suas Aulas Matriculadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _enrolledClasses.isEmpty
                    ? const Center(
                      child: Text('Você não está matriculado em nenhuma aula'),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Dia')),
                          DataColumn(label: Text('Data')),
                          DataColumn(label: Text('Horário')),
                          DataColumn(label: Text('Aula')),
                          DataColumn(label: Text('Professor')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows:
                            _enrolledClasses.map((classItem) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(classItem.dayOfWeek)),
                                  DataCell(
                                    Text(
                                      '${classItem.date.day}/${classItem.date.month}',
                                    ),
                                  ),
                                  DataCell(
                                    Text(_formatTime(classItem.startTime)),
                                  ),
                                  DataCell(Text(classItem.className)),
                                  DataCell(
                                    FutureBuilder<String>(
                                      future: _getTeacherName(
                                        classItem.teacherId,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        return Text(
                                          snapshot.data ?? 'Professor',
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.exit_to_app,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () =>
                                              _showUnenrollDialog(classItem.id),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            StudentEnrollmentScreen(student: widget.student),
                  ),
                ).then((_) => _loadEnrolledClasses());
              },
              child: const Text('Matricular em Novas Aulas'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {},
            ),
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }


  Future<void> _showUnenrollDialog(String classId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Desmatrícula'),
          content: const Text(
            'Tem certeza que deseja se desmatricular desta aula?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _unenrollFromClass(classId);
              },
            ),
          ],
        );
      },
    );
  }


  Future<String> _getTeacherName(String teacherId) async {
    
    return 'Professor $teacherId';
  }
}



