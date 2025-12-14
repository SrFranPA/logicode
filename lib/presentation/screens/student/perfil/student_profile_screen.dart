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
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesion para ver tu perfil')),
      );
    }
    final uid = authUser.uid;

    const accent = Color(0xFFFFA451);

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
                  subtitle: 'Sube con XP y refuerzo',
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
      ),
    );
  }
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
    case 'shield':
      return Icons.shield;
    case 'bolt':
      return Icons.bolt;
    default:
      return Icons.military_tech;
  }
}

class _AchievementsSection extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _AchievementsSection({required this.userData});

  @override
  Widget build(BuildContext context) {
    final logrosData = (userData['logros'] as List?)?.cast<Map?>() ?? [];
    final divisionActual = (userData['division_actual'] ?? '').toString().toLowerCase();
    final List<Map> base = [
      // Divisiones
      {
        'titulo': 'Recolector',
        'asset': 'assets/images/medallas/recolector.png',
        'color': '#FFA451',
        'categoria': 'divisiones',
        'desc': 'Completa retos iniciales de division.'
      },
      {
        'titulo': 'Arquitecto',
        'asset': 'assets/images/medallas/arquitecto.png',
        'color': '#FF8A3D',
        'categoria': 'divisiones',
        'desc': 'Diseña tu ruta y sube de nivel.'
      },
      {
        'titulo': 'Explorador',
        'asset': 'assets/images/medallas/explorador.png',
        'color': '#4CAF50',
        'categoria': 'divisiones',
        'desc': 'Descubre nuevas divisiones.'
      },
      // Cursos (curso1-curso9)
      {'titulo': 'Curso 1', 'asset': 'assets/images/medallas/curso1.png', 'color': '#FFB74D', 'categoria': 'cursos', 'desc': 'Completa el curso 1.'},
      {'titulo': 'Curso 2', 'asset': 'assets/images/medallas/curso2.png', 'color': '#FF9800', 'categoria': 'cursos', 'desc': 'Completa el curso 2.'},
      {'titulo': 'Curso 3', 'asset': 'assets/images/medallas/curso3.png', 'color': '#F57C00', 'categoria': 'cursos', 'desc': 'Completa el curso 3.'},
      {'titulo': 'Curso 4', 'asset': 'assets/images/medallas/curso4.png', 'color': '#FB8C00', 'categoria': 'cursos', 'desc': 'Completa el curso 4.'},
      {'titulo': 'Curso 5', 'asset': 'assets/images/medallas/curso5.png', 'color': '#FFB300', 'categoria': 'cursos', 'desc': 'Completa el curso 5.'},
      {'titulo': 'Curso 6', 'asset': 'assets/images/medallas/curso6.png', 'color': '#FFA726', 'categoria': 'cursos', 'desc': 'Completa el curso 6.'},
      {'titulo': 'Curso 7', 'asset': 'assets/images/medallas/curso7.png', 'color': '#FF7043', 'categoria': 'cursos', 'desc': 'Completa el curso 7.'},
      {'titulo': 'Curso 8', 'asset': 'assets/images/medallas/curso8.png', 'color': '#FF6F00', 'categoria': 'cursos', 'desc': 'Completa el curso 8.'},
      {'titulo': 'Curso 9', 'asset': 'assets/images/medallas/curso9.png', 'color': '#F9A825', 'categoria': 'cursos', 'desc': 'Completa el curso 9.'},
      // Coleccionista
      {
        'titulo': 'Rey',
        'asset': 'assets/images/medallas/rey.png',
        'color': '#FFC107',
        'categoria': 'coleccion',
        'desc': 'Colecciona todas las medallas clave.'
      },
    ];
    // siempre mostramos 8 espacios; si hay logros en DB, sobrescriben pero heredan asset/base si no traen.
    final logros = List<Map>.from(base);
    for (int i = 0; i < logrosData.length && i < 8; i++) {
      final m = (logrosData[i] ?? {}) as Map;
      // Hereda asset/icon/color si no vienen
      logros[i] = {
        ...base[i],
        ...m,
      };
    }

    bool _desbloqueaDivision(String baseNombre) {
      final pref = baseNombre.toLowerCase();
      return divisionActual.startsWith(pref);
    }

    final divisiones = logros
        .where((m) => (m['categoria'] ?? '') == 'divisiones')
        .take(3)
        .map((m) => {
              ...m,
              'locked': !_desbloqueaDivision((m['titulo'] ?? '').toString()),
            })
        .toList();

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
          const SizedBox(height: 6),
          const Text(
            'Desbloquea medallas al completar hitos, mantener rachas y sumar XP.',
            style: TextStyle(
              color: Color(0xFF555B64),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          _CategoryGrid(
            titulo: 'Divisiones',
            items: divisiones,
          ),
          const SizedBox(height: 12),
          _CategoryGrid(
            titulo: 'Cursos',
            items: logros.where((m) => (m['categoria'] ?? '') == 'cursos').take(9).toList(),
          ),
          const SizedBox(height: 12),
          _CategoryGrid(
            titulo: 'Coleccionista',
            items: logros.where((m) => (m['categoria'] ?? '') == 'coleccion').take(1).toList(),
          ),
        ],
      ),
    );
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

class _CategoryGrid extends StatelessWidget {
  final String titulo;
  final List<Map> items;

  const _CategoryGrid({required this.titulo, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2026),
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final logro = (items[index]) as Map;
            final titulo = (logro['titulo'] ?? 'Logro').toString();
            final icono = (logro['icono'] ?? 'star').toString();
            final asset = (logro['asset'] ?? '').toString();
            final colorHex = (logro['color'] ?? '#0E6BA8').toString();
            final color = _hexToColor(colorHex);
            final locked = logro['locked'] == true;

            return Stack(
              children: [
                Opacity(
                  opacity: locked ? 0.35 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.12), color.withOpacity(0.32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.88),
                          ),
                          child: Center(
                            child: asset.isNotEmpty
                                ? ClipOval(
                                    child: Image.asset(
                                      asset,
                                      width: 70,
                                      height: 70,
                                      cacheWidth: 140,
                                      cacheHeight: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(_iconFromString(icono), color: color, size: 28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2026),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (locked)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(Icons.lock, size: 18, color: Color(0xFF6B7280)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
