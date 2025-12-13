// lib/presentation/screens/student/aprende/leccion_curso_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/pregunta_model.dart';
import 'test/widgets/pregunta_widget_builder.dart';

class LeccionCursoScreen extends StatefulWidget {
  final String cursoId;
  final String leccionTitulo;
  final Color accentColor;

  const LeccionCursoScreen({
    super.key,
    required this.cursoId,
    required this.leccionTitulo,
    this.accentColor = const Color(0xFFFFA451),
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
  int _xpPendiente = 0;

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

      // Seleccion aleatoria sin repeticion, priorizando variedad de dificultad
      const niveles = ['Muy facil', 'Facil', 'Medio', 'Dificil', 'Muy dificil'];
      final Map<String, List<Pregunta>> porNivel = {
        for (final n in niveles) n: [],
      };
      for (final p in data) {
        final d = p.dificultad;
        if (porNivel.containsKey(d)) {
          porNivel[d]!.add(p);
        } else {
          porNivel.putIfAbsent(d, () => []).add(p);
        }
      }
      // barajar cada nivel
      for (final list in porNivel.values) {
        list.shuffle();
      }
      final seleccion = <Pregunta>[];
      // Tomar hasta 2 por nivel en orden de dificultad
      for (final n in niveles) {
        final list = porNivel[n] ?? [];
        seleccion.addAll(list.take(2));
        if (seleccion.length >= 10) break;
      }
      // Rellenar si faltan con el resto mezclado
      if (seleccion.length < 10) {
        final restantes = porNivel.values.expand((e) => e).toList();
        restantes.shuffle();
        for (final p in restantes) {
          if (seleccion.length >= 10) break;
          if (!seleccion.any((sel) => sel.id == p.id)) {
            seleccion.add(p);
          }
        }
      }
      seleccion.shuffle();

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

  void _onResult(bool isCorrect, String r, Pregunta preguntaActual) {
    if (!mounted) return;
    setState(() {
      answered = true;
      correcto = isCorrect;
      retro = r;
    });
    if (isCorrect) {
      _xpPendiente += _xpPorDificultad(preguntaActual.dificultad);
    } else if (lives > 0) {
      _consumirVida();
    }
  }

  Future<void> _guardarXpPendiente() async {
    if (_userId == null || _xpPendiente <= 0) return;
    final pending = _xpPendiente;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userId)
          .update({'xp_acumulada': FieldValue.increment(pending)});
      _xpPendiente = 0;
    } catch (_) {
      // Si falla, mantenemos el acumulado para reintentar en la siguiente sesion
    }
  }

  Future<void> _marcarLeccionCompletada() async {
    if (_userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set(
        {
          'progreso': {
            widget.cursoId: {
              'completadas': FieldValue.arrayUnion([widget.leccionTitulo]),
              'ultima_actualizacion': FieldValue.serverTimestamp(),
            },
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // si falla, no bloqueamos la salida; se puede reintentar en otra sesion
    }
  }

  Future<void> _siguiente() async {
    if (lives == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    if (index + 1 >= preguntas.length) {
      await _guardarXpPendiente();
      await _marcarLeccionCompletada();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    setState(() {
      index++;
      answered = false;
      correcto = false;
      retro = '';
    });
  }

  int _xpPorDificultad(String? dif) {
    final d = (dif ?? '').toLowerCase();
    if (d.contains('muy dificil')) return 120;
    if (d.contains('dificil')) return 100;
    if (d.contains('medio')) return 70;
    if (d.contains('facil')) return 50;
    return 30; // muy facil u otro
  }

  @override
  Widget build(BuildContext context) {
    const tomato = Color(0xFFFFA451);

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
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF283347), Color(0xFF1E2433)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () async {
                    final exit = await confirmExit();
                    if (exit && mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.leccionTitulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.menu_book, color: widget.accentColor),
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progreso',
                          style: TextStyle(
                            color: Color(0xFF2C1B0E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((progreso) * 100).round()}% completado',
                          style: const TextStyle(
                            color: Color(0xFF5A5248),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progreso,
                            minHeight: 8,
                            backgroundColor: tomato.withOpacity(0.15),
                            color: tomato,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _infoChip(
                          icon: Icons.star_border,
                          label: '${_xpPorDificultad(pregunta.dificultad)} XP',
                          color: tomato,
                        ),
                        const SizedBox(width: 10),
                        _infoChip(
                          icon: Icons.favorite,
                          label: '$lives vidas',
                          color: const Color(0xFFFF6A3D),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                          onResult: (ok, mensaje) => _onResult(ok, mensaje, pregunta),
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
                        backgroundColor: answered ? tomato : Colors.black26,
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

class _infoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _infoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF2C1B0E),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
