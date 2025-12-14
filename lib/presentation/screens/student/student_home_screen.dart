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
        label: 'Refuerzo',
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
      backgroundColor: const Color(0xFFFCF8F2),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2533), Color(0xFF141927)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFFFFA451),
            unselectedItemColor: Colors.white70,
            selectedIconTheme: const IconThemeData(size: 26, color: Color(0xFFFFA451)),
            unselectedIconTheme: const IconThemeData(
              size: 22,
              color: Colors.white70,
            ),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            type: BottomNavigationBarType.fixed,
            onTap: (i) => setState(() => _currentIndex = i),
            items: _items
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA451).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.activeIcon, color: const Color(0xFFFFA451)),
                    ),
                    label: item.label,
                  ),
                )
                .toList(),
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
  bool _notifiedFullLives = false;

  @override
  void initState() {
    super.initState();
    _updateStreak();
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

  Future<void> _updateStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    int racha = (data['racha'] as num?)?.toInt() ?? 0;
    final lastTs = data['ultima_racha'];
    DateTime? last;
    if (lastTs is Timestamp) {
      last = lastTs.toDate();
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = (last != null) ? DateTime(last.year, last.month, last.day) : null;

    bool changed = false;
    if (lastDate == null) {
      racha = 1;
      changed = true;
    } else {
      final diffDays = todayDate.difference(lastDate).inDays;
      if (diffDays == 0) {
        // mismo dia, no cambia
      } else if (diffDays == 1) {
        racha += 1;
        changed = true;
      } else if (diffDays > 1) {
        racha = 1;
        changed = true;
      }
    }

    if (changed) {
      await docRef.update({
        'racha': racha,
        'ultima_racha': Timestamp.fromDate(today),
      });
    }
  }

  Future<void> _recoverLivesIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    int vidas = (data['vidas'] as num?)?.toInt() ?? 5;
    if (vidas >= 5) {
      if (!_notifiedFullLives && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vidas recargadas')),
        );
        _notifiedFullLives = true;
      }
      return;
    } else {
      _notifiedFullLives = false;
    }

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
    if (elapsedSecs < 60) return; // menos de 1 min

    final cycles = elapsedSecs ~/ 60;
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
                    colors: [Color(0xFF283347), Color(0xFF1E2433)],
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
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
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
                              colors: [Color(0xFFFFB35C), Color(0xFFFF8A3D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FF8A3D),
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
                            color: const Color(0xFFE9EEF7),
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
                                  color: isFilled ? const Color(0xFFFF8A3D) : Colors.white38,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DFF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC8B5F4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.rocket_launch, size: 16, color: Color(0xFF5C3BB0)),
                              const SizedBox(width: 6),
                              Text(
                                divisionNombre,
                                style: const TextStyle(
                                  color: Color(0xFF5C3BB0),
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
                              color: const Color(0xFFE9EEF7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Color(0xFF1E2433)),
                                const SizedBox(width: 6),
                                Text(
                                  'Vida en ${_formatDuration(restante)}',
                                  style: const TextStyle(
                                    color: Color(0xFF1E2433),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
