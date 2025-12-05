// lib/presentation/screens/student/student_home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'aprende/aprende_screen.dart';
import 'divisiones/divisiones_screen.dart';
import 'perfil/student_profile_screen.dart';
import 'ajustes/student_settings_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    AprendeScreen(),
    DivisionesScreen(),
    StudentProfileScreen(),
    StudentSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E5),
      body: Column(
        children: [
          const _StudentHud(), // 🔥 HUD fijo arriba en TODA la app
          const SizedBox(height: 8),
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFFFCEEFE),
        selectedItemColor: const Color(0xFFFFA200),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Aprende',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Divisiones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// HUD SUPERIOR (Racha + Corazones + XP + "Hola, nombre")
// ===================================================================

class _StudentHud extends StatelessWidget {
  const _StudentHud();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() ?? {};
        final nombre = (data['nombre'] ?? 'Estudiante').toString();
        final xp = (data['xp_acumulada'] as num?)?.toDouble() ?? 0;
        final racha = (data['racha'] as num?)?.toInt() ?? 0;
        final vidas = (data['vidas'] as num?)?.toInt() ?? 5;
        final divisionId = (data['division_actual'] ?? '').toString();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: divisionId.isNotEmpty
              ? db.collection('divisiones').doc(divisionId).get()
              : null,
          builder: (context, divSnap) {
            double xpMin = 0;
            double xpMax = 500;

            if (divSnap.hasData && divSnap.data != null && divSnap.data!.data() != null) {
              final div = divSnap.data!.data()!;
              xpMin = (div['xp_min'] as num?)?.toDouble() ?? 0;
              xpMax = (div['xp_max'] as num?)?.toDouble() ?? (xpMin + 500);
              if (xpMax <= xpMin) xpMax = xpMin + 1;
            }

            final progress = ((xp - xpMin) / (xpMax - xpMin)).clamp(0.0, 1.0);

            return SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF2D9),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------ Fila racha + corazones ------------------
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFB98C5A),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$racha días',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6F604A),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (i) {
                            final isFilled = i < vidas;
                            return Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                Icons.favorite,
                                size: 18,
                                color: isFilled
                                    ? const Color(0xFFE54C3C)
                                    : const Color(0xFFE3D4C5),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Hola, $nombre 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2416),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sigue aprendiendo lógica de programación\ncon tu compañero virtual.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7E6D57),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _XpCard(
                      xpActual: xp,
                      xpMin: xpMin,
                      xpMax: xpMax,
                      progress: progress,
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

// Tarjeta de XP (mismo estilo que te gustó)
class _XpCard extends StatelessWidget {
  final double xpActual;
  final double xpMin;
  final double xpMax;
  final double progress;

  const _XpCard({
    required this.xpActual,
    required this.xpMin,
    required this.xpMax,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC766), Color(0xFFFFA200)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu progreso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acumula XP para subir de división.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.30),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFF4D5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${xpActual.toInt()} XP  •  Próxima división: ${xpMax.toInt()} XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
