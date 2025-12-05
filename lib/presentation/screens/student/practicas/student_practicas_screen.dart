import 'package:flutter/material.dart';

class StudentPracticasScreen extends StatelessWidget {
  const StudentPracticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _PracticaData(
        titulo: 'Laboratorio 1',
        descripcion: 'Variables y tipos con desafios guiados.',
        dificultad: 'Basico',
        color: const Color(0xFFF2A03A),
      ),
      _PracticaData(
        titulo: 'Laboratorio 2',
        descripcion: 'Condicionales y flujo de decisiones.',
        dificultad: 'Intermedio',
        color: const Color(0xFFEF8B2C),
      ),
      _PracticaData(
        titulo: 'Laboratorio 3',
        descripcion: 'Bucles y patrones recurrentes.',
        dificultad: 'Intermedio',
        color: const Color(0xFFE2701A),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 3,
        toolbarHeight: 44,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8D7A8), Color(0xFFF2B260)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Practicas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        itemBuilder: (context, i) => _PracticaCard(data: items[i]),
      ),
    );
  }
}

class _PracticaData {
  final String titulo;
  final String descripcion;
  final String dificultad;
  final Color color;

  _PracticaData({
    required this.titulo,
    required this.descripcion,
    required this.dificultad,
    required this.color,
  });
}

class _PracticaCard extends StatelessWidget {
  final _PracticaData data;

  const _PracticaCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(0.25)),
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
                  color: data.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data.dificultad,
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.play_circle_fill, color: Color(0xFF4A6275)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF12314D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.descripcion,
            style: const TextStyle(
              color: Color(0xFF4A6275),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.science_rounded, color: data.color, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Entrar al laboratorio',
                style: TextStyle(
                  color: Color(0xFF12314D),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF4A6275)),
            ],
          ),
        ],
      ),
    );
  }
}
