import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';

import '../../../services/local_storage_service.dart';
import '../../modals/login_options_modal.dart';
import '../admin/admin_home_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _maxLives = 5;
  static const Duration _regenDuration = Duration(minutes: 10);

  int _selectedIndex = 0;
  int _lives = _maxLives;
  DateTime? _nextLifeAt;
  Timer? _regenTimer;

  @override
  void initState() {
    super.initState();
    _startRegenTimer();
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }

  void _useLife() {
    if (_lives <= 0) return;
    setState(() {
      _lives--;
      if (_lives < _maxLives && _nextLifeAt == null) {
        _nextLifeAt = DateTime.now().add(_regenDuration);
        _startRegenTimer();
      }
    });
  }

  void _startRegenTimer() {
    if (_lives >= _maxLives) {
      _nextLifeAt = null;
      _regenTimer?.cancel();
      _regenTimer = null;
      return;
    }
    if (_regenTimer != null) return;

    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_nextLifeAt != null && now.isAfter(_nextLifeAt!)) {
        setState(() {
          _lives = (_lives + 1).clamp(0, _maxLives);
          if (_lives >= _maxLives) {
            _lives = _maxLives;
            _nextLifeAt = null;
            timer.cancel();
            _regenTimer = null;
          } else {
            _nextLifeAt = DateTime.now().add(_regenDuration);
          }
        });
      } else {
        setState(() {}); // repinta para mostrar countdown
      }
    });
  }

  String _countdownText() {
    if (_nextLifeAt == null) return "Vidas completas";
    final remaining = _nextLifeAt!.difference(DateTime.now());
    if (remaining.isNegative) return "00:00";
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingCubit>();
    final nombre = onboarding.nombre;
    final edad = onboarding.edad;

    const accent = Color(0xFFFFA200);
    const surface = Color(0xFFFDF7E2);
    const dark = Color(0xFF1F1F1F);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          await LocalStorageService().setOnboardingCompleted(true);

          // Redirección según rol
          if (state.rol == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inicio de sesión exitoso")),
          );

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },

      child: Scaffold(
        backgroundColor: surface,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _LearningTab(
                nombre: nombre,
                accent: accent,
                dark: dark,
                lives: _lives,
                maxLives: _maxLives,
                countdownText: _countdownText(),
                onLoseLife: _useLife,
              ),
              const _PlaceholderTab(
                title: "Divisiones",
                description: "Explora módulos y subniveles próximos.",
                icon: Icons.emoji_events,
              ),
              _ProfileTab(
                nombre: nombre,
                edad: edad,
                accent: accent,
                dark: dark,
              ),
              const _PlaceholderTab(
                title: "Ajustes",
                description: "Configura notificaciones, idioma y más.",
                icon: Icons.settings,
              ),
            ],
          ),
        ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black12.withOpacity(0.1)),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: accent,
            unselectedItemColor: Colors.black38,
            iconSize: 28,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: "Aprende",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: "Divisiones",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Perfil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Ajustes",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningTab extends StatelessWidget {
  final String nombre;
  final Color accent;
  final Color dark;
  final int lives;
  final int maxLives;
  final String countdownText;
  final VoidCallback onLoseLife;

  const _LearningTab({
    required this.nombre,
    required this.accent,
    required this.dark,
    required this.lives,
    required this.maxLives,
    required this.countdownText,
    required this.onLoseLife,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopStatusCard(
            accent: accent,
            dark: dark,
            lives: lives,
            maxLives: maxLives,
            countdownText: countdownText,
          ),
          const SizedBox(height: 18),

          Text(
            "Hola, ${nombre.isEmpty ? "explorador" : nombre} 👋",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF303030),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Sigue aprendiendo lógica con tu compañero virtual.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE0A3), Color(0xFFFFC66E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/mascota.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tu progreso",
                        style: TextStyle(
                          color: dark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Registra tu avance y no pierdas tu racha diaria.",
                        style: TextStyle(
                          color: dark.withOpacity(0.75),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25)),
                                    ),
                                    builder: (_) => const LoginOptionsModal(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Guardar mi progreso",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: lives > 0 ? onLoseLife : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: dark.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Usar 1 vida",
                                style: TextStyle(
                                  color: dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _FeatureTile(
                icon: Icons.school,
                title: "Lecciones",
                subtitle: "Aprende con retos cortos",
              ),
              _FeatureTile(
                icon: Icons.extension,
                title: "Prácticas",
                subtitle: "Refuerza con ejercicios",
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _FeatureTile(
                icon: Icons.bolt,
                title: "Rachas",
                subtitle: "No pierdas tu serie diaria",
              ),
              _FeatureTile(
                icon: Icons.emoji_events,
                title: "Logros",
                subtitle: "Suma medallas y trofeos",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String nombre;
  final int edad;
  final Color accent;
  final Color dark;

  const _ProfileTab({
    required this.nombre,
    required this.edad,
    required this.accent,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = nombre.isEmpty ? "Explorador" : nombre;
    final displayAge = edad > 0 ? "$edad años" : "Edad no definida";

    return Container(
      color: const Color(0xFFFDF7E2),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE0A3), Color(0xFFFFC66E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mascota.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayAge,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: accent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Nivel 1",
                      style: TextStyle(
                        color: dark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: const [
              _StatCard(
                label: "Racha",
                value: "0 días",
                icon: Icons.local_fire_department,
              ),
              SizedBox(width: 12),
              _StatCard(
                label: "Puntos",
                value: "120",
                icon: Icons.bolt,
              ),
              SizedBox(width: 12),
              _StatCard(
                label: "Cursos",
                value: "3/10",
                icon: Icons.school,
              ),
            ],
          ),

          const SizedBox(height: 22),
          const Text(
            "Logros",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _AchievementChip(
                title: "Primer login",
                icon: Icons.emoji_emotions,
              ),
              _AchievementChip(
                title: "5 respuestas correctas",
                icon: Icons.check_circle,
              ),
              _AchievementChip(
                title: "Racha de 3 días",
                icon: Icons.local_fire_department,
              ),
              _AchievementChip(
                title: "Compartir progreso",
                icon: Icons.share,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _PlaceholderTab({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDF7E2),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFFFA200)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A4A4A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text(
              "Pronto verás aquí tu contenido personalizado.",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF303030),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TopStatusCard extends StatelessWidget {
  final Color accent;
  final Color dark;
  final int lives;
  final int maxLives;
  final String countdownText;

  const _TopStatusCard({
    required this.accent,
    required this.dark,
    required this.lives,
    required this.maxLives,
    required this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                "Racha: 0 días",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF303030),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(
                  maxLives,
                  (index) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      index < lives ? Icons.favorite : Icons.favorite_border,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dark.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFA200)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF303030),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFFA200), size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final String title;
  final IconData icon;

  const _AchievementChip({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFA200), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}
