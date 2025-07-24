
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import '../models/assignment_model.dart';
import '../models/user_model.dart';
import '../services/assignment_service.dart';
import 'package:open_file/open_file.dart';
import 'package:collection/collection.dart'; 


import 'teacher_submissions_screen.dart';
import 'submission_detail_screen.dart';
import 'student_submit_assignment_screen.dart';
import 'student_view_submission_screen.dart';


class AssignmentUploadScreen extends StatefulWidget {
  final User user;
  final String? classId;
  final String? className;

  const AssignmentUploadScreen({
    Key? key,
    required this.user,
    this.classId,
    this.className,
  }) : super(key: key);

  @override
  State<AssignmentUploadScreen> createState() => _AssignmentUploadScreenState();
}

class _AssignmentUploadScreenState extends State<AssignmentUploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  
  File? _selectedFile;
  String? _fileName;
  String? _fileType;

  final AssignmentService _assignmentService = AssignmentService();
  Assignment? _openAssignment; 

  late final String _classId;
  late final String _className;

  @override
  void initState() {
    super.initState();
    _classId = widget.classId ?? 'default_class_id';
    _className = widget.className ?? 'Sem Nome';
    print('AssignmentUploadScreen: initState: classId = $_classId, className = $_className');

    
    _loadOpenAssignment();
  }

  
  Future<void> _loadOpenAssignment() async {
    print('AssignmentUploadScreen: Tentando carregar atividade aberta para classId: $_classId');
    final assignment = await _assignmentService.getOpenAssignment(_classId);
    if (assignment != null) {
      print("AssignmentUploadScreen: Atividade aberta carregada: ${assignment.assignmentTitle} (ID: ${assignment.id})");
      setState(() {
        _openAssignment = assignment;
      });
    } else {
      print("AssignmentUploadScreen: Nenhuma atividade aberta encontrada para classId: $_classId.");
      setState(() {
        _openAssignment = null; 
      });
    }
  }

  
  Future<void> _createAssignment() async {
    if (_titleController.text.isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título e data limite')),
      );
      print('AssignmentUploadScreen: Falha ao criar atividade: Título ou data limite ausentes.');
      return;
    }

    
    
    
    
    
    
    
    
    
    

    
    final newAssignment = Assignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      teacherId: widget.user.id.toString(),
      classId: _classId,
      className: _className,
      assignmentTitle: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate!,
      fileUrl: '', 
      fileName: '',
      fileType: '',
      studentId: null, 
      studentName: null,
      submissionDate: null, 
      isOpen: true, 
    );

    print('AssignmentUploadScreen: Tentando adicionar nova atividade: ${newAssignment.assignmentTitle}');
    await _assignmentService.addAssignment(newAssignment);
    print('AssignmentUploadScreen: Nova atividade adicionada ao serviço.');

    
    await _loadOpenAssignment();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atividade criada com sucesso')),
    );
    print('AssignmentUploadScreen: Atividade "${newAssignment.assignmentTitle}" criada com sucesso.');
  }

  void _showCreateAssignmentDialog() {
    
    _titleController.clear();
    _descriptionController.clear();
    _dueDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Atividade'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  style: const TextStyle(color: Colors.black), 
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 10),
                StatefulBuilder( 
                  builder: (context, setDialogState) {
                    return TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() { 
                            _dueDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                      label: Text(
                        _dueDate == null
                            ? 'Selecionar Data Limite'
                            : 'Data: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: const TextStyle(color: Colors.deepPurple), 
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _createAssignment();
                Navigator.pop(context);
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  
  Future<void> _editAssignmentDueDate(Assignment assignment) async {
    final initialDate = assignment.dueDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), 
    );

    if (pickedDate != null && pickedDate != initialDate) {
      final updatedAssignment = assignment.copyWith(dueDate: pickedDate);
      await _assignmentService.addAssignment(updatedAssignment); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prazo da atividade atualizado com sucesso.')),
      );
      
      setState(() {
        
      });
    }
  }


  
  
  Future<void> _pickFile() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _fileName = file.name;
        _fileType = file.name.split('.').last.toLowerCase();
      });
    }
  }

  Future<String> _saveFileLocally(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = path.join(
      directory.path,
      'assignments',
      '${widget.user.id}_$timestamp${_fileName ?? ''}',
    );
    await Directory(path.dirname(newPath)).create(recursive: true);
    return await file.copy(newPath).then((f) => f.path);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.user.type == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Gerenciar Atividades' : 'Atividades da Turma',
        style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isTeacher ? _buildTeacherView() : _buildStudentView(),
      ),
    );
  }

  Widget _buildTeacherView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FutureBuilder<List<Assignment>>(
            future: _assignmentService.getClassAssignments(_classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('AssignmentUploadScreen: Erro ao carregar atividades para professor: ${snapshot.error}');
                return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              final allAssignments = snapshot.data ?? [];
              
              final teacherAssignments = allAssignments.where((a) => a.studentId == null).toList();

              print('AssignmentUploadScreen: Visão do professor: ${teacherAssignments.length} atividades de professor buscadas para classId: $_classId');
              if (teacherAssignments.isEmpty) {
                return const Center(child: Text('Nenhuma atividade criada ainda.', style: TextStyle(color: Colors.white)));
              }
              return ListView.builder(
                itemCount: teacherAssignments.length,
                itemBuilder: (context, index) {
                  final assignment = teacherAssignments[index];
                  print('AssignmentUploadScreen: Exibindo atividade (Professor): ${assignment.assignmentTitle} (ID: ${assignment.id}, isOpen: ${assignment.isOpen})');
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(assignment.assignmentTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prazo: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}'),
                          Text(assignment.description ?? ''),
                        ],
                      ),
                      
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          assignment.isOpen
                              ? const Icon(Icons.lock_open, color: Colors.green)
                              : const Icon(Icons.lock, color: Colors.grey),
                          const SizedBox(width: 8), 
                          
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editAssignmentDueDate(assignment),
                          ),
                        ],
                      ),
                      onTap: () async {
                        
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherSubmissionsScreen(
                              originalAssignment: assignment, 
                              user: widget.user,  
                            ),
                          ),
                        );
                        if (result == true) { 
                          setState(() {
                            
                            
                            _loadOpenAssignment();
                          });
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            _showCreateAssignmentDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova Atividade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 210, 198, 33),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    return FutureBuilder<List<Assignment>>(
      future: _assignmentService.getClassAssignments(_classId), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('AssignmentUploadScreen: Erro ao carregar atividades para aluno: ${snapshot.error}');
          return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final allAssignments = snapshot.data ?? [];
        
        final teacherOpenAndOnTimeAssignments = allAssignments.where((a) =>
            a.studentId == null && 
            a.isOpen && 
            a.dueDate.isAfter(DateTime.now()) 
        ).toList();

        print('AssignmentUploadScreen: Visão do aluno: ${teacherOpenAndOnTimeAssignments.length} atividades abertas e no prazo para classId: $_classId');

        if (teacherOpenAndOnTimeAssignments.isEmpty) {
          return const Center(child: Text('Nenhuma atividade disponível para envio no momento.', style: TextStyle(color: Colors.white)));
        }

        return ListView.builder(
          itemCount: teacherOpenAndOnTimeAssignments.length,
          itemBuilder: (context, index) {
            final assignment = teacherOpenAndOnTimeAssignments[index];
            print('AssignmentUploadScreen: Exibindo atividade (Aluno): ${assignment.assignmentTitle} (ID: ${assignment.id}, isOpen: ${assignment.isOpen}, Prazo: ${assignment.dueDate})');

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(assignment.assignmentTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prazo: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}'),
                    Text(assignment.description ?? ''),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios), 
                onTap: () async {
                  
                  
                  final mySubmission = await _assignmentService.getStudentSubmissionForAssignment(
                    widget.user.id.toString(), 
                    assignment.id, 
                  );

                  if (mySubmission != null) {
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentViewSubmissionScreen(
                          submission: mySubmission,
                        ),
                      ),
                    );
                  } else {
                    
                    final bool? submissionSuccessful = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentSubmitAssignmentScreen(
                          user: widget.user,
                          assignment: assignment, 
                        ),
                      ),
                    );
                    if (submissionSuccessful == true) { 
                      setState(() {
                        
                      });
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}