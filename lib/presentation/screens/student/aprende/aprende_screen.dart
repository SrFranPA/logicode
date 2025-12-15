// lib/presentation/screens/student/aprende/aprende_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'curso_screen.dart';

class AprendeScreen extends StatelessWidget {
  const AprendeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('usuarios').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final user = userSnap.data?.data() ?? <String, dynamic>{};
        final cursoActualId = (user['curso_actual'] ?? '').toString();
        final pretestEstado = (user['pretest_estado'] ?? 'pendiente').toString();
        final bool testAprobado = pretestEstado == 'aprobado';
        final Map progresoCursos = (user['progreso'] as Map?) ?? {};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('cursos').orderBy('orden').snapshots(),
          builder: (context, cursosSnap) {
            if (!cursosSnap.hasData) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final cursos = cursosSnap.data!.docs;

            int unlockedUntilOrder = 1;
            int highestApprovedOrder = 0;
            int cursoActualOrder = 0;

            for (final c in cursos) {
              final data = c.data();
              final orden = (data['orden'] as num?)?.toInt() ?? 1;

              if (c.id == cursoActualId) {
                cursoActualOrder = orden;
              }

              final progresoCurso = (progresoCursos[c.id] as Map?) ?? {};
              final finalScore = (progresoCurso['final_score'] as num?)?.toInt() ?? 0;
              final finalAprobado = progresoCurso['final_aprobado'] == true && finalScore >= 7;
              if (finalAprobado && orden > highestApprovedOrder) {
                highestApprovedOrder = orden;
              }
            }

            if (highestApprovedOrder > 0) {
              unlockedUntilOrder = highestApprovedOrder + 1;
            } else if (cursoActualOrder > 0) {
              unlockedUntilOrder = cursoActualOrder + 1;
            }

            return Container(
              color: const Color(0xFFFEF6ED),
              width: double.infinity,
              child: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFF7F1E3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 10,
                                offset: Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF2B46D).withOpacity(0.16)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(0xFFE38B2F),
                                    child: Icon(Icons.flag, color: Colors.white, size: 18),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Elige un curso y avanza en tu laboratorio. Cada modulo desbloquea el siguiente.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.3,
                                        color: Color(0xFF2C3B4A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!testAprobado) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE7C899)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD9B3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.lock_outline, color: Color(0xFFE07A1E)),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Completa el test inicial para desbloquear tus cursos.',
                                        style: TextStyle(
                                          color: Color(0xFF8A5A2F),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE07A1E),
                                      minimumSize: const Size(double.infinity, 62),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 16,
                                      ),
                                      elevation: 8,
                                      shadowColor: const Color(0xFFE07A1E).withOpacity(0.35),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/pretest');
                                    },
                                    icon: const Icon(
                                      Icons.assignment_turned_in,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      'Realizar test',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontSize: 18,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Completar el test inicial desbloquea todo el contenido.',
                                  style: TextStyle(
                                    color: Color(0xFF6B5332),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFFBF2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF8CCFA6).withOpacity(0.5),
                                  ),
                                ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Color(0xFF1E88E5)),
                                      SizedBox(width: 8),
                                      Expanded(
                                  child: Text(
                                    'Test completado. Explora los cursos disponibles.',
                                    style: TextStyle(
                                      color: Color(0xFF1E4D2E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (testAprobado)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 42),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = cursos[index];
                              final data = doc.data();
                              final nombreCurso = (data['nombre'] ?? 'Curso').toString();
                              final descripcion = (data['descripcion'] ?? '').toString();
                              final orden = (data['orden'] as num?)?.toInt() ?? 1;
                              final progresoCurso = (progresoCursos[doc.id] as Map?) ?? {};
                              final finalScore = (progresoCurso['final_score'] as num?)?.toInt() ?? 0;
                              final finalAprobado = progresoCurso['final_aprobado'] == true && finalScore >= 7;

                              final unlocked = testAprobado && orden <= unlockedUntilOrder;
                              final isCurrent = doc.id == cursoActualId;

                              return _CourseCard(
                                index: index,
                                title: nombreCurso,
                                description: descripcion.isEmpty
                                    ? 'Conceptos clave y ejercicios interactivos.'
                                    : descripcion,
                                unlocked: unlocked,
                                highlight: isCurrent,
                                aprobado: finalAprobado,
                                onTap: () {
                                  if (!unlocked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Debes aprobar el curso anterior (test final >= 7) para desbloquear este contenido.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CursoScreen(
                                        cursoId: doc.id,
                                        cursoNombre: nombreCurso,
                                        descripcion: descripcion.isEmpty
                                            ? 'Conceptos clave y ejercicios interactivos.'
                                            : descripcion,
                                        cursoOrden: orden,
                                        iconPath: 'assets/images/iconos/curso${(index % 9) + 1}.png',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: cursos.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatefulWidget {
  final int index;
  final String title;
  final String description;
  final bool unlocked;
  final bool highlight;
  final bool aprobado;
  final VoidCallback onTap;

  const _CourseCard({
    required this.index,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.highlight,
    this.aprobado = false,
    required this.onTap,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconForTitle(String t) {
    t = t.toLowerCase();
    if (t.contains('variable')) return Icons.tune;
    if (t.contains('condicion')) return Icons.code;
    if (t.contains('bucle') || t.contains('loop')) return Icons.loop;
    if (t.contains('funcion')) return Icons.extension;
    if (t.contains('arreglo') || t.contains('vector')) return Icons.view_module;
    if (t.contains('tabla')) return Icons.grid_on;
    return Icons.psychology_alt;
  }

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFF3A45C), Color(0xFFFECF9C)],
      [Color(0xFF6CC5B8), Color(0xFFB5F2E2)],
      [Color(0xFF7D8BFF), Color(0xFFB6C3FF)],
      [Color(0xFFE57373), Color(0xFFF6B1B1)],
      [Color(0xFFF4C95D), Color(0xFFFFE4A1)],
    ];

    final colors = palettes[widget.index % palettes.length];
    Color colorA = colors[0];
    Color colorB = colors[1];

    final bool disponible = widget.aprobado || widget.unlocked;
    final statusIcon = widget.aprobado
        ? Icons.emoji_events
        : widget.unlocked
            ? Icons.play_circle_fill
            : Icons.lock_outline;
    final statusLabel = widget.aprobado ? 'Aprobado' : (widget.unlocked ? 'Disponible' : 'Bloqueado');
    final statusColor = widget.aprobado
        ? const Color(0xFF8B5E1A)
        : (widget.unlocked ? const Color(0xFF0F172A) : const Color(0xFF4B5563));

    if (!disponible) {
      colorA = const Color(0xFFE8E8E8);
      colorB = const Color(0xFFF6F6F6);
    }

    final iconPath = 'assets/images/iconos/curso${(widget.index % 9) + 1}.png';

    return GestureDetector(
      onTapDown: (_) {
        if (widget.unlocked) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1 - _controller.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorA, colorB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
            ),
          ),
         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
         child: Row(
            children: widget.index.isEven
                ? [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1F2A44)
                                  .withOpacity(disponible ? 0.95 : 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: disponible
                                  ? statusColor.withOpacity(0.14)
                                  : const Color.fromARGB(255, 245, 245, 245),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: disponible
                                    ? statusColor.withOpacity(0.35)
                                    : const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 16,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        iconPath,
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        opacity: disponible ? null : const AlwaysStoppedAnimation(0.45),
                      ),
                    ),
                  ]
                : [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        iconPath,
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                        opacity: disponible ? null : const AlwaysStoppedAnimation(0.45),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1F2A44)
                                  .withOpacity(disponible ? 0.95 : 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(disponible ? 0.22 : 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: disponible
                                    ? const Color(0xFF1F2A44).withOpacity(0.25)
                                    : const Color(0xFF8B8B8B).withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 16,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
         ),
       ),
     ),
    );
  }
}
