// lib/presentation/screens/student/aprende/curso_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leccion_curso_screen.dart';

class CursoScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;
  final String descripcion;
  final String iconPath;
  final int cursoOrden;

  const CursoScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
    required this.descripcion,
    this.iconPath = 'assets/gif/cursoG1.gif',
    this.cursoOrden = 1,
  });

  const CursoScreen.placeholder({super.key})
      : cursoId = '',
        cursoNombre = 'Curso',
        descripcion = '',
        iconPath = 'assets/gif/cursoG1.gif',
        cursoOrden = 1;

  @override
  State<CursoScreen> createState() => _CursoScreenState();
}

class _CursoScreenState extends State<CursoScreen> {
  final List<_Lesson> lessons = const [
    _Lesson(title: 'Leccion 1', detail: 'Conceptos básicos'),
    _Lesson(title: 'Leccion 2', detail: 'Práctica guiada'),
    _Lesson(title: 'Leccion 3', detail: 'Desafío final'),
  ];

  late List<bool> _completed;
  int _lives = 5;
  String? _userId;
  bool _finalAprobado = false;
  int _finalScore = 0;

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(lessons.length, false);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadLives();
    _loadProgress();
    Future.microtask(_mostrarMotivacion);
  }

  Future<void> _loadLives() async {
    if (_userId == null) return;
    final snap =
        await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    final vidas = (data['vidas'] as num?)?.toInt();
    if (vidas != null && mounted) {
      setState(() {
        _lives = vidas.clamp(0, 5);
      });
    }
  }

  Future<void> _mostrarMotivacion() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/mascota/refuerzo1.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Vamos por este curso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comienza fuerte: cada lección te acerca a tu meta. ¡Tú puedes!',
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
                    backgroundColor: const Color(0xFFFFA451),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Comenzar',
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

  Future<void> _loadProgress() async {
    if (_userId == null) return;
    final snap =
        await FirebaseFirestore.instance.collection('usuarios').doc(_userId).get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    final progreso = (data['progreso'] as Map?) ?? {};
    final cursoProg = (progreso[widget.cursoId] as Map?) ?? {};
    final completadas = (cursoProg['completadas'] as List?)?.cast<String>() ?? [];
    final finalScore = (cursoProg['final_score'] as num?)?.toInt() ?? 0;
    final finalAprobado = cursoProg['final_aprobado'] == true && finalScore >= 7;

    if (mounted) {
      setState(() {
        _completed = lessons
            .map((l) => completadas.contains(l.title))
            .toList(growable: false);
        _finalAprobado = finalAprobado;
        _finalScore = finalScore;
      });
    }
  }

  Future<void> _marcarLeccionCompletada(int indexLesson) async {
    if (_userId == null) return;
    final titulo = lessons[indexLesson].title;
    if (mounted) {
      setState(() => _completed[indexLesson] = true);
    }
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_userId).set(
        {
          'progreso': {
            widget.cursoId: {
              'completadas': FieldValue.arrayUnion([titulo]),
              'ultima_actualizacion': FieldValue.serverTimestamp(),
            },
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Si falla, mantenemos el estado local y se reintentara despues.
    }
  }

  Future<void> _openLesson(int i) async {
    await _loadLives();
    if (_lives <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes vidas disponibles. Recarga para continuar.'),
        ),
      );
      return;
    }
    final unlocked = i == 0 ? true : _completed[i - 1];
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa la lección anterior para continuar.'),
        ),
      );
      return;
    }

    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeccionCursoScreen(
          cursoId: widget.cursoId,
          cursoNombre: widget.cursoNombre,
          leccionTitulo: lessons[i].title,
          cursoOrden: widget.cursoOrden,
          accentColor: _lessonPalette(i).first,
        ),
      ),
    );

    if (res == true && mounted) {
      await _marcarLeccionCompletada(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tomato = Color(0xFFFF8A3D);
    final progreso = _completed.where((c) => c).length / lessons.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF283347),
        foregroundColor: Colors.white,
        title: Text(
          widget.cursoNombre,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 78,
                            height: 78,
                            child: Image.asset(
                              widget.iconPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.cursoNombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C1B0E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.descripcion,
                        style: const TextStyle(
                          color: Color(0xFF5A5248),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _chip(Icons.extension, '3 lecciones'),
                          const SizedBox(width: 8),
                          _chip(Icons.local_fire_department, 'Modo activo'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 14),
                const Text(
                  'Lecciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C1B0E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Avanza paso a paso. Cada lección desbloquea la siguiente.',
                  style: TextStyle(
                    color: Color(0xFF5A5248),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = lessons[i];
                      final palette = _lessonPalette(i);
                      final unlocked = i == 0 ? true : _completed[i - 1];
                      final done = _completed[i];
                      return GestureDetector(
                        onTap: () => _openLesson(i),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: palette,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: unlocked
                                  ? const Color(0xFF283347).withOpacity(0.08)
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: Icon(
                                  done
                                      ? Icons.check_circle_rounded
                                      : unlocked
                                          ? Icons.play_arrow_rounded
                                          : Icons.lock_outline,
                                  color: done
                                      ? const Color(0xFF2E7D32)
                                      : unlocked
                                          ? tomato
                                          : const Color(0xFF7A6A5C),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayLeccionTitle(item.title),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF2C1B0E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.detail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unlocked ? const Color(0xFF5A5248) : const Color(0xFF7A6A5C),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _LessonStatusChip(
                                done: done,
                                unlocked: unlocked,
                                tomato: tomato,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _finalAprobado ? Icons.emoji_events_rounded : Icons.quiz,
                      color: Colors.white,
                    ),
                    label: Text(
                      _finalAprobado ? 'Repetir test final' : 'Test final',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _finalAprobado ? const Color(0xFF2E7D32) : tomato,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                  ),
                    onPressed: () async {
                      await _loadLives();
                      final allLessonsDone = _completed.every((e) => e);
                      if (!allLessonsDone) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa todas las lecciones antes de hacer el test final.'),
                          ),
                        );
                        return;
                      }
                      if (_lives <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No tienes vidas disponibles. Recarga para continuar.'),
                          ),
                        );
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeccionCursoScreen(
                            cursoId: widget.cursoId,
                            cursoNombre: widget.cursoNombre,
                            leccionTitulo: 'Test final',
                            cursoOrden: widget.cursoOrden,
                            accentColor: tomato,
                          ),
                        ),
                      );
                      _loadLives();
                      _loadProgress();
                    },
                  ),
                ),
                if (_finalAprobado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Aprobaste el test final (puntaje: $_finalScore).',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayLeccionTitle(String title) {
    if (title.startsWith('Leccion')) {
      return title.replaceFirst('Leccion', 'Lección');
    }
    return title;
  }

  List<Color> _lessonPalette(int index) {
    const palettes = [
      [Color(0xFF1BA6A8), Color(0xFF8FE8EA)],
      [Color(0xFFFFDFA6), Color(0xFFF6C778)],
      [Color(0xFFDDF1C8), Color(0xFFB7E29A)],
      [Color(0xFFFFE6E6), Color(0xFFFFF0F0)],
    ];
    return palettes[index % palettes.length];
  }
}

class _Lesson {
  final String title;
  final String detail;
  const _Lesson({required this.title, required this.detail});
}

class _LessonStatusChip extends StatefulWidget {
  final bool done;
  final bool unlocked;
  final Color tomato;

  const _LessonStatusChip({
    required this.done,
    required this.unlocked,
    required this.tomato,
  });

  @override
  State<_LessonStatusChip> createState() => _LessonStatusChipState();
}

class _LessonStatusChipState extends State<_LessonStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    final unlocked = widget.unlocked;
    final textColor = done
        ? const Color(0xFF2E7D32)
        : unlocked
            ? const Color(0xFF2C1B0E)
            : const Color(0xFF7A6A5C);
    final iconColor = done
        ? const Color(0xFF2E7D32)
        : unlocked
            ? widget.tomato
            : const Color(0xFF7A6A5C);
    final label = done
        ? 'Completado'
        : unlocked
            ? 'Disponible'
            : 'Bloqueado';
    final icon = done
        ? Icons.check_circle
        : unlocked
            ? Icons.arrow_forward_ios
            : Icons.lock_outline;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final offsetY = (unlocked || done) ? _float.value : 0.0;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFE8F9E5) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? const Color(0xFF3FB07F).withOpacity(0.6)
                : const Color(0xFF283347).withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _chip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F5FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withOpacity(0.03)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF8A3D)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF283347),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

