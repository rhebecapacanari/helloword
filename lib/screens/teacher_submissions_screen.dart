
import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../models/user_model.dart';
import '../services/assignment_service.dart';
import 'submission_detail_screen.dart'; 

class TeacherSubmissionsScreen extends StatefulWidget {
  final Assignment originalAssignment; 
  final User user; 

  const TeacherSubmissionsScreen({
    Key? key,
    required this.originalAssignment,
    required this.user,
  }) : super(key: key);

  @override
  State<TeacherSubmissionsScreen> createState() => _TeacherSubmissionsScreenState();
}

class _TeacherSubmissionsScreenState extends State<TeacherSubmissionsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  late Future<List<Assignment>> _studentSubmissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  
  void _loadSubmissions() {
    _studentSubmissionsFuture = _assignmentService.getStudentSubmissionsForOriginalAssignment(
      widget.originalAssignment.assignmentTitle,
      widget.originalAssignment.classId,
    );
  }

  
  Future<void> _closeAssignment() async {
    
    final updatedAssignment = widget.originalAssignment.copyWith(isOpen: false);
    
    await _assignmentService.addAssignment(updatedAssignment); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atividade fechada com sucesso.')),
    );
    
    Navigator.pop(context, true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entregas para: ${widget.originalAssignment.assignmentTitle}',
        style: const TextStyle(color: Colors.white),
        ),
         iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
        actions: [
          
          if (widget.originalAssignment.isOpen)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Fechar Atividade',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Fechar Atividade?'),
                    content: const Text('Deseja fechar esta atividade para novas entregas?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _closeAssignment();
                }
              },
            ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: FutureBuilder<List<Assignment>>(
        future: _studentSubmissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar entregas: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final submissions = snapshot.data ?? [];

          if (submissions.isEmpty) {
            return const Center(child: Text('Nenhum aluno entregou esta atividade ainda.', style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text('Aluno: ${submission.studentName ?? 'Desconhecido'}'),
                  subtitle: Text('Status: ${submission.status}'),
                  trailing: submission.isGraded
                      ? Text('Nota: ${submission.grade?.toStringAsFixed(1) ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold))
                      : const Icon(Icons.pending),
                  onTap: () async {
                    
                    final bool? gradeUpdated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmissionDetailScreen(
                          submission: submission, 
                          user: widget.user, 
                        ),
                      ),
                    );
                    if (gradeUpdated == true) { 
                      setState(() {
                        _loadSubmissions(); 
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}