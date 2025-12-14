import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DivisionesScreen extends StatefulWidget {
  const DivisionesScreen({super.key});

  @override
  State<DivisionesScreen> createState() => _DivisionesScreenState();
}

class _DivisionesScreenState extends State<DivisionesScreen> {
  String? _divisionActual;
  bool _loadingDivision = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadDivision();
  }

  Future<void> _loadDivision() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingDivision = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      final data = doc.data() ?? {};
      final div = data['division_actual']?.toString();
      if (mounted) {
        setState(() {
          _divisionActual = div;
          _loadingDivision = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDivision = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFA451); // tomate aprende
    const accentAlt = Color(0xFFFF8A3D);
    const dark = Color(0xFF1E2433); // tono oscuro usado en aprende

    final sampleDivisiones = [
      _DivisionCardData(
        nombre: 'Division Beta',
        rango: '0 - 499 XP',
        estado: 'En curso',
        color: accent,
        xpMin: 0,
        asset: 'assets/images/recolector.png',
      ),
      _DivisionCardData(
        nombre: 'Division Gamma',
        rango: '500 - 999 XP',
        estado: 'Siguiente parada',
        color: accentAlt,
        xpMin: 500,
        asset: 'assets/images/arquitecto.png',
      ),
      _DivisionCardData(
        nombre: 'Division Delta',
        rango: '1000+ XP',
        estado: 'Objetivo a largo plazo',
        color: const Color(0xFFE56E1D),
        xpMin: 1000,
        asset: 'assets/images/explorador.png',
      ),
    ];

    // Marcar actual y siguiente en la ruta
    int currentIndex = sampleDivisiones.indexWhere(
      (d) => d.nombre.toLowerCase() == (_divisionActual ?? '').toLowerCase(),
    );
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2433), Color(0xFF283347)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Divisiones',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progreso y ranking de tu ruta',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_divisionActual != null && _divisionActual!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _divisionActual!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _TopGlobalSection(
                accent: accent,
                dark: dark,
                divisionActual: _divisionActual,
                loadingDivision: _loadingDivision,
                uid: _uid,
              ),
              const SizedBox(height: 18),
              const Text(
                'Rutas de progresion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2026),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cada division desbloquea nuevos retos. Completa XP para avanzar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555B64),
                ),
              ),
              const SizedBox(height: 16),
              ...sampleDivisiones.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final isCurrent = i == currentIndex;
                final isNext = i == currentIndex + 1 && i < sampleDivisiones.length;
                return _DivisionCard(data: d, dark: dark, isCurrent: isCurrent, isNext: isNext);
              }).toList(),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
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
        ),
      ),
    );
  }
}

class _TopGlobalSection extends StatelessWidget {
  final Color accent;
  final Color dark;
  final String? divisionActual;
  final bool loadingDivision;
  final String? uid;

  const _TopGlobalSection({
    required this.accent,
    required this.dark,
    required this.divisionActual,
    required this.loadingDivision,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    // Consultamos ordenado por XP y filtramos en cliente la division.
    final stream = FirebaseFirestore.instance
        .collection('usuarios')
        .orderBy('xp_acumulada', descending: true)
        .limit(50)
        .snapshots();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFBF7), // fondo mas claro para el bloque
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              Icon(Icons.emoji_events, color: accent),
              const SizedBox(width: 8),
              Text(
                divisionActual != null && divisionActual!.isNotEmpty
                    ? 'Top 5 - ${divisionActual!}'
                    : 'Top 5 por XP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2026),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loadingDivision)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                final docs = snap.data!.docs;
                List<QueryDocumentSnapshot<Map<String, dynamic>>> filtrados = docs;
                if (divisionActual != null && divisionActual!.isNotEmpty) {
                  filtrados = docs
                      .where((d) => (d.data()['division_actual'] ?? '') == divisionActual)
                      .take(5)
                      .toList();
                } else {
                  filtrados = docs.take(5).toList();
                }

                if (filtrados.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      divisionActual != null && divisionActual!.isNotEmpty
                          ? 'Aun no hay usuarios en esta division.'
                          : 'Aun no hay usuarios registrados.',
                      style: const TextStyle(color: Color(0xFF555B64)),
                    ),
                  );
                }

                int userPosition = -1;
                for (int i = 0; i < filtrados.length; i++) {
                  if (filtrados[i].id == uid) {
                    userPosition = i + 1;
                    break;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userPosition > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tu posicion: #$userPosition',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ...List.generate(filtrados.length, (i) {
                      final data = filtrados[i].data();
                      final nombre = (data['nombre'] ?? 'Estudiante').toString();
                      final xp = (data['xp_acumulada'] as num?)?.toInt() ?? 0;
                      final division = (data['division_actual'] ?? '').toString();
                      final isUser = filtrados[i].id == uid;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? accent.withOpacity(0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUser ? accent.withOpacity(0.6) : Colors.transparent,
                            width: 1,
                          ),
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
                                color: accent.withOpacity(0.18),
                              ),
                              child: Center(
                                child: Text(
                                  '#${i + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: accent,
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
                                  Text(
                                    division.isNotEmpty ? division : 'Division actual',
                                    style:
                                        const TextStyle(color: Color(0xFF555B64), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$xp XP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
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
  final int? xpMin;
  final String? asset;

  _DivisionCardData({
    required this.nombre,
    required this.rango,
    required this.estado,
    required this.color,
    this.xpMin,
    this.asset,
  });
}

class _DivisionCard extends StatelessWidget {
  final _DivisionCardData data;
  final Color dark;
  final bool isCurrent;
  final bool isNext;

  const _DivisionCard({
    required this.data,
    required this.dark,
    this.isCurrent = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? data.color.withOpacity(0.7)
              : isNext
                  ? data.color.withOpacity(0.4)
                  : data.color.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? data.color.withOpacity(0.28)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withOpacity(0.18),
              border: Border.all(color: data.color.withOpacity(0.4)),
            ),
            child: Icon(Icons.rocket_launch, color: dark),
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
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2026),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.rango,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF555B64)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  data.estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isNext && data.xpMin != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Meta: ${data.xpMin} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF555B64),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
