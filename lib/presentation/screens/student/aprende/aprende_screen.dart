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
          return const Center(child: CircularProgressIndicator());
        }

        final user = userSnap.data!.data()!;
        final cursoActualId = (user['curso_actual'] ?? '').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('cursos').orderBy('orden').snapshots(),
          builder: (context, cursosSnap) {
            if (!cursosSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final cursos = cursosSnap.data!.docs;

            // Determinar hasta qué curso está desbloqueado
            int unlockedUntilOrder = 1;
            for (final c in cursos) {
              if (c.id == cursoActualId) {
                final orden = (c.data()['orden'] as num?)?.toInt() ?? 1;
                unlockedUntilOrder = orden + 1;
              }
            }

            return Container(
              color: const Color(0xFFFFF7E5),
              width: double.infinity,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 42),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Elige un curso para comenzar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F2416),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ⭐ GRID DE TARJETAS HEXAGONALES GRANDES
                      _CoursesGrid(
                        cursos: cursos,
                        cursoActualId: cursoActualId,
                        unlockedUntilOrder: unlockedUntilOrder,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////
//                         ⭐ GRID DE CURSOS                        //
//////////////////////////////////////////////////////////////////////

class _CoursesGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos;
  final String cursoActualId;
  final int unlockedUntilOrder;

  const _CoursesGrid({
    required this.cursos,
    required this.cursoActualId,
    required this.unlockedUntilOrder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double itemWidth = 150;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: cursos.map((doc) {
            final data = doc.data();
            final nombreCurso = (data['nombre'] ?? 'Curso').toString();
            final orden = (data['orden'] as num?)?.toInt() ?? 1;

            final unlocked = orden <= unlockedUntilOrder;
            final highlight = unlocked && doc.id == cursoActualId;

            return SizedBox(
              width: itemWidth,
              child: _HexCourseTile(
                title: nombreCurso,
                unlocked: unlocked,
                highlight: highlight,
                onTap: () {
                  if (!unlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa el curso anterior para desbloquear este 🧠',
                        ),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abrir curso: $nombreCurso (pendiente)')),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////
//                     ⭐ TARJETA HEXAGONAL                         //
//////////////////////////////////////////////////////////////////////

class _HexCourseTile extends StatefulWidget {
  final String title;
  final bool unlocked;
  final bool highlight;
  final VoidCallback onTap;

  const _HexCourseTile({
    required this.title,
    required this.unlocked,
    required this.highlight,
    required this.onTap,
  });

  @override
  State<_HexCourseTile> createState() => _HexCourseTileState();
}

class _HexCourseTileState extends State<_HexCourseTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconForTitle(String t) {
    t = t.toLowerCase();
    if (t.contains("variable")) return Icons.tune;
    if (t.contains("condicion")) return Icons.code;
    if (t.contains("bucle") || t.contains("loop")) return Icons.loop;
    if (t.contains("funcion")) return Icons.extension;
    if (t.contains("arreglo") || t.contains("vector")) return Icons.view_module;
    if (t.contains("tabla")) return Icons.grid_on;
    return Icons.psychology_alt;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForTitle(widget.title);

    final Color bgColor = widget.unlocked
        ? (widget.highlight
            ? const Color(0xFFFFC642)
            : const Color(0xFFFFD86B))
        : const Color(0xFFE6E0EC);

    final Color borderColor =
        widget.unlocked ? const Color(0xFFFFA200) : Colors.grey.shade400;

    final Color textColor =
        widget.unlocked ? const Color(0xFF3A2C1A) : Colors.grey.shade600;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.unlocked) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (!widget.unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Completa el curso anterior para desbloquear este 🧠"),
            ),
          );
          return;
        }
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1 - _controller.value,
          child: child,
        ),
        child: ClipPath(
          clipper: _HexagonClipper(),
          child: Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: widget.unlocked
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.unlocked ? icon : Icons.lock,
                  size: 34,
                  color:
                      widget.unlocked ? const Color(0xFF5A3A00) : Colors.grey.shade600,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        widget.highlight ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
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

//////////////////////////////////////////////////////////////////////
//                      🔷 HEXAGON CLIPPER                        //
//////////////////////////////////////////////////////////////////////

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.75, h)
      ..lineTo(w * 0.25, h)
      ..lineTo(0, h * 0.5)
      ..close();
  }

  @override
  bool shouldReclip(customClipper) => false;
}
