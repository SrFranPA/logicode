// lib/presentation/screens/student/aprende/leccion_curso_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/pregunta_model.dart';
import '../../../../data/repositories/pregunta_repository.dart';
import 'test/widgets/pregunta_widget_builder.dart';

class LeccionCursoScreen extends StatefulWidget {
  final String cursoId;
  final String leccionTitulo;

  const LeccionCursoScreen({
    super.key,
    required this.cursoId,
    required this.leccionTitulo,
  });

  @override
  State<LeccionCursoScreen> createState() => _LeccionCursoScreenState();
}

class _LeccionCursoScreenState extends State<LeccionCursoScreen> {
  late final PreguntaRepository repo;

  List<Pregunta> preguntas = [];
  int index = 0;
  int lives = 5;
  bool cargando = true;
  bool answered = false;
  bool correcto = false;
  String retro = '';

  @override
  void initState() {
    super.initState();
    repo = PreguntaRepository(FirebaseFirestore.instance);
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('banco_preguntas')
          .where('cursoId', isEqualTo: widget.cursoId)
          .orderBy('fecha_creacion', descending: false)
          .limit(15)
          .get();
      final data = snap.docs.map((e) => Pregunta.fromDoc(e)).toList();
      if (!mounted) return;
      setState(() {
        preguntas = data;
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

  void _onResult(bool isCorrect, String r) {
    if (!mounted) return;
    setState(() {
      answered = true;
      correcto = isCorrect;
      retro = r;
      if (!isCorrect) lives = (lives - 1).clamp(0, 5);
    });
  }

  void _siguiente() {
    if (index + 1 >= preguntas.length) {
      Navigator.of(context).pop(true);
      return;
    }
    if (lives == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      index++;
      answered = false;
      correcto = false;
      retro = '';
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
      return Scaffold(
        backgroundColor: const Color(0xFFFCF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF283347),
          title: Text(widget.leccionTitulo),
        ),
        body: const Center(
          child: Text(
            'No hay preguntas para esta leccion.',
            style: TextStyle(color: Color(0xFF2C1B0E)),
          ),
        ),
      );
    }

    final pregunta = preguntas[index];
    final progreso = (index + 1) / preguntas.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF283347),
        elevation: 0,
        title: Text(
          widget.leccionTitulo,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: EdgeInsets.only(right: i == 4 ? 0 : 6),
                          child: Icon(
                            Icons.favorite,
                            color: i < lives ? const Color(0xFFFFA451) : Colors.black26,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Curso: ${widget.cursoId}',
                      style: const TextStyle(
                        color: Color(0xFF5A5248),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregunta ${index + 1} de ${preguntas.length}',
                        style: const TextStyle(
                          color: Color(0xFF2C1B0E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFFFA451).withOpacity(0.15),
                          color: const Color(0xFFFFA451),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: buildQuestionWidget(
                    pregunta: pregunta,
                    onResult: _onResult,
                  ),
                ),
                const SizedBox(height: 16),
                if (answered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: correcto ? const Color(0xFFE8F9E5) : const Color(0xFFFFE6E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: correcto ? const Color(0xFF3FB07F) : const Color(0xFFE57373),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          correcto ? Icons.check_circle : Icons.error_outline,
                          color: correcto ? const Color(0xFF2E8E62) : const Color(0xFFB53A3A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            retro.isEmpty
                                ? (correcto ? 'Correcto' : 'Respuesta incorrecta')
                                : retro,
                            style: TextStyle(
                              color: correcto ? const Color(0xFF1D6647) : const Color(0xFFB02A2A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: answered ? _siguiente : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered ? const Color(0xFFFFA451) : Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: answered ? 4 : 0,
                    ),
                    child: Text(
                      index + 1 >= preguntas.length || lives == 0 ? 'Finalizar' : 'Siguiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
