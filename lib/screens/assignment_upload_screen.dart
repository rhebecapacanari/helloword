import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';
import '../services/database_service.dart';


class AssignmentUploadScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String teacherId;


  const AssignmentUploadScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.teacherId,
  }) : super(key: key);


  @override
  _AssignmentUploadScreenState createState() => _AssignmentUploadScreenState();
}


class _AssignmentUploadScreenState extends State<AssignmentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _fileName;
  String? _fileType;
  bool _isLoading = false;
  final AssignmentService _assignmentService = AssignmentService();


  Future<String> _saveFileLocally(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = path.join(
      directory.path,
      'assignments',
      '${widget.studentId}_$timestamp$_fileName',
    );


    await Directory(path.dirname(newPath)).create(recursive: true);
    await file.copy(newPath);
    return newPath;
  }


  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo para enviar')),
      );
      return;
    }


    setState(() => _isLoading = true);


    try {
      
      final localFilePath = await _saveFileLocally(_selectedFile!);


      
      final assignment = Assignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: widget.studentId,
        studentName: widget.studentName,
        teacherId: widget.teacherId,
        classId: widget.classId,
        className: widget.className,
        fileUrl: localFilePath,
        fileName: _fileName!,
        fileType: _fileType!,
        submissionDate: DateTime.now(),
        description: _descriptionController.text,
        assignmentTitle: _titleController.text,
      );


      
      await _assignmentService.addAssignment(assignment);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabalho enviado com sucesso!')),
      );


      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar trabalho: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar Trabalho')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Trabalho*',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value!.isEmpty
                            ? 'Digite um título para o trabalho'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Arquivo do Trabalho*',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tipo: ${_fileType?.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAssignment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('ENVIAR TRABALHO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



