
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import '../models/assignment_model.dart';
import '../models/user_model.dart';
import '../services/assignment_service.dart';
import 'package:open_file/open_file.dart'; 

class StudentSubmitAssignmentScreen extends StatefulWidget {
  final User user;
  final Assignment assignment; 

  const StudentSubmitAssignmentScreen({Key? key, required this.user, required this.assignment}) : super(key: key);

  @override
  _StudentSubmitAssignmentScreenState createState() => _StudentSubmitAssignmentScreenState();
}

class _StudentSubmitAssignmentScreenState extends State<StudentSubmitAssignmentScreen> {
  File? _selectedFile;
  String? _fileName;
  String? _fileType;
  final AssignmentService _assignmentService = AssignmentService();

  
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
      'student_submissions', 
      '${widget.user.id}_${widget.assignment.id}_$timestamp${path.extension(file.path)}',
    );
    await Directory(path.dirname(newPath)).create(recursive: true);
    return await file.copy(newPath).then((f) => f.path);
  }

  
  Future<void> _submitAssignment() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo antes de enviar.')),
      );
      return;
    }

    
    final isLate = DateTime.now().isAfter(widget.assignment.dueDate);
    if (isLate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O prazo para esta atividade já encerrou.')),
      );
      return;
    }

    
    if (!widget.assignment.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta atividade foi fechada pelo professor e não aceita mais envios.')),
      );
      return;
    }

    final localPath = await _saveFileLocally(_selectedFile!);

    
    final submission = Assignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      studentId: widget.user.id.toString(),
      studentName: widget.user.name,
      teacherId: widget.assignment.teacherId, 
      classId: widget.assignment.classId, 
      className: widget.assignment.className, 
      assignmentTitle: widget.assignment.assignmentTitle, 
      description: widget.assignment.description, 
      dueDate: widget.assignment.dueDate, 
      fileUrl: localPath,
      fileName: _fileName ?? '',
      fileType: _fileType ?? '',
      submissionDate: DateTime.now(), 
      isGraded: false,
      isOpen: false, 
    );

    await _assignmentService.addAssignment(submission); 

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trabalho enviado com sucesso')),
    );

    Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    final isLate = DateTime.now().isAfter(widget.assignment.dueDate);
    
    final canSubmit = widget.assignment.isOpen && !isLate;

    return Scaffold(
      appBar: AppBar(
        title: Text('Enviar: ${widget.assignment.assignmentTitle}'),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.assignment.description ?? '', style: const TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Prazo: ${widget.assignment.dueDate.day}/${widget.assignment.dueDate.month}/${widget.assignment.dueDate.year}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Selecionar Arquivo'),
              onPressed: canSubmit ? _pickFile : null, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                foregroundColor: Colors.black,
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Text('Arquivo selecionado: $_fileName', style: const TextStyle(color: Colors.white)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canSubmit ? _submitAssignment : null, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ENVIAR TRABALHO'),
            ),
            
            if (!widget.assignment.isOpen)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Esta atividade foi fechada pelo professor.',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            if (isLate)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Prazo encerrado.',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}