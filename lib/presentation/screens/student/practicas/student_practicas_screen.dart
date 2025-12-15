import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentPracticasScreen extends StatelessWidget {
  const StudentPracticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const accent = Color(0xFFFFA451);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: null,
      body: uid == null
          ? const Center(child: Text('Inicia sesion para ver tu refuerzo'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }
                final data = snap.data!.data() ?? {};
                final errores = (data['errores'] as List?)?.cast<Map?>() ?? [];

                final placeholders = [
                  {
                    'pregunta': '¿Cuál es la salida de este código al recorrer un arreglo?',
                    'curso': 'Estructuras de datos',
                    'leccion': 'Arreglos y listas',
                    'dificultad': 'Medio',
                  },
                  {
                    'pregunta': 'Completa el if/else para validar el ingreso de un usuario.',
                    'curso': 'Condicionales',
                    'leccion': 'Validaciones básicas',
                    'dificultad': 'Fácil',
                  },
                  {
                    'pregunta': 'Ordena los pasos para crear un bucle while controlado por contador.',
                    'curso': 'Bucles',
                    'leccion': 'While y control',
                    'dificultad': 'Medio',
                  },
                ];

                final items = errores.isNotEmpty ? errores : placeholders;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _HeroPractica(
                        accent: accent,
                        total: items.length,
                      );
                    }
                    final e = (items[i - 1] ?? {}) as Map;
                    final pregunta = (e['pregunta'] ?? 'Pregunta pendiente').toString();
                    final curso = (e['curso'] ?? '').toString();
                    final leccion = (e['leccion'] ?? '').toString();
                    final dificultad = (e['dificultad'] ?? '').toString();

                    return _RefuerzoCard(
                      titulo: curso.isNotEmpty ? curso : 'Curso',
                      descripcion: pregunta,
                      etiqueta: leccion.isNotEmpty ? leccion : 'Leccion',
                      dificultad: dificultad.isNotEmpty ? dificultad : 'Pendiente',
                      color: accent,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _HeroPractica extends StatelessWidget {
  final Color accent;
  final int total;

  const _HeroPractica({required this.accent, required this.total});

  @override
  Widget build(BuildContext context) {
    const images = [
      'assets/images/mascota/refuerzo1.png',
      'assets/images/mascota/refuerzo2.png',
      'assets/images/mascota/refuerzo3.png',
      
    ];
    final imgPath = images[(total % images.length).clamp(0, images.length - 1)];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2433), Color(0xFF2F3A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                imgPath,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prácticas dirigidas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Refuerza las preguntas falladas con nuevos ejercicios del curso.',
                  style: const TextStyle(
                    color: Color(0xFFE6EAF5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefuerzoCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String etiqueta;
  final String dificultad;
  final Color color;

  const _RefuerzoCard({
    required this.titulo,
    required this.descripcion,
    required this.etiqueta,
    required this.dificultad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(
                label: dificultad,
                color: color,
                icon: Icons.flag_rounded,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.refresh, color: Color(0xFF1E2433)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          if (etiqueta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Tag(
                label: 'Repasar pregunta',
                color: color,
                icon: Icons.lightbulb_rounded,
              ),
              const SizedBox(width: 8),
              _Tag(
                label: 'Práctica guiada',
                color: const Color(0xFF0EA5E9),
                icon: Icons.auto_awesome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Tag({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
