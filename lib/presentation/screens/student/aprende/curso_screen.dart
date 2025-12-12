// lib/presentation/screens/student/aprende/curso_screen.dart

import 'package:flutter/material.dart';

class CursoScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final lessons = [
      _Lesson(title: 'Leccion 1', detail: 'Conceptos basicos'),
      _Lesson(title: 'Leccion 2', detail: 'Practica guiada'),
      _Lesson(title: 'Leccion 3', detail: 'Desafio final'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFEF6ED),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE07A1E),
        foregroundColor: Colors.white,
        title: Text(
          cursoNombre,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
                      Text(
                        cursoNombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C1B0E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07A1E).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book, color: Color(0xFFE07A1E)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              descripcion,
                              style: const TextStyle(
                                color: Color(0xFF2C1B0E),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _chip(Icons.extension, '3 lecciones'),
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
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = lessons[i];
                      final colors = [
                        [const Color(0xFFF3A45C), const Color(0xFFFECF9C)],
                        [const Color(0xFF6CC5B8), const Color(0xFFB5F2E2)],
                        [const Color(0xFF7D8BFF), const Color(0xFFB6C3FF)],
                      ];
                      final palette = colors[i % colors.length];
                      return Container(
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
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.28),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_circle_fill, color: Color(0xFF1F2A44)),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF1F2A44),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            item.detail,
                            style: const TextStyle(color: Color(0xFF3C4A5A)),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF1F2A44),
                            size: 18,
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
