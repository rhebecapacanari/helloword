
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/assignment_model.dart';
import 'package:open_file/open_file.dart';

class StudentViewSubmissionScreen extends StatelessWidget {
  final Assignment submission; 

  const StudentViewSubmissionScreen({Key? key, required this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    final isGraded = submission.isGraded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Entrega',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 183, 59, 98),
      ),
      backgroundColor: const Color.fromARGB(255, 166, 116, 150),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Atividade: ${submission.assignmentTitle}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Descrição: ${submission.description ?? ''}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Prazo: ${submission.dueDate.day}/${submission.dueDate.month}/${submission.dueDate.year}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            if (submission.fileUrl != null && submission.fileUrl!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.file_copy),
                label: const Text('Abrir Meu Arquivo Enviado'),
                onPressed: () async {
                  final fileUrl = submission.fileUrl;
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

            Text('Status: ${submission.status}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            if (isGraded) ...[
              Text('Nota: ${submission.grade?.toStringAsFixed(1) ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Comentário do Professor: ${submission.feedback ?? 'Nenhum feedback'}', style: const TextStyle(color: Colors.white)),
              if (submission.correctionImagePath != null && submission.correctionImagePath!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Imagem de Correção:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Image.file(File(submission.correctionImagePath!), height: 200),
              ]
            ] else if (submission.isLate) ...[
              const Text('Sua entrega foi feita fora do prazo e aguarda avaliação.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.orangeAccent)),
            ] else
            const Text('Sua entrega ainda não foi avaliada.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}