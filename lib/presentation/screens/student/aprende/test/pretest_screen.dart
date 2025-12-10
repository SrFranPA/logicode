// lib/presentation/screens/student/aprende/test/pretest_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../data/models/pregunta_model.dart';
import '../../../../../data/repositories/pregunta_repository.dart';
import 'widgets/pregunta_widget_builder.dart';

class PretestScreen extends StatefulWidget {
  const PretestScreen({super.key});

  @override
  State<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends State<PretestScreen> {
  late final PreguntaRepository repo;

  List<Pregunta> preguntas = [];
  int index = 0;

  bool locked = false;
  bool? fueCorrecto;
  String retro = "";

  @override
  void initState() {
    super.initState();
    repo = PreguntaRepository(FirebaseFirestore.instance);
    cargarPreguntas();
  }

  Future<void> cargarPreguntas() async {
    preguntas = await repo.cargarPreguntasPretest();
    setState(() {});
  }

  void _siguiente() {
    if (index + 1 >= preguntas.length) {
      // TODO: mostrar finalización
      return;
    }

    setState(() {
      index++;
      locked = false;
      fueCorrecto = null;
      retro = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (preguntas.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pregunta = preguntas[index];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F2FF),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        leading: const BackButton(color: Colors.white),
        title: const Text("Pretest", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Pregunta ${index + 1} de ${preguntas.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            LinearProgressIndicator(
              value: (index + 1) / preguntas.length,
              backgroundColor: Colors.orange.shade100,
              color: Colors.orange,
            ),

            const SizedBox(height: 18),

            buildQuestionWidget(
              pregunta: pregunta,
              onResult: (correcta, r) {
                setState(() {
                  locked = true;
                  fueCorrecto = correcta;
                  retro = r;
                });
              },
            ),

            const SizedBox(height: 20),

            if (locked)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fueCorrecto! ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  retro,
                  style: TextStyle(
                    fontSize: 18,
                    color: fueCorrecto! ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: locked ? _siguiente : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    locked ? Colors.orange : Colors.grey.shade400,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Siguiente",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
