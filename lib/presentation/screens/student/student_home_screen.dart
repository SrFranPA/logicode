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
    ),
    _NavItem(
      screen: DivisionesScreen(),
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Divisiones',
    ),
    _NavItem(
      screen: StudentPracticasScreen(),
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F6F6), Color(0xFFFAFAFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const _StudentHud(),
            const SizedBox(height: 8),
            Expanded(
              child: _items[_currentIndex].screen,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2A03A),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: const Color(0xFFF2A03A),
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              selectedIconTheme: const IconThemeData(size: 26, color: Colors.white),
              unselectedIconTheme: IconThemeData(
                size: 22,
                color: Colors.white.withOpacity(0.8),
              ),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
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
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ===================================================================
// HUD SUPERIOR (Racha + Corazones + XP + "Hola, nombre")
// ===================================================================

class _StudentHud extends StatefulWidget {
  const _StudentHud();

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
            String divisionNombre = 'Explorador';

            if (divSnap.hasData && divSnap.data != null && divSnap.data!.data() != null) {
              final div = divSnap.data!.data()!;
              divisionNombre = (div['nombre'] ?? divisionNombre).toString();
            }

            return SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4B24E), Color(0xFFF2A03A)],
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
                            Icons.handshake,
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
                            color: const Color(0xFFFFF2DC),
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
                                  color: isFilled ? const Color(0xFFB71C1C) : Colors.white30,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2A03A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDA8216)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.rocket_launch, size: 16, color: Color(0xFF4A2600)),
                              const SizedBox(width: 6),
                              Text(
                                divisionNombre,
                                style: const TextStyle(
                                  color: Color(0xFF4A2600),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.2,
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
                              color: const Color(0xFFFFF2DC),
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
