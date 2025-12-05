// lib/presentation/screens/student/student_home_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ajustes/student_settings_screen.dart';
import 'aprende/aprende_screen.dart';
import 'divisiones/divisiones_screen.dart';
import 'practicas/student_practicas_screen.dart';
import 'perfil/student_profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      screen: AprendeScreen(),
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Aprende',
      showProgress: true,
    ),
    _NavItem(
      screen: DivisionesScreen(),
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Divisiones',
    ),
    _NavItem(
      screen: StudentPracticasScreen(),
      icon: Icons.bubble_chart_outlined,
      activeIcon: Icons.bubble_chart,
      label: 'Practicas',
    ),
    _NavItem(
      screen: StudentProfileScreen(),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
    ),
    _NavItem(
      screen: StudentSettingsScreen(),
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Ajustes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FF),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE9F3FF), Color(0xFFF5F9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _StudentHud(
              showProgress: _items[_currentIndex].showProgress, // Solo muestra barra donde aplica
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _items[_currentIndex].screen,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0E6BA8),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showProgress;

  const _NavItem({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showProgress = false,
  });
}

// ===================================================================
// HUD SUPERIOR (Racha + Corazones + XP + "Hola, nombre")
// ===================================================================

class _StudentHud extends StatefulWidget {
  final bool showProgress;

  const _StudentHud({required this.showProgress});

  @override
  State<_StudentHud> createState() => _StudentHudState();
}

class _StudentHudState extends State<_StudentHud> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _tickCounter = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
        _tickCounter++;
      });
      if (_tickCounter % 5 == 0) {
        _recoverLivesIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _recoverLivesIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    int vidas = (data['vidas'] as num?)?.toInt() ?? 5;
    if (vidas >= 5) return;

    final ts = data['ultima_recuperacion_vida'];
    final now = DateTime.now();
    DateTime last = now;
    if (ts is Timestamp) {
      last = ts.toDate();
    } else {
      await docRef.update({'ultima_recuperacion_vida': Timestamp.fromDate(now)});
      return;
    }

    final elapsedSecs = now.difference(last).inSeconds;
    if (elapsedSecs < 120) return; // menos de 2 min

    final cycles = elapsedSecs ~/ 120;
    final newVidas = (vidas + cycles).clamp(0, 5);
    final newLast = newVidas == 5 ? now : last.add(Duration(minutes: cycles));

    await docRef.update({
      'vidas': newVidas,
      'ultima_recuperacion_vida': Timestamp.fromDate(newLast),
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final data = snap.data!.data() ?? {};
        final nombre = (data['nombre'] ?? 'Estudiante').toString();
        final xp = (data['xp_acumulada'] as num?)?.toDouble() ?? 0;
        final racha = (data['racha'] as num?)?.toInt() ?? 0;
        final vidas = (data['vidas'] as num?)?.toInt() ?? 5;
        final divisionId = (data['division_actual'] ?? '').toString();

        final lastRecuperacion =
            (data['ultima_recuperacion_vida'] is Timestamp) ? (data['ultima_recuperacion_vida'] as Timestamp).toDate() : DateTime.now();
        final nextRecuperacion = lastRecuperacion.add(const Duration(minutes: 2));
        Duration restante = Duration.zero;
        if (vidas < 5) {
          final diff = nextRecuperacion.difference(_now);
          restante = diff.isNegative ? Duration.zero : diff;
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          future: divisionId.isNotEmpty
              ? db.collection('divisiones').doc(divisionId).get()
              : Future.value(null),
          builder: (context, divSnap) {
            double xpMin = 0;
            double xpMax = 500;
            String divisionNombre = 'Explorador';

            if (divSnap.hasData && divSnap.data != null && divSnap.data!.data() != null) {
              final div = divSnap.data!.data()!;
              xpMin = (div['xp_min'] as num?)?.toDouble() ?? 0;
              xpMax = (div['xp_max'] as num?)?.toDouble() ?? (xpMin + 500);
              divisionNombre = (div['nombre'] ?? divisionNombre).toString();
              if (xpMax <= xpMin) xpMax = xpMin + 1;
            }

            final progress = ((xp - xpMin) / (xpMax - xpMin)).clamp(0.0, 1.0);

            return SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E6BA8), Color(0xFF1292D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $nombre',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FF7043),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  size: 18, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                '$racha dias',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: List.generate(5, (i) {
                              final isFilled = i < vidas;
                              return Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: 18,
                                  color: isFilled ? const Color(0xFFFF8A3D) : Colors.white30,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                divisionNombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (vidas < 5) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Vida en ${_formatDuration(restante)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (widget.showProgress)
                      _XpCard(
                        xpActual: xp,
                        xpMin: xpMin,
                        xpMax: xpMax,
                        progress: progress,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.rocket_launch, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Division: $divisionNombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
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

// Tarjeta de XP con estilo de laboratorio
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1BB1E6), Color(0xFF0E6BA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu progreso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acumula XP para subir de division.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFB2F2FF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${xpActual.toInt()} XP   -   Siguiente division: ${xpMax.toInt()} XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Te faltan ${(xpMax - xpActual).clamp(0, double.infinity).toInt()} XP para el siguiente salto.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
