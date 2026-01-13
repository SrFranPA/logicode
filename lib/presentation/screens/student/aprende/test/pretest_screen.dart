// lib/presentation/screens/student/aprende/test/pretest_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../data/models/pregunta_model.dart';
import '../../../../../data/repositories/pregunta_repository.dart';
import '../../../../../data/repositories/evaluaciones_repository.dart';
import 'widgets/pregunta_widget_builder.dart';

class PretestScreen extends StatefulWidget {
  const PretestScreen({super.key});

  @override
  State<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends State<PretestScreen> {
  late final PreguntaRepository repo;
  late final EvaluacionesRepository evaluacionesRepo;

  List<Pregunta> preguntas = [];
  List<bool?> respuestas = [];
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
    evaluacionesRepo = EvaluacionesRepository(db: FirebaseFirestore.instance);
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
        respuestas = List<bool?>.filled(seleccion.length, null);
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

  Future<void> _guardarResultadoFinal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final totalPreguntas = preguntas.length;
    if (totalPreguntas == 0) return;

    final correctas = respuestas.where((r) => r == true).length;
    final bancoIds = preguntas.map((p) => p.id ?? '').toList();
    final porcentaje = (correctas * 100.0 / totalPreguntas);
    final estado = porcentaje >= 70 ? 'aprobado' : 'reprobado';

    try {
      await evaluacionesRepo.registrarEvaluacion(
        uid: user.uid,
        tipo: 'pre',
        puntajeObtenido: correctas,
        puntajeMinimo: 0,
        puntajeMaximo: totalPreguntas,
        numPreguntas: totalPreguntas,
        bancoPreguntasIds: bancoIds,
      );
    } catch (_) {
      // Si falla el detalle, igual guardamos la nota en el perfil.
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'pretest_estado': estado,
          'pretest_calificacion': porcentaje,
          'pretest_completado': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignoramos error para no cortar el flujo del usuario.
    }
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF9FAF9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/gif/reprovado.gif',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Salir del pretest?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF2C1B0E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada intento te acerca a tu meta. ¡Termina este reto y demuestra tu nivel!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4B4F56),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C1B0E)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA200),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Salir',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _siguiente() async {
    if (_finalizado) return;
    // Si no se respondio la pregunta actual, marcar como incorrecta.
    if (respuestas[index] == null) {
      respuestas[index] = false;
    }

    if (index + 1 >= preguntas.length) {
      await _guardarResultadoFinal();
      if (!mounted) return;
      _finalizado = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF9FAF9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/gif/fintest.gif',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  '¡Pretest completado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ahora puedes avanzar en tus cursos. Cada paso suma para llegar lejos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sigue con este impulso, el siguiente reto te espera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
      backgroundColor: const Color(0xFFFFF2F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2C1B0E),
        leading: BackButton(
          color: Colors.white,
          onPressed: () async {
            final exit = await _confirmExit();
            if (exit && mounted) Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Pretest",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF2F0), Color(0xFFFCD9D4)],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Calienta motores",
                              style: TextStyle(
                                color: Color(0xFF4A3424),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Demuestra tu nivel para empezar con potencia.",
                              style: TextStyle(
                                color: Color(0xFF2C1B0E),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/mascota/refuerzo3.png',
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB9A0).withOpacity(0.25)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
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
                              color: const Color(0xFFFFA200).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFA200).withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.flag_circle_rounded,
                              color: Color(0xFFFFA200),
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
                                  backgroundColor: const Color(0xFFFFA200).withOpacity(0.18),
                                  color: const Color(0xFFFFA200),
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
                          _badge(Icons.check_circle_outline, "Responde y continúa", const Color(0xFF3FB07F)),
                          const SizedBox(width: 10),
                          _badge(Icons.shuffle, "Orden aleatorio", const Color(0xFFE57373)),
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
                  child: KeyedSubtree(
                    key: ValueKey(pregunta.id ?? index),
                    child: buildQuestionWidget(
                      pregunta: pregunta,
                      onResult: (correcta, r) {
                        if (!mounted) return;
                        setState(() {
                          locked = true;
                          fueCorrecto = correcta;
                          retro = r;
                          respuestas[index] = correcta;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (locked)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fueCorrecto! ? const Color(0xFFE8F9E5) : const Color(0xFFFFE6E6),
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
                          backgroundColor: locked ? const Color(0xFFFB7A57) : const Color(0xFFFFD4C6),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),    );
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
