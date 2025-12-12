// lib/presentation/screens/student/aprende/curso_screen.dart

import 'package:flutter/material.dart';
import 'leccion_curso_screen.dart';

class CursoScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;
  final String descripcion;

  const CursoScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
    required this.descripcion,
  });

  @override
  State<CursoScreen> createState() => _CursoScreenState();
}

class _CursoScreenState extends State<CursoScreen> {
  final List<_Lesson> lessons = const [
    _Lesson(title: 'Leccion 1', detail: 'Conceptos basicos'),
    _Lesson(title: 'Leccion 2', detail: 'Practica guiada'),
    _Lesson(title: 'Leccion 3', detail: 'Desafio final'),
  ];

  late List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(lessons.length, false);
  }

  Future<void> _openLesson(int i) async {
    final unlocked = i == 0 ? true : _completed[i - 1];
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa la leccion anterior para continuar.'),
        ),
      );
      return;
    }

    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeccionCursoScreen(
          cursoId: widget.cursoId,
          leccionTitulo: lessons[i].title,
        ),
      ),
    );

    if (res == true && mounted) {
      setState(() {
        _completed[i] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF6ED),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE07A1E),
        foregroundColor: Colors.white,
        title: Text(
          widget.cursoNombre,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEF6ED), Color(0xFFE7F2FF)],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE0B8), Color(0xFFE5F4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE07A1E).withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.28),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book, color: Color(0xFFE07A1E)),
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
                          color: Color(0xFF4A3B2D),
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
                  'Avanza paso a paso. Cada leccion desbloquea la siguiente.',
                  style: TextStyle(
                    color: Color(0xFF6A5645),
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
                      final colors = [
                        [const Color(0xFFF3A45C), const Color(0xFFFECF9C)],
                        [const Color(0xFFC4E5FF), const Color(0xFFE3F1FF)],
                        [const Color(0xFFD8F5E5), const Color(0xFFBCE9D3)],
                        [const Color(0xFFFFD7C2), const Color(0xFFFFECDD)],
                      ];
                      final unlocked = i == 0 ? true : _completed[i - 1];
                      final done = _completed[i];
                      final palette = colors[i % colors.length];
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
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: unlocked
                                  ? const Color(0xFFE07A1E).withOpacity(0.16)
                                  : const Color(0xFFB0B0B0).withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2C1B0E)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(unlocked ? 0.55 : 0.35),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Paso ${i + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF2C1B0E),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Color(0xFF2C1B0E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.detail,
                                      style: TextStyle(
                                        color: unlocked ? const Color(0xFF5A4737) : const Color(0xFF7A6A5C),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: done
                                      ? const Color(0xFF2E7D32).withOpacity(0.12)
                                      : Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: done
                                        ? const Color(0xFF2E7D32).withOpacity(0.5)
                                        : const Color(0xFFE07A1E).withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      done
                                          ? 'Completado'
                                          : unlocked
                                              ? 'Iniciar'
                                              : 'Bloqueado',
                                      style: TextStyle(
                                        color: done
                                            ? const Color(0xFF2E7D32)
                                            : unlocked
                                                ? const Color(0xFF2C1B0E)
                                                : const Color(0xFF7A6A5C),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      done
                                          ? Icons.check_circle
                                          : unlocked
                                              ? Icons.arrow_forward_ios
                                              : Icons.lock_outline,
                                      color: done
                                          ? const Color(0xFF2E7D32)
                                          : unlocked
                                              ? const Color(0xFF2C1B0E)
                                              : const Color(0xFF7A6A5C),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _Lesson {
  final String title;
  final String detail;
  const _Lesson({required this.title, required this.detail});
}

Widget _chip(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFEEAD5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE7C899)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8D5722)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8D5722),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
