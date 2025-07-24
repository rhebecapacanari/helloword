
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import '../models/assignment_model.dart';
import '../models/user_model.dart';
import '../services/assignment_service.dart';
import 'package:open_file/open_file.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final Assignment submission; 
  final User user; 

  const SubmissionDetailScreen({
    Key? key,
    required this.submission,
    required this.user,
  }) : super(key: key);

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  final _feedbackController = TextEditingController();
  final _gradeController = TextEditingController();
  File? _feedbackImage;

  final AssignmentService _assignmentService = AssignmentService();

  @override
  void initState() {
    super.initState();
    
    if (widget.submission.feedback != null) {
      _feedbackController.text = widget.submission.feedback!;
    }
    if (widget.submission.grade != null) {
      _gradeController.text = widget.submission.grade.toString();
    }
    
    if (widget.submission.correctionImagePath != null && widget.submission.correctionImagePath!.isNotEmpty) {
      _feedbackImage = File(widget.submission.correctionImagePath!);
    }
  }

  
  Future<void> _pickFeedbackImage() async {
    final XTypeGroup imageGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
    final XFile? file = await openFile(acceptedTypeGroups: [imageGroup]);

    if (file != null) {
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(
        directory.path,
        'feedback_images', 
        '${widget.submission.id}_feedback_$timestamp${path.extension(file.path)}', 
      );
      await Directory(path.dirname(newPath)).create(recursive: true);
      final savedFile = await File(file.path).copy(newPath);

      setState(() {
        _feedbackImage = savedFile;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem de feedback selecionada e salva localmente.')));
    }
  }

  
  Future<void> _submitGrade() async {
    final grade = double.tryParse(_gradeController.text);
    if (grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma nota válida')),
      );
      return;
    }

    await _assignmentService.gradeAssignment(
      submissionId: widget.submission.id, 
      feedback: _feedbackController.text,
      grade: grade,
      correctionImagePath: _feedbackImage?.path, 
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação salva com sucesso')));
    Navigator.pop(context, true); 
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.submission; 
    final isTeacher = widget.user.type == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Avaliar Entrega de ${assignment.studentName ?? 'Aluno'} ' : 'Detalhes da Minha Entrega',
        style: const TextStyle(color: Colors.white),
        ),
         iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Atividade: ${assignment.assignmentTitle}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Descrição: ${assignment.description ?? ''}', style: const TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 16),
            if (assignment.studentId != null) 
              Text('Aluno: ${assignment.studentName ?? 'N/A'}', style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 8),
            if (assignment.submissionDate != null)
              Text('Data de Envio: ${assignment.submissionDate!.day}/${assignment.submissionDate!.month}/${assignment.submissionDate!.year} ${assignment.submissionDate!.hour}:${assignment.submissionDate!.minute}', style: const TextStyle(color: Colors.white)),
            Text('Prazo: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            if (assignment.fileUrl != null && assignment.fileUrl!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.file_copy),
                label: const Text('Abrir Arquivo Enviado'),
                onPressed: () async {
                  final fileUrl = assignment.fileUrl;
                  if (fileUrl != null && fileUrl.isNotEmpty) {
                    try {
                      final result = await OpenFile.open(fileUrl);
                      if (result.type != ResultType.done) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Não foi possível abrir o arquivo: ${result.message}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao abrir arquivo: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nenhum arquivo anexado a esta entrega.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                  foregroundColor: Colors.black,
                ),
              ),
            const Divider(height: 32, color: Colors.white70),

            
            if (isTeacher) ...[
              const Text('Avaliação:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Comentário (Feedback)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickFeedbackImage,
                icon: const Icon(Icons.photo),
                label: Text(_feedbackImage == null ? 'Selecionar Imagem de Feedback' : 'Trocar Imagem de Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 210, 198, 33),
                  foregroundColor: Colors.black,
                ),
              ),
              if (_feedbackImage != null) ...[
                const SizedBox(height: 8),
                Text('Imagem de feedback selecionada: ${path.basename(_feedbackImage!.path)}', style: const TextStyle(color: Colors.white)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(_feedbackImage!, height: 150),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitGrade,
                child: const Text('ENVIAR AVALIAÇÃO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 183, 59, 98),
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              
              Text('Status: ${assignment.status}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (assignment.isGraded) ...[
                Text('Nota: ${assignment.grade?.toStringAsFixed(1) ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Comentário do Professor: ${assignment.feedback ?? "Nenhum comentário"}', style: const TextStyle(color: Colors.white)),
                if (assignment.correctionImagePath != null && assignment.correctionImagePath!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Imagem de Correção:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Image.file(File(assignment.correctionImagePath!), height: 200),
                ]
              ] else if (assignment.isLate) ...[
                const Text('Esta entrega foi feita fora do prazo.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.orangeAccent)),
              ] else
          const Text('Sua entrega ainda não foi avaliada.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}