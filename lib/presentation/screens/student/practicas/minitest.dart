import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/pregunta_model.dart';
import '../aprende/test/widgets/pregunta_widget_builder.dart';

class MiniTestScreen extends StatefulWidget {
  final String? cursoId;
  final String? cursoNombre;
  final String? leccionNombre;
  final List<String>? dificultades;

  const MiniTestScreen({
    super.key,
    this.cursoId,
    this.cursoNombre,
    this.leccionNombre,
    this.dificultades,
  });

  @override
  State<MiniTestScreen> createState() => _MiniTestScreenState();
}

class _MiniTestScreenState extends State<MiniTestScreen> {
  List<Pregunta> preguntas = [];
  bool cargando = true;
  int _index = 0;
  int _aciertos = 0;
  bool locked = false;
  bool? fueCorrecto;
  String retro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      Query query = FirebaseFirestore.instance.collection('banco_preguntas').limit(60);
      if (widget.cursoId != null && widget.cursoId!.isNotEmpty) {
        query = query.where('cursoId', isEqualTo: widget.cursoId);
      }
      if (widget.dificultades != null && widget.dificultades!.isNotEmpty) {
        final base = widget.dificultades!;
        // Incluimos variaciones con y sin acento / mayÃƒÂºsculas para que coincida con el campo de Firestore.
        final variations = <String>{};
        for (final d in base) {
          variations.add(d);
          variations.add(d.toLowerCase());
          variations.add(d.toUpperCase());
          variations.add(d.replaceAll('ÃƒÂ­', 'i'));
          variations.add(d.replaceAll('ÃƒÂ', 'I'));
        }
        final listDiffs = variations.take(10).toList();
        query = query.where('dificultad', whereIn: listDiffs);
      }
      final snap = await query.get();
      var list = snap.docs.map((d) => Pregunta.fromDoc(d)).toList();

      // Si es un desafio (se envian dificultades), no quitar el filtro: mostrar vacio si no hay preguntas.
      if (list.isEmpty) {
        // segundo intento sin filtro de dificultad si no se encontro nada
        Query fallback = FirebaseFirestore.instance.collection('banco_preguntas').limit(60);
        if (widget.cursoId != null && widget.cursoId!.isNotEmpty) {
          fallback = fallback.where('cursoId', isEqualTo: widget.cursoId);
        }
        final snapAll = await fallback.get();
        list = snapAll.docs.map((d) => Pregunta.fromDoc(d)).toList();
      }
      if (list.isEmpty) {
        final snapAll = await FirebaseFirestore.instance.collection('banco_preguntas').limit(60).get();
        list = snapAll.docs.map((d) => Pregunta.fromDoc(d)).toList();
      }
      list.shuffle();
      setState(() {
        preguntas = list.take(5).toList();
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

  void _siguiente() {
    if (_index + 1 >= preguntas.length) {
      final aprobado = _aciertos >= preguntas.length;
      _mostrarFinal(aprobado: aprobado);
      return;
    }
    setState(() {
      _index++;
      locked = false;
      fueCorrecto = null;
      retro = '';
    });
  }

    Future<void> _mostrarFinal({required bool aprobado}) async {
    if (aprobado) {
      await _restaurarVidas();
    }
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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  aprobado ? 'assets/images/medallas/curso1.png' : 'assets/images/mascota/leccion2.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                aprobado ? '¡Lo lograste!' : 'Lo lograste, continúa así',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: aprobado ? const Color(0xFF166534) : const Color(0xFFB02A2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                aprobado
                    ? 'Completaste el desafío y restauraste todas tus vidas.'
                    : 'Sigue practicando: responde todas correctamente para restaurar tus vidas.',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: aprobado ? const Color(0xFF16A34A) : const Color(0xFFB02A2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    aprobado ? 'Continuar' : 'Seguir practicando',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop(aprobado);
  }

  Future<void> _ganarVidas(int cantidad) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final snap = await ref.get();
      final data = snap.data() ?? {};
      final actuales = (data['vidas'] as num?)?.toInt() ?? 0;
      final nuevas = (actuales + cantidad).clamp(0, 5);
      await ref.update({'vidas': nuevas});
    } catch (_) {
      // si falla, solo omitimos la actualizacion
    }
  }

  Future<void> _restaurarVidas() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({'vidas': 5});
    } catch (_) {
      // omitimos error silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }
    if (preguntas.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No hay preguntas de refuerzo disponibles.')),
      );
    }

    final p = preguntas[_index];
    final tema = (widget.cursoNombre?.isNotEmpty == true) ? widget.cursoNombre! : 'Curso';
    const Color accent = Color(0xFF1E2433);
    const Color banner = Color(0xFFFFA451);

    return WillPopScope(
      onWillPop: () async {
        final salir = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/mascota/leccion2.png',
                      width: 160,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Seguro que deseas salir?',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF1E2433),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Perderás el progreso de este minitest.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Continuar',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA451),
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
        );
        return salir ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF8F2),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E2433), Color(0xFF2F3A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              'Mini lección',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
            ),
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [banner.withOpacity(0.95), banner.withOpacity(0.78)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: banner.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/mascota/refuerzo2.png',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tema,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.leccionNombre?.isNotEmpty == true ? widget.leccionNombre! : 'Refuerzo',
                              style: const TextStyle(
                                color: Color(0xFFFFF0E0),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_index + 1}/5',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E2433),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: Colors.black.withOpacity(0.02)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA451).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFFA451).withOpacity(0.28)),
                                  ),
                                  child: Text(
                                    'Dificultad: ${p.dificultad ?? 'Pendiente'}',
                                    style: const TextStyle(
                                      color: Color(0xFF2C1B0E),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              KeyedSubtree(
                                key: ValueKey(p.id ?? _index),
                                child: buildQuestionWidget(
                                  pregunta: p,
                                  onResult: (ok, r) {
                                    setState(() {
                                      locked = true;
                                      fueCorrecto = ok;
                                      retro = r;
                                      if (ok) _aciertos++;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (locked)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: fueCorrecto == true ? const Color(0xFFE8F9E5) : const Color(0xFFFFE6E6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: fueCorrecto == true ? const Color(0xFF3FB07F) : const Color(0xFFE57373),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    fueCorrecto == true ? Icons.check_circle : Icons.error_outline,
                                    color: fueCorrecto == true ? const Color(0xFF2E8E62) : const Color(0xFFB53A3A),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      retro.isNotEmpty
                                          ? retro
                                          : (fueCorrecto == true ? 'Respuesta correcta' : 'Respuesta incorrecta'),
                                      style: TextStyle(
                                        color: fueCorrecto == true
                                            ? const Color(0xFF1D6647)
                                            : const Color(0xFFB02A2A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: locked ? _siguiente : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA451),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _index + 1 >= preguntas.length ? 'Finalizar' : 'Siguiente',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
