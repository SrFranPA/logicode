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
        final bool pretestCompletado = user['pretest_completado'] != null;
        final bool testAprobado = pretestCompletado || pretestEstado == 'aprobado';
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

            for (final c in cursos) {
              final data = c.data();
              final orden = (data['orden'] as num?)?.toInt() ?? 1;

              final progresoCurso = (progresoCursos[c.id] as Map?) ?? {};
              final finalScore = (progresoCurso['final_score'] as num?)?.toInt() ?? 0;
              final finalAprobado = progresoCurso['final_aprobado'] == true && finalScore >= 7;
              if (finalAprobado && orden > highestApprovedOrder) {
                highestApprovedOrder = orden;
              }
            }

            if (highestApprovedOrder > 0) {
              unlockedUntilOrder = highestApprovedOrder + 1;
            } else {
              unlockedUntilOrder = 1; // tras pretest, solo curso 1 disponible
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
                              colors: [Color.fromARGB(255, 250, 250, 250), Color.fromARGB(255, 255, 220, 202)],
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
                            border: Border.all(color: const Color(0xFFFFC9A8).withOpacity(0.18)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!testAprobado) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB88C).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.emoji_events, color: Color(0xFFBB4B1E)),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Test inicial',
                                          style: TextStyle(
                                            color: Color(0xFF4C2817),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Completa este reto y libera tus cursos.',
                                          style: TextStyle(
                                            color: Color(0xFF6E3A22),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFE9D7), Color(0xFFFFD1B3)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFEAA35C).withOpacity(0.4)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'assets/images/mascota/refuerzo2.png',
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE07A1E).withOpacity(0.14),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            child: const Text(
                                              'Desbloquea tus cursos',
                                              style: TextStyle(
                                                color: Color(0xFF7A3417),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Completa el test inicial para liberar tu ruta y comenzar a avanzar.',
                                              style: TextStyle(
                                                color: Color(0xFF4A2B16),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCC5A1A),
                                      minimumSize: const Size(double.infinity, 62),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 16,
                                      ),
                                      elevation: 12,
                                      shadowColor: const Color(0xFFCC5A1A).withOpacity(0.35),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/pretest');
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.assignment_turned_in, color: Colors.white, size: 22),
                                        SizedBox(width: 10),
                                        Text(
                                          'Realizar test',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 18,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                          'Aprueba el curso anterior para desbloquear este contenido.',
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
                                        iconPath: 'assets/gif/cursoG${(index % 9) + 1}.gif',
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

class _CourseCardState extends State<_CourseCard> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseController;
  Animation<double> _pulse = const AlwaysStoppedAnimation(0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
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
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, disponible ? _pulse.value : 0),
                                child: child,
                              );
                            },
                            child: Container(
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
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, disponible ? _pulse.value : 0),
                                child: child,
                              );
                            },
                            child: Container(
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
