import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; 
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart'; 
import '../services/schedule_service.dart';
import '../services/assignment_service.dart';
import '../services/database_service.dart'; 


class AttendanceRecord {
  final String studentId;
  final String classId;
  final DateTime date;
  final String status; 

  AttendanceRecord({required this.studentId, required this.classId, required this.date, required this.status});

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentId: map['studentId'].toString(), 
      classId: map['classId'],
      date: DateTime.parse(map['date']),
      status: map['status'],
    );
  }
}

class StudentReportCardScreen extends StatefulWidget {
  final User user; 

  const StudentReportCardScreen({Key? key, required this.user}) : super(key: key);

  @override
  _StudentReportCardScreenState createState() => _StudentReportCardScreenState();
}

class _StudentReportCardScreenState extends State<StudentReportCardScreen> {
  bool _isLoading = true;
  List<ClassSchedule> _enrolledClasses = [];
  Map<String, List<Assignment>> _gradesByClass = {}; 
  Map<String, List<AttendanceRecord>> _attendanceByClass = {}; 
  Map<String, String> _teacherNames = {}; 

  final ScheduleService _scheduleService = ScheduleService();
  final AssignmentService _assignmentService = AssignmentService();
  final DatabaseService _databaseService = DatabaseService(); 

  @override
  void initState() {
    super.initState();
    _loadReportCardData();
  }

  Future<void> _loadReportCardData() async {
    setState(() => _isLoading = true);
    try {
      
      final int studentId = widget.user.id!; 

      
      
      _enrolledClasses = await _scheduleService.getStudentEnrolledClasses(studentId.toString());

      
      for (var classSchedule in _enrolledClasses) {
        
        
        final allRelevantAssignments = await _assignmentService.getRelevantAssignmentsForStudentInClass(studentId, classSchedule.id);
        final gradedAssignments = allRelevantAssignments.where((a) => a.isGraded == 1 && a.grade != null).toList();
        _gradesByClass[classSchedule.id] = gradedAssignments;

        
        
        final attendanceRecordsMaps = await _databaseService.getStudentAttendanceRecords(studentId.toString(), classSchedule.id);
        _attendanceByClass[classSchedule.id] = attendanceRecordsMaps.map((map) => AttendanceRecord.fromMap(map)).toList();

        
        if (!_teacherNames.containsKey(classSchedule.teacherId)) {
          
          
          final teacherUserMap = await _databaseService.getUserById(int.tryParse(classSchedule.teacherId) ?? 0);
          if (teacherUserMap != null) {
            _teacherNames[classSchedule.teacherId] = teacherUserMap['name'] as String;
          } else {
            _teacherNames[classSchedule.teacherId] = 'Professor Desconhecido';
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do boletim: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar boletim: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> content = [
            pw.Center(
              child: pw.Text(
                'Boletim Escolar',
                style: pw.TextStyle(font: boldFont, fontSize: 28, color: PdfColors.deepPurple900),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Aluno(a): ${widget.user.name}',
              style: pw.TextStyle(font: font, fontSize: 18),
            ),
            pw.Text(
              'ID do Aluno: ${widget.user.id}',
              style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Divider(height: 30, thickness: 1.5, color: PdfColors.deepPurple200),
          ];

          if (_enrolledClasses.isEmpty) {
            content.add(pw.Center(
              child: pw.Text(
                'Nenhuma turma encontrada ou dados não disponíveis.',
                style: pw.TextStyle(font: font, fontSize: 16),
              ),
            ));
          } else {
            for (var classSchedule in _enrolledClasses) {
              final grades = _gradesByClass[classSchedule.id] ?? [];
              final attendance = _attendanceByClass[classSchedule.id] ?? [];
              final teacherName = _teacherNames[classSchedule.teacherId] ?? 'N/A';

              int totalClasses = attendance.length;
              int presences = attendance.where((r) => r.status == 'P').length;
              int absences = attendance.where((r) => r.status == 'A').length;
              double attendancePercentage = totalClasses > 0 ? (presences / totalClasses) * 100 : 0.0;

              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Turma: ${classSchedule.className}',
                        style: pw.TextStyle(font: boldFont, fontSize: 20, color: PdfColors.deepPurple),
                      ),
                      pw.Text(
                        'Professor(a): $teacherName',
                        style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Presença:',
                        style: pw.TextStyle(font: boldFont, fontSize: 16),
                      ),
                      pw.Text(
                        'Total de Aulas Registradas: $totalClasses',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.Text(
                        'Presenças: $presences',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.Text(
                        'Faltas: $absences',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.Text(
                        'Percentual de Presença: ${attendancePercentage.toStringAsFixed(2)}%',
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Notas das Atividades:',
                        style: pw.TextStyle(font: boldFont, fontSize: 16),
                      ),
                      if (grades.isEmpty)
                        pw.Text(
                          'Nenhuma atividade avaliada ainda.',
                          style: pw.TextStyle(font: font, fontSize: 14, fontStyle: pw.FontStyle.italic),
                        )
                      else
                        pw.Table.fromTextArray(
                          headers: ['Atividade', 'Nota', 'Data de Entrega'],
                          data: grades.map((assignment) => [
                            assignment.assignmentTitle,
                            assignment.grade?.toStringAsFixed(1) ?? 'N/A',
                            DateFormat('dd/MM/yyyy').format(assignment.submissionDate ?? DateTime.now()),
                          ]).toList(),
                          border: pw.TableBorder.all(color: PdfColors.grey400),
                          headerStyle: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.black),
                          cellStyle: pw.TextStyle(font: font, fontSize: 10),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(3),
                            1: const pw.FlexColumnWidth(1),
                            2: const pw.FlexColumnWidth(2),
                          },
                        ),
                    ],
                  ),
                ),
              );
              content.add(pw.Divider(height: 30, thickness: 1.5, color: PdfColors.deepPurple200));
            }
          }

          return content;
        },
      ),
    );

    
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/boletim_${widget.user.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'boletim_${widget.user.name}.pdf');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boletim exportado e pronto para compartilhar!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boletim Escolar', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 183, 59, 98),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 166, 116, 150),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletim Escolar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: _enrolledClasses.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma turma encontrada ou dados não disponíveis.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _enrolledClasses.length + 1, 
              itemBuilder: (context, index) {
                if (index < _enrolledClasses.length) {
                  final classSchedule = _enrolledClasses[index];
                  final grades = _gradesByClass[classSchedule.id] ?? [];
                  final attendance = _attendanceByClass[classSchedule.id] ?? [];
                  final teacherName = _teacherNames[classSchedule.teacherId] ?? 'N/A';

                  int totalClasses = attendance.length;
                  int presences = attendance.where((r) => r.status == 'P').length;
                  int absences = attendance.where((r) => r.status == 'A').length;
                  double attendancePercentage = totalClasses > 0 ? (presences / totalClasses) * 100 : 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turma: ${classSchedule.className}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          Text(
                            'Professor(a): $teacherName',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Presença:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text('Total de Aulas: $totalClasses'),
                          Text('Presenças: $presences'),
                          Text('Faltas: $absences'),
                          Text('Percentual: ${attendancePercentage.toStringAsFixed(2)}%'),
                          const SizedBox(height: 10),
                          const Text(
                            'Notas das Atividades:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (grades.isEmpty)
                            const Text(
                              'Nenhuma atividade avaliada ainda.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: grades.map((assignment) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    '${assignment.assignmentTitle}: ${assignment.grade?.toStringAsFixed(1) ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: _generatePdfReport,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar Boletim em PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}