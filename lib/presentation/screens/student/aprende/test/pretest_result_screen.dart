// lib/presentation/screens/student/tests/pretest_result_screen.dart

import 'package:flutter/material.dart';

class PretestResultScreen extends StatelessWidget {
  final int total;
  final int correctas;
  final List<String> preguntasIds;

  const PretestResultScreen({
    super.key,
    required this.total,
    required this.correctas,
    required this.preguntasIds,
  });

  @override
  Widget build(BuildContext context) {
    final puntaje = ((correctas / total) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2A03A),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Resultado del Pretest',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$puntaje%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12314D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctas de $total correctas',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF555B64),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // volver a Aprende
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2A03A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Volver a cursos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
