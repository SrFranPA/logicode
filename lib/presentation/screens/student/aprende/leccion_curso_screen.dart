// lib/presentation/screens/student/aprende/leccion_curso_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/pregunta_model.dart';
import '../../../../data/repositories/evaluaciones_repository.dart';
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
  late final EvaluacionesRepository _evalRepo;
  List<Pregunta> preguntas = [];
  int index = 0;
  int lives = 5;
  int _aciertos = 0;
  bool cargando = true;
  bool answered = false;
  bool correcto = false;
  String retro = '';
  double? _pretestScore10;
  String? _overrideDificultad;
  int _sinVidasCount = 0;
  bool _sinVidasRegistrado = false;
  String? _userId;
  bool sinVidas = false;
  int _xpPendiente = 0;
  String _leccionImage = 'assets/images/mascota/leccion1.png';

  bool get _esTestFinal => widget.leccionTitulo.toLowerCase().contains('test final');

  @override
  void initState() {
    super.initState();
    _evalRepo = EvaluacionesRepository(db: FirebaseFirestore.instance);
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
    await _cargarPretestScore();
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

  Future<void> _cargarPretestScore() async {
    if (_userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      final raw = (data['pretest_calificacion'] as num?)?.toDouble();
      if (raw == null) return;
      _pretestScore10 = raw / 10.0;

      final overrides = (data['leccion_dificultad_override'] as Map?)?.cast<String, dynamic>();
      final cursoOverrides = (overrides?[_cursoKey()] as Map?)?.cast<String, dynamic>();
      final override = cursoOverrides?[_leccionKey()]?.toString();
      if (override != null && override.isNotEmpty) {
        _overrideDificultad = override;
      }

      final intentos = (data['leccion_intentos_sin_vidas'] as Map?)?.cast<String, dynamic>();
      final cursoIntentos = (intentos?[_cursoKey()] as Map?)?.cast<String, dynamic>();
      final count = (cursoIntentos?[_leccionKey()] as num?)?.toInt() ?? 0;
      _sinVidasCount = count;
    } catch (_) {
      // Si falla, no bloqueamos el flujo.
    }
  }

  String _cursoKey() => widget.cursoId;
  String _leccionKey() => widget.leccionTitulo;

  int? _numeroLeccion(String titulo) {
    final match = RegExp(r'\\d+').firstMatch(titulo);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('Ãƒ¡', 'a')
        .replaceAll('ÃƒÂ©', 'e')
        .replaceAll('ÃƒÂ­', 'i')
        .replaceAll('ÃƒÂ³', 'o')
        .replaceAll('ÃƒÂº', 'u');
  }

  String? _dificultadObjetivo() {
    if (_overrideDificultad != null && _overrideDificultad!.isNotEmpty) {
      return _overrideDificultad;
    }
    final score = _pretestScore10;
    final num = _numeroLeccion(widget.leccionTitulo);
    if (score == null || num == null) return null;

    if (score > 7) {
      if (num == 1) return 'medio';
      if (num == 2) return 'dificil';
      if (num == 3) return 'muy dificil';
    } else if (score > 4) {
      if (num == 1) return 'facil';
      if (num == 2) return 'medio';
      if (num == 3) return 'dificil';
    } else {
      if (num == 1) return 'muy facil';
      if (num == 2) return 'medio';
      if (num == 3) return 'medio';
    }
    return null;
  }

  bool _matchDificultad(String? dificultad, String objetivo) {
    final d = _normalizeText(dificultad ?? '');
    final o = _normalizeText(objetivo);
    return d.contains(o);
  }

  String _bajarDificultad(String actual) {
    final orden = ['muy facil', 'facil', 'medio', 'dificil', 'muy dificil'];
    final norm = _normalizeText(actual);
    final idx = orden.indexWhere((e) => norm.contains(e));
    if (idx == -1) return 'medio';
    if (idx == 0) return orden[0];
    return orden[idx - 1];
  }

  Future<void> _registrarFalloSinVidas() async {
    if (_userId == null || _sinVidasRegistrado) return;
    _sinVidasRegistrado = true;
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      final intentos = (data['leccion_intentos_sin_vidas'] as Map?)?.cast<String, dynamic>() ?? {};
      final cursoIntentos = (intentos[_cursoKey()] as Map?)?.cast<String, dynamic>() ?? {};
      int count = (cursoIntentos[_leccionKey()] as num?)?.toInt() ?? 0;
      count += 1;

      String? newOverride;
      if (count >= 3) {
        final actual = _overrideDificultad ?? _dificultadObjetivo() ?? 'medio';
        newOverride = _bajarDificultad(actual);
        count = 0;
        _overrideDificultad = newOverride;
      }

      cursoIntentos[_leccionKey()] = count;
      intentos[_cursoKey()] = cursoIntentos;

      final update = <String, dynamic>{
        'leccion_intentos_sin_vidas': intentos,
      };

      if (newOverride != null) {
        final overrides = (data['leccion_dificultad_override'] as Map?)
                ?.cast<String, dynamic>() ??
            {};
        final cursoOverrides = (overrides[_cursoKey()] as Map?)?.cast<String, dynamic>() ?? {};
        cursoOverrides[_leccionKey()] = newOverride;
        overrides[_cursoKey()] = cursoOverrides;
        update['leccion_dificultad_override'] = overrides;
      }

      tx.update(userRef, update);
    });

    if (mounted && _overrideDificultad != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustamos la dificultad para ayudarte a avanzar.')),
      );
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

      final objetivo = _dificultadObjetivo();
      List<Pregunta> pool = data;
      if (objetivo != null) {
        final filtradas = data.where((p) => _matchDificultad(p.dificultad, objetivo)).toList();
        if (filtradas.isNotEmpty) {
          pool = filtradas;
        }
      }

      final seleccion = <Pregunta>[];
      pool.shuffle();
      seleccion.addAll(pool.take(10));

      if (seleccion.length < 10) {
        // Si no hay suficientes de la dificultad objetivo, completamos con el resto.
        final resto = data.where((p) => !seleccion.any((s) => s.id == p.id)).toList();
        resto.shuffle();
        for (final p in resto) {
          if (seleccion.length >= 10) break;
          seleccion.add(p);
        }
      }

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

  Future<int?> _consumirVida() async {
    if (_esTestFinal) return lives;
    if (_userId == null) return lives;
    final nueva = (lives - 1).clamp(0, 5);
    setState(() => lives = nueva);
    await FirebaseFirestore.instance.collection('usuarios').doc(_userId).update({'vidas': nueva});
    return nueva;
  }

  Future<void> _onResult(bool isCorrect, String r, Pregunta preguntaActual) async {
    if (!mounted) return;
    setState(() {
      answered = true;
      correcto = isCorrect;
      retro = r;
    });
    if (isCorrect) {
      _aciertos++;
      if (!_esTestFinal) {
        _xpPendiente += _xpPorDificultad(preguntaActual.dificultad);
      }
    } else if (lives > 0 && !_esTestFinal) {
      final restante = await _consumirVida() ?? lives;
      if (restante <= 0) {
        _mostrarSinVidas();
      }
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
      await _actualizarRachaPorLeccion();
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
      if (aprobado) {
        await _actualizarRachaPorLeccion();
      }
    } catch (_) {
      // si falla, se puede reintentar en otro intento
    }
  }

  Future<void> _mostrarResultadoFinal(bool aprobado) async {
    if (!mounted) return;
    final puntaje = '$_aciertos/${preguntas.length}';
    final img = aprobado
        ? 'assets/images/mascota/refuerzo2.png'
        : 'assets/images/mascota/leccion3.png';
    final mensaje = aprobado
        ? '¡Gran trabajo! Superaste el test con puntaje $puntaje. Ganaste tu medalla y desbloqueaste el siguiente curso.'
        : 'No pasa nada: necesitas 7 aciertos. Repasa tus notas, intenta de nuevo y verás cómo mejoras.';
    final motivacion = aprobado
        ? 'Sigue este ritmo, cada logro te acerca a tu meta.'
        : 'Cada intento suma. Practica y volverás más fuerte.';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: aprobado
                        ? [const Color(0xFF22C55E).withOpacity(0.18), const Color(0xFF4ADE80).withOpacity(0.3)]
                        : [const Color(0xFFF59E0B).withOpacity(0.18), const Color(0xFFFBBF24).withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: aprobado ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      img,
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: aprobado ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Text(
                        'Puntaje: $puntaje',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: aprobado ? const Color(0xFF166534) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                aprobado ? '¡Test aprobado!' : 'Sigue practicando',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: aprobado ? const Color(0xFF166534) : const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                motivacion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aprobado ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarLeccionCompletada() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/mascota/refuerzo3.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Genial, lo lograste!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sigue con la siguiente lección, tu progreso se está notando.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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
  }

  Future<void> _mostrarSinVidas() async {
    if (!mounted) return;
    await _registrarFalloSinVidas();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/mascota/leccion2.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin vidas disponibles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tómate un respiro y vuelve a intentarlo. Puedes practicar en Refuerzo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _siguiente() async {
    if (lives == 0 && !_esTestFinal) {
      await _mostrarSinVidas();
      return;
    }
    if (index + 1 >= preguntas.length) {
      final aprobado = !_esTestFinal || _aciertos >= 7;
      if (aprobado) {
        if (!_esTestFinal) {
          await _guardarXpPendiente();
        }
        if (_esTestFinal) {
          await _guardarEvaluacionPost(aprobado: true);
          await _registrarResultadoFinal(true);
          await _mostrarResultadoFinal(true);
        } else {
          await _marcarLeccionCompletada();
          await _mostrarLeccionCompletada();
        }
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (_esTestFinal) {
          await _guardarEvaluacionPost(aprobado: false);
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

  Future<void> _guardarEvaluacionPost({required bool aprobado}) async {
    if (!_esTestFinal || _userId == null) return;
    final totalPreguntas = preguntas.length;
    final bancoIds = preguntas.map((p) => p.id ?? '').toList();
    final porcentaje = totalPreguntas > 0 ? (_aciertos * 100.0 / totalPreguntas) : 0.0;
    try {
      await _evalRepo.registrarEvaluacion(
        uid: _userId!,
        tipo: 'post',
        puntajeObtenido: _aciertos,
        puntajeMinimo: 0,
        puntajeMaximo: totalPreguntas,
        numPreguntas: totalPreguntas,
        bancoPreguntasIds: bancoIds,
        detalle: {
          'cursoId': widget.cursoId,
          'cursoNombre': widget.cursoNombre,
          'leccion': widget.leccionTitulo,
          'aprobado': aprobado,
        },
      );
    } catch (_) {
      // Si falla el detalle, igual guardamos la nota en el perfil.
    }

    try {
      await _guardarVectorFinal(porcentaje);
    } catch (_) {
      // No bloqueamos la UX si falla el guardado.
    }
  }

  Future<void> _actualizarRachaPorLeccion() async {
    if (_userId == null) return;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    int racha = (data['racha'] as num?)?.toInt() ?? 0;
    final lastTs = data['ultima_racha'];
    DateTime? last;
    if (lastTs is Timestamp) {
      last = lastTs.toDate();
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final lastDate = (last != null) ? DateTime(last.year, last.month, last.day) : null;

    bool changed = false;
    if (lastDate == null) {
      racha = 1;
      changed = true;
    } else {
      final diffDays = todayDate.difference(lastDate).inDays;
      if (diffDays == 0) {
        // mismo dia, no cambia
      } else if (diffDays == 1) {
        racha += 1;
        changed = true;
      } else if (diffDays > 1) {
        racha = 1;
        changed = true;
      }
    }

    if (changed) {
      await docRef.update({
        'racha': racha,
        'ultima_racha': Timestamp.fromDate(now),
        'ultima_leccion_completada': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> _guardarVectorFinal(double porcentaje) async {
    if (_userId == null || widget.cursoOrden <= 0) return;
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};
      final List<dynamic> actual = (data['postest_calificaciones'] as List?) ?? [];
      final List<double> valores = actual.map((e) => (e as num?)?.toDouble() ?? 0.0).toList();
      final index = widget.cursoOrden - 1;
      if (valores.length <= index) {
        valores.addAll(List<double>.filled(index + 1 - valores.length, 0.0));
      }
      valores[index] = porcentaje;
      tx.update(userRef, {'postest_calificaciones': valores});
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

  String _displayLeccionTitle(String title) {
    if (title.startsWith('Leccion')) {
      return title.replaceFirst('Leccion', 'Lección');
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    const Color tomato = Color(0xFFFFA451);
    final Color accentSoft = widget.accentColor.withOpacity(0.20);
    final displayLeccion = _displayLeccionTitle(widget.leccionTitulo);

    Future<bool> confirmExit() async {
      return await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7D2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/images/mascota/salida1.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Salir de la lección',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF2C1B0E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Perderás tu progreso actual. ¿Quieres salir?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4B4F56),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B4F3B),
                              side: const BorderSide(color: Color(0xFFE1C4A8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A3D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF283347),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
          title: Text(displayLeccion),
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
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF283347),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
          title: Text(displayLeccion),
        ),
        body: const Center(
          child: Text(
            'No hay preguntas para esta lección.',
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
            systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: const Color(0xFF283347),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
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
                        displayLeccion,
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
                                displayLeccion,
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
              if (_esTestFinal)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2433), Color(0xFF2F3A4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Desafío final',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Responde con calma: este reto libera tu medalla y el siguiente curso.',
                              style: TextStyle(
                                color: Color(0xFFE6EAF5),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/mascota/refuerzo2.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_esTestFinal) const SizedBox(height: 12),
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

