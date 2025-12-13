// lib/presentation/screens/student/aprende/leccion_curso_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/pregunta_model.dart';
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
  List<Pregunta> preguntas = [];
  int index = 0;
  int lives = 5;
  bool cargando = true;
  bool answered = false;
  bool correcto = false;
  String retro = '';
  String? _userId;
  bool sinVidas = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _initData();
  }

  Future<void> _initData() async {
    await _cargarVidas();
    if (!mounted) return;
    if (lives <= 0) {
      setState(() {
        sinVidas = true;
        cargando = false;
      });
      return;
    }
    await _cargarPreguntas();
  }

  Future<void> _cargarVidas() async {
    if (_userId == null) return;
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final vidasDb = (data['vidas'] as num?)?.toInt();
    if (vidasDb != null) {
      lives = vidasDb.clamp(0, 5);
    }
  }

  Future<void> _cargarPreguntas() async {
    try {
      final col = FirebaseFirestore.instance.collection('banco_preguntas');

      final snap = await col.where('cursoId', isEqualTo: widget.cursoId).limit(40).get();
      var data = snap.docs.map((e) => Pregunta.fromDoc(e)).toList();

      if (data.isEmpty) {
        final allSnap = await col.limit(40).get();
        data = allSnap.docs.map((e) => Pregunta.fromDoc(e)).toList();
      }

      const ordenDif = {
        'Muy facil': 0,
        'Facil': 1,
        'Medio': 2,
        'Dificil': 3,
        'Muy dificil': 4,
      };

      data.sort((a, b) {
        final da = ordenDif[a.dificultad] ?? 99;
        final db = ordenDif[b.dificultad] ?? 99;
        if (da != db) return da.compareTo(db);
        return a.fechaCreacion.compareTo(b.fechaCreacion);
      });

      final seleccion = data.length > 10 ? data.sublist(0, 10) : data;
      if (!mounted) return;
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

  Future<void> _consumirVida() async {
    if (_userId == null) return;
    final nueva = (lives - 1).clamp(0, 5);
    setState(() => lives = nueva);
    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).update({'vidas': nueva});
  }

  void _onResult(bool isCorrect, String r) {
    if (!mounted) return;
    setState(() {
      answered = true;
      correcto = isCorrect;
      retro = r;
    });
    if (!isCorrect && lives > 0) {
      _consumirVida();
    }
  }

  void _siguiente() {
    if (lives == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    if (index + 1 >= preguntas.length) {
      Navigator.of(context).pop(true);
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
    Future<bool> confirmExit() async {
      return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Salir de la leccion'),
              content: const Text('Perderas tu progreso actual. Deseas salir?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (sinVidas) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF283347),
          title: Text(widget.leccionTitulo),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes vidas disponibles. Recarga vidas para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2C1B0E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final exit = await confirmExit();
        if (exit && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFF283347),
          elevation: 0,
          title: Text(
            widget.leccionTitulo,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final exit = await confirmExit();
              if (exit && mounted) Navigator.pop(context);
            },
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EEF7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book, color: Color(0xFF283347)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.leccionTitulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2C1B0E),
                                ),
                              ),
                              const SizedBox(height: 4),
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
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                              child: Icon(
                                Icons.favorite,
                                color: i < lives ? const Color(0xFFFFA451) : Colors.black26,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progreso ${((progreso) * 100).round()}%',
                          style: const TextStyle(
                            color: Color(0xFF2C1B0E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFFFA451).withOpacity(0.15),
                            color: const Color(0xFFFFA451),
                          ),
                        ),
                      ],
                    ),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
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
                      child: KeyedSubtree(
                        key: ValueKey(pregunta.id),
                        child: buildQuestionWidget(
                          pregunta: pregunta,
                          onResult: _onResult,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (answered)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: correcto ? const Color(0xFFE8F9E5) : const Color(0xFFFFE6E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: correcto ? const Color(0xFF3FB07F) : const Color(0xFFE57373),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              color:
                                  correcto ? const Color(0xFF1D6647) : const Color(0xFFB02A2A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: answered ? _siguiente : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answered ? const Color(0xFFFFA451) : Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: answered ? 3 : 0,
                    ),
                    child: Text(
                      index + 1 >= preguntas.length || lives == 0 ? 'Finalizar' : 'Siguiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
