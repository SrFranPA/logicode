// lib/presentation/screens/student/aprende/test/pretest_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool cargando = true;
  bool _finalizado = false;

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
    try {
      final data = await repo.cargarPreguntasPretest();
      if (!mounted) return;
      data.shuffle();
      final seleccion = data.length > 10 ? data.sublist(0, 10) : data;
      setState(() {
        preguntas = seleccion;
        cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        preguntas = [];
        cargando = false;
      });
    }
  }

  Future<void> _marcarCompletado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'pretest_estado': 'aprobado',
          'pretest_completado': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Si falla el guardado, no bloqueamos la UX
    }
  }

  Future<void> _siguiente() async {
    if (_finalizado) return;
    if (index + 1 >= preguntas.length) {
      await _marcarCompletado();
      if (!mounted) return;
      _finalizado = true;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pretest completado'),
          content: const Text(
            'Has finalizado el pretest. Ahora puedes avanzar en tus cursos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
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
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (preguntas.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No hay preguntas disponibles para el pretest.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final pregunta = preguntas[index];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF6ED),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE07A1E),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Pretest",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEF6ED), Color(0xFFFFF0DF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07A1E).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.flag_circle_rounded,
                              color: Color(0xFFE07A1E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pregunta ${index + 1} de ${preguntas.length}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C1B0E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 240,
                                child: LinearProgressIndicator(
                                  value: (index + 1) / preguntas.length,
                                  backgroundColor: const Color(0xFFE07A1E).withOpacity(0.16),
                                  color: const Color(0xFFE07A1E),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _badge(Icons.schedule, "Tiempo libre", const Color(0xFF8D5722)),
                          const SizedBox(width: 10),
                          _badge(Icons.check_circle_outline, "Responde y continua", const Color(0xFF2E7D32)),
                          const SizedBox(width: 10),
                          _badge(Icons.shuffle, "Orden aleatorio", const Color(0xFF7B4A1D)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: buildQuestionWidget(
                    pregunta: pregunta,
                    onResult: (correcta, r) {
                      if (!mounted) return;
                      setState(() {
                        locked = true;
                        fueCorrecto = correcta;
                        retro = r;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                if (locked)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fueCorrecto! ? const Color(0xFFE9F8EF) : const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: fueCorrecto! ? const Color(0xFF3FB07F) : const Color(0xFFE57373),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          fueCorrecto! ? Icons.check_circle : Icons.error_outline,
                          color: fueCorrecto! ? const Color(0xFF2E8E62) : const Color(0xFFB53A3A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            retro,
                            style: TextStyle(
                              fontSize: 15,
                              color: fueCorrecto! ? const Color(0xFF1D6647) : const Color(0xFFB02A2A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: locked ? _siguiente : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: locked ? const Color(0xFFE07A1E) : const Color(0xFFE5C49B),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: locked ? 4 : 0,
                        ),
                        child: Text(
                          index + 1 >= preguntas.length ? "Finalizar" : "Siguiente",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _siguiente,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8D5722),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      child: const Text(
                        "Omitir",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _badge(IconData icon, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
