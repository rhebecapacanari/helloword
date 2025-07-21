import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../models/enrollment_model.dart';
import '../models/student_model.dart';
import '../services/enrollment_service.dart';

class StudentEnrollmentScreen extends StatefulWidget {
  final Student student;

  const StudentEnrollmentScreen({super.key, required this.student});

  @override
  State<StudentEnrollmentScreen> createState() => _StudentEnrollmentScreenState();
}

class _StudentEnrollmentScreenState extends State<StudentEnrollmentScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<ClassSchedule> _availableClasses = [];
  List<ClassEnrollment> _myEnrollments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEnrollmentsAndClasses();
  }

  Future<void> _loadEnrollmentsAndClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _availableClasses = await _enrollmentService.getAvailableClasses(widget.student.id!.toString());
_myEnrollments = await _enrollmentService.getStudentEnrollments(widget.student.id!.toString());

    } catch (e) {
      _errorMessage = 'Erro ao carregar aulas: $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enrollInClass(String classId) async {
    setState(() => _isLoading = true);
    try {
      final success = await _enrollmentService.enrollStudentInClass(
        classId: classId,
        studentId: widget.student.id.toString(),
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matrícula realizada com sucesso!')),
        );
        await _loadEnrollmentsAndClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao realizar matrícula')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
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

 @override
Widget build(BuildContext context) {
  return Scaffold(
        backgroundColor: const Color.fromARGB(255, 166, 116, 150),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 183, 59, 98),
           iconTheme: const IconThemeData(color: Colors.white), 
          title: const Text(
            'MATRICULAR EM AULAS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aulas Disponíveis:',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._availableClasses.map((classItem) {
                          final isEnrolled = _myEnrollments.any((e) => e.classId == classItem.id);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(classItem.className),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${classItem.dayOfWeek} - ${DateFormat('dd/MM').format(classItem.date)}'),
                                  Text('Horário: ${_formatTime(classItem.startTime)}'),
                                  if (classItem.description != null)
                                    Text('Descrição: ${classItem.description!}')
                                ],
                              ),
                              trailing: isEnrolled
                                  ? const Text(
                                      'Matriculado',
                                      style: TextStyle(color: Colors.green),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _enrollInClass(classItem.id),
                                      child: const Text('Matricular'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                                          foregroundColor: Colors.black,
                                    ),
                                  )
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
      );
}
}