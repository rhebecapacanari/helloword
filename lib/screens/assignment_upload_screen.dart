import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';
import '../services/database_service.dart';
import 'package:file_selector/file_selector.dart';

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
  List<Assignment> _submittedAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadSubmittedAssignments();
  }

  Future<void> _loadSubmittedAssignments() async {
    final assignments = await fetchAssignmentsByStudent(widget.studentId);
    setState(() {
      _submittedAssignments = assignments;
    });
  }

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

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedFile = null;
        _fileName = null;
        _fileType = null;
      });

      _loadSubmittedAssignments();
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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Enviar Trabalho',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
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
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Digite um título para o trabalho' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Arquivo do Trabalho*',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (_fileName != null) ...[
                Text(
                  'Selecionado: $_fileName',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Tipo: ${_fileType?.toUpperCase()}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              ElevatedButton.icon(
  icon: const Icon(Icons.attach_file),
  label: const Text('Selecionar Arquivo'),
  onPressed: () async {
    final XTypeGroup acceptedTypes = XTypeGroup(
      label: 'arquivos',
      extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [acceptedTypes]);
    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _fileName = file.name;
        _fileType = file.name.split('.').last.toLowerCase();
      });
    }
  },
),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('ENVIAR TRABALHO'),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white),
              const Text(
                'Trabalhos Enviados:',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ..._submittedAssignments.map((assignment) {
                return Card(
                  child: ListTile(
                    title: Text(assignment.assignmentTitle ?? 'Sem título'),
                    subtitle: Text(
                      'Enviado em: ${assignment.submissionDate.toString()}',
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List<Assignment>> fetchAssignmentsByStudent(String studentId) async {
  final db = await AssignmentService().database; 
  final result = await db.query(
    'assignments',
    where: 'studentId = ?',
    whereArgs: [studentId],
  );
  return result.map((e) => Assignment.fromMap(e)).toList();
}

