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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E2433),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Refuerzo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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

                if (errores.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sin refuerzo pendiente. Sigue practicando para mejorar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF283347), fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: errores.length,
                  itemBuilder: (context, i) {
                    final e = (errores[i] ?? {}) as Map;
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dificultad,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.refresh, color: Color(0xFF4A6275)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF12314D),
            ),
          ),
          if (etiqueta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: Color(0xFF4A6275),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(
              color: Color(0xFF4A6275),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.lightbulb, color: Color(0xFF4A6275), size: 18),
              SizedBox(width: 6),
              Text(
                'Repasar pregunta',
                style: TextStyle(
                  color: Color(0xFF12314D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
