import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('cursos').orderBy('orden').snapshots(),
          builder: (context, cursosSnap) {
            if (!cursosSnap.hasData) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final cursos = cursosSnap.data!.docs;

            int unlockedUntilOrder = 1;
            for (final c in cursos) {
              if (c.id == cursoActualId) {
                final orden = (c.data()['orden'] as num?)?.toInt() ?? 1;
                unlockedUntilOrder = orden + 1;
              }
            }

            return Container(
              color: const Color(0xFFE9F3FF),
              width: double.infinity,
              child: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Elige un curso y avanza en tu laboratorio. Cada modulo desbloquea el siguiente.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A6275),
                              ),
                            ),
                            SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 42),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
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

                            final unlocked = orden <= unlockedUntilOrder;
                            final isCurrent = doc.id == cursoActualId;

                            return _CourseCard(
                              index: index,
                              title: nombreCurso,
                              description: descripcion.isEmpty
                                  ? 'Conceptos clave y ejercicios interactivos.'
                                  : descripcion,
                              unlocked: unlocked,
                              highlight: isCurrent,
                              onTap: () {
                                if (!unlocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Desbloquea este laboratorio completando el anterior.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Abrir curso: $nombreCurso (pendiente)'),
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
  final VoidCallback onTap;

  const _CourseCard({
    required this.index,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.highlight,
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
      [Color(0xFF0E6BA8), Color(0xFF1BB1E6)], // azul ciencia
      [Color(0xFF1D6FB2), Color(0xFF36A7E2)], // azul medio
      [Color(0xFF1C9A9E), Color(0xFF3EC8B7)], // teal laboratorio
      [Color(0xFFFF8A3D), Color(0xFFFF7043)], // acento naranja
      [Color(0xFF7C5DFA), Color(0xFF9E7BFF)], // violeta tecnico
    ];

    final colors = palettes[widget.index % palettes.length];
    Color colorA = colors[0];
    Color colorB = colors[1];

    if (!widget.unlocked) {
      colorA = Color.lerp(colorA, const Color(0xFF9DAEC6), 0.5)!;
      colorB = Color.lerp(colorB, const Color(0xFFB7C5D9), 0.5)!;
    }

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
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.unlocked ? Colors.white.withOpacity(0.18) : Colors.white54,
                  width: widget.highlight ? 2.2 : 1.4,
                ),
                boxShadow: widget.unlocked
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Positioned(
                      top: -12,
                      right: -6,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -14,
                      left: -6,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        widget.unlocked ? _iconForTitle(widget.title) : Icons.lock,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.science_outlined, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Paraciencia',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                widget.unlocked ? Icons.science_rounded : Icons.lock,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.unlocked ? 'Entrar' : 'Bloqueado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.unlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
