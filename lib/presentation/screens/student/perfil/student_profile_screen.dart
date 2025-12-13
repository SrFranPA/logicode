import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    _updateStreak();
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

  Future<void> _showEditSheet(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 6,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2433), Color(0xFF283347)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                    color: const Color(0xFFFFA451),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edita tu nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usaremos este nombre para tu perfil y certificados.',
                  style: TextStyle(
                    color: Color(0xFFE6EAF5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      hintText: 'Ingresa tu nombre',
                      filled: true,
                      fillColor: const Color(0xFFF3F5FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA451),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa un nombre valido.')),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user.uid)
                            .update({'nombre': newName});
                        await user.updateDisplayName(newName);
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Datos actualizados.')),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo actualizar.')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Guardar cambios',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final authUser = FirebaseAuth.instance.currentUser;

    const accent = Color(0xFFFFA451);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF283347),
        elevation: 0,
        toolbarHeight: 46,
        centerTitle: true,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

          final data = snap.data!.data() ?? {};
          final nombre = (data['nombre'] ?? authUser?.displayName ?? 'Estudiante').toString();
          final racha = (data['racha'] as num?)?.toInt() ?? 0;
          final divisionActual = (data['division_actual'] ?? '-').toString();
          final xp = (data['xp_acumulada'] as num?)?.toInt() ?? 0;
          final email = authUser?.email ?? (data['email'] ?? 'Sin correo');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE9EEF7), Color(0xFFD7DFEF)],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF283347), size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2026),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555B64),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF555B64)),
                      onPressed: () => _showEditSheet(context, nombre),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Progreso',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2026),
                ),
              ),
              const SizedBox(height: 10),
              _StatTile(
                title: 'Racha activa',
                value: '$racha d',
                subtitle: 'Dias seguidos aprendiendo',
                icon: Icons.bolt,
                accent: accent,
              ),
              _StatTile(
                title: 'Division actual',
                value: divisionActual,
                subtitle: 'Sube con XP y practicas',
                icon: Icons.rocket_launch,
                accent: accent,
              ),
              _StatTile(
                title: 'Total de XP',
                value: '$xp',
                subtitle: 'Sumado en cursos y retos',
                icon: Icons.stacked_bar_chart,
                accent: accent,
              ),
              const SizedBox(height: 14),
              const Text(
                'Logros',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2026),
                ),
              ),
              const SizedBox(height: 8),
              _AchievementsSection(userData: data),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.tips_and_updates, color: Color(0xFF283347)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pronto podras editar tu avatar, vincular redes y descargar tu certificado.',
                        style: TextStyle(color: Color(0xFF1E2026), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),    );
    }
}

class _AchievementsSection extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _AchievementsSection({required this.userData});

  @override
  Widget build(BuildContext context) {
    final logros = (userData['logros'] as List?)?.cast<Map?>() ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFF283347)),
              SizedBox(width: 8),
              Text(
                'Logros y medallas',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2026),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (logros.isEmpty)
            const Text(
              'Aun no tienes logros. Completa cursos y retos para obtener medallas.',
              style: TextStyle(color: Color(0xFF555B64), fontSize: 12),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: logros.map((raw) {
                final logro = (raw ?? {}) as Map;
                final titulo = (logro['titulo'] ?? 'Logro').toString();
                final icono = (logro['icono'] ?? 'star').toString();
                final colorHex = (logro['color'] ?? '#0E6BA8').toString();
                final color = _hexToColor(colorHex);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconFromString(icono), color: color),
                      const SizedBox(width: 6),
                      Text(
                        titulo,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final intColor = int.tryParse(h, radix: 16) ?? 0xFF0E6BA8;
    return Color(intColor);
  }

  IconData _iconFromString(String name) {
    switch (name) {
      case 'star':
        return Icons.star;
      case 'medal':
        return Icons.emoji_events;
      case 'flame':
        return Icons.local_fire_department;
      case 'rocket':
        return Icons.rocket_launch;
      default:
        return Icons.military_tech;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accent = const Color(0xFFFFA451),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2026),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF555B64), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2026),
            ),
          ),
        ],
      ),
    );
  }
}
