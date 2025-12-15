// lib/presentation/screens/student/aprende/leccion_curso_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/pregunta_model.dart';
import 'test/widgets/pregunta_widget_builder.dart';

class LeccionCursoScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;
  final String leccionTitulo;
  final Color accentColor;
  final int cursoOrden;

  const LeccionCursoScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
    required this.leccionTitulo,
    this.accentColor = const Color(0xFFFFA451),
    this.cursoOrden = 1,
  });

  @override
  State<LeccionCursoScreen> createState() => _LeccionCursoScreenState();
}

class _LeccionCursoScreenState extends State<LeccionCursoScreen> {
  List<Pregunta> preguntas = [];
  int index = 0;
  int lives = 5;
  int _aciertos = 0;
  bool cargando = true;
  bool answered = false;
  bool correcto = false;
  String retro = '';
  String? _userId;
  bool sinVidas = false;
  int _xpPendiente = 0;
  String _leccionImage = 'assets/images/mascota/leccion1.png';

  bool get _esTestFinal => widget.leccionTitulo.toLowerCase().contains('test final');

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _leccionImage = _randomLeccionImage();
    _initData();
  }

  String _randomLeccionImage() {
    final imgs = [
      'assets/images/mascota/leccion1.png',
      'assets/images/mascota/leccion2.png',
      'assets/images/mascota/leccion3.png',
      'assets/images/mascota/leccion4.png',
    ];
    imgs.shuffle();
    return imgs.first;
  }

  Future<void> _initData() async {
    await _cargarVidas();
    if (!mounted) return;
    if (lives <= 0 && !_esTestFinal) {
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
    if (_esTestFinal) return;
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
      _aciertos++;
      _xpPendiente += _xpPorDificultad(preguntaActual.dificultad);
    } else if (lives > 0 && !_esTestFinal) {
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

  Future<void> _registrarResultadoFinal(bool aprobado) async {
    if (_userId == null) return;
    final cursoData = <String, dynamic>{
      'ultima_actualizacion': FieldValue.serverTimestamp(),
      'final_aprobado': aprobado,
      'final_score': _aciertos,
      'orden': widget.cursoOrden,
    };
    if (aprobado) {
      cursoData['completadas'] = FieldValue.arrayUnion([widget.leccionTitulo]);
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set(
        {
          'progreso': {
            widget.cursoId: cursoData,
          },
          if (aprobado) 'curso_actual': widget.cursoId,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // si falla, se puede reintentar en otro intento
    }
  }

  Future<void> _mostrarResultadoFinal(bool aprobado) async {
    if (!mounted) return;
    final puntaje = '$_aciertos/${preguntas.length}';
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(aprobado ? '¡Test aprobado!' : 'Test no aprobado'),
        content: Text(
          aprobado
              ? 'Superaste el test final con puntaje $puntaje. Aprobado: ganaste una medalla y desbloqueaste el siguiente curso.'
              : 'Necesitas al menos 7 aciertos. Vuelve y practica las lecciones para reintentar el test final.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _siguiente() async {
    if (lives == 0 && !_esTestFinal) {
      Navigator.of(context).pop(false);
      return;
    }
    if (index + 1 >= preguntas.length) {
      final aprobado = !_esTestFinal || _aciertos >= 7;
      if (aprobado) {
        await _guardarXpPendiente();
        if (_esTestFinal) {
          await _registrarResultadoFinal(true);
          await _mostrarResultadoFinal(true);
        } else {
          await _marcarLeccionCompletada();
        }
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (_esTestFinal) {
          await _registrarResultadoFinal(false);
          await _mostrarResultadoFinal(false);
          if (mounted) Navigator.of(context).pop(false);
        } else if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Necesitas 7 aciertos'),
              content: const Text(
                'Responde al menos 7 preguntas correctas para pasar al siguiente curso.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
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
    const Color tomato = Color(0xFFFFA451);
    final Color accentSoft = widget.accentColor.withOpacity(0.20);

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentSoft, const Color(0xFFFCF8F2)],
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cursoNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Color(0xFF2C1B0E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.leccionTitulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF4A3A2A),
                                ),
                              ),
                            ],
                          ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        _leccionImage,
                        width: 118,
                        height: 118,
                        fit: BoxFit.contain,
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
                  child: Row(
                    children: [
                      Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 5,
                          backgroundColor: tomato.withOpacity(0.15),
                          color: tomato,
                        ),
                      ),
                    ),
                    if (!_esTestFinal) ...[
                      const SizedBox(width: 10),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            child: Icon(
                              Icons.favorite,
                              color: i < lives ? tomato : Colors.black26,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: tomato.withOpacity(0.14),
                                
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_xpPorDificultad(pregunta.dificultad)} XP',
                                style: const TextStyle(
                                  color: Color(0xFF2C1B0E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          KeyedSubtree(
                            key: ValueKey(pregunta.id),
                            child: buildQuestionWidget(
                              pregunta: pregunta,
                              onResult: (ok, mensaje) => _onResult(ok, mensaje, pregunta),
                            ),
                          ),
                        ],
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
