import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DivisionesScreen extends StatelessWidget {
  const DivisionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleDivisiones = [
      _DivisionCardData(
        nombre: 'Division Beta',
        rango: '0 - 499 XP',
        estado: 'En curso',
        color: const Color(0xFFF2A03A),
      ),
      _DivisionCardData(
        nombre: 'Division Gamma',
        rango: '500 - 999 XP',
        estado: 'Siguiente parada',
        color: const Color(0xFFEF8B2C),
      ),
      _DivisionCardData(
        nombre: 'Division Delta',
        rango: '1000+ XP',
        estado: 'Objetivo a largo plazo',
        color: const Color(0xFFE2701A),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 3,
        // AppBar sencillo solo con el nombre de la sección
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
          'Divisiones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _TopGlobalSection(),
          const SizedBox(height: 18),
          const Text(
            'Rutas de progresion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2026),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cada division desbloquea nuevos retos cientificos. Completa XP para avanzar.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF555B64),
            ),
          ),
          const SizedBox(height: 16),
          ...sampleDivisiones.map((d) => _DivisionCard(data: d)).toList(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2A03A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.psychology_alt, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completa lecciones y practicas para sumar XP. Las divisiones se actualizan automaticamente.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
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

class _TopGlobalSection extends StatelessWidget {
  const _TopGlobalSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDF2DE), Color(0xFFFFFAF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2A03A).withOpacity(0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFFE27C1A)),
              SizedBox(width: 8),
              Text(
                'Top 5 por XP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2026),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .orderBy('xp_acumulada', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aun no hay usuarios registrados.',
                    style: TextStyle(color: Color(0xFF555B64)),
                  ),
                );
              }

              return Column(
                children: List.generate(docs.length, (i) {
                  final data = docs[i].data();
                  final nombre = (data['nombre'] ?? 'Estudiante').toString();
                  final xp = (data['xp_acumulada'] as num?)?.toInt() ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2A03A).withOpacity(0.18),
                          ),
                          child: Center(
                            child: Text(
                              '#${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE27C1A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E2026),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Division actual',
                                style: TextStyle(color: Color(0xFF555B64), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2A03A).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$xp XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE27C1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DivisionCardData {
  final String nombre;
  final String rango;
  final String estado;
  final Color color;

  _DivisionCardData({
    required this.nombre,
    required this.rango,
    required this.estado,
    required this.color,
  });
}

class _DivisionCard extends StatelessWidget {
  final _DivisionCardData data;

  const _DivisionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9A34F).withOpacity(0.25), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withOpacity(0.18),
              border: Border.all(color: data.color.withOpacity(0.38)),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.rango,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              data.estado,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
