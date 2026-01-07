// lib/presentation/screens/student/tests/pretest_result_screen.dart

import 'package:flutter/material.dart';

import '../../../../../services/app_config_service.dart';

class PretestResultScreen extends StatelessWidget {
  final int total;
  final int correctas;
  final List<String> preguntasIds;
  final AppConfigService _configService = AppConfigService();

  PretestResultScreen({
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
            StreamBuilder<bool>(
              stream: _configService.watchOcultarNotaPretest(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                final ocultarNota = snapshot.data == true;

                if (ocultarNota) {
                  return Column(
                    children: const [
                      Icon(Icons.visibility_off, size: 46, color: Color(0xFF555B64)),
                      SizedBox(height: 10),
                      Text(
                        'La nota del test diagnóstico está oculta por administración.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF555B64),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
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
                  ],
                );
              },
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
