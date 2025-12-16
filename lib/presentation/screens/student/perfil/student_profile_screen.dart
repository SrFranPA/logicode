import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Future<QuerySnapshot<Map<String, dynamic>>>? _cursosFuture;

  @override
  void initState() {
    super.initState();
    _cursosFuture = FirebaseFirestore.instance.collection('cursos').orderBy('orden').get();
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
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF95A3B8), Color(0xFF6B7A94)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B7A94).withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F2937),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF6B7280)),
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
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        title: 'Racha activa',
                        value: '$racha d',
                        subtitle: '',
                        icon: Icons.local_fire_department,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        title: 'Total de XP',
                        value: '$xp',
                        subtitle: '',
                        icon: Icons.grade_rounded,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
                _StatTile(
                  title: 'Division actual',
                  value: divisionActual,
                  subtitle: 'Sube con XP y refuerzo',
                  icon: Icons.rocket_launch,
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
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _cursosFuture ??= FirebaseFirestore.instance.collection('cursos').orderBy('orden').get(),
                  builder: (context, cursosSnap) {
                    final cursos = cursosSnap.data?.docs ?? [];
                    return _AchievementsSection(
                      userData: data,
                      cursos: cursos,
                    );
                  },
                ),
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
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos;

  const _AchievementsSection({
    required this.userData,
    required this.cursos,
  });

  @override
  Widget build(BuildContext context) {
    final logrosData = (userData['logros'] as List?)?.cast<Map?>() ?? [];
    final progresoCursos = (userData['progreso'] as Map?) ?? {};
    final divisionActual = (userData['division_actual'] ?? '').toString().toLowerCase();

    const baseDivisiones = [
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
        'desc': 'Disena tu ruta y sube de nivel.'
      },
      {
        'titulo': 'Explorador',
        'asset': 'assets/images/medallas/explorador.png',
        'color': '#4CAF50',
        'categoria': 'divisiones',
        'desc': 'Descubre nuevas divisiones.'
      },
    ];

    const cursoColors = [
      '#FFB74D',
      '#FF9800',
      '#F57C00',
      '#FB8C00',
      '#FFB300',
      '#FFA726',
      '#FF7043',
      '#FF6F00',
      '#F9A825',
    ];

    Map<String, dynamic> _mergeOverrides(Map base) {
      final override = logrosData.firstWhere(
        (m) => (m?['titulo'] ?? '') == base['titulo'],
        orElse: () => null,
      );
      if (override is Map) {
        return {...base, ...override};
      }
      return Map<String, dynamic>.from(base);
    }

    bool _desbloqueaDivision(String baseNombre) {
      final pref = baseNombre.toLowerCase();
      return divisionActual.startsWith(pref);
    }

    final divisiones = baseDivisiones
        .map((m) {
          final data = _mergeOverrides(m);
          return {
            ...data,
            'locked': !_desbloqueaDivision((data['titulo'] ?? '').toString()),
          };
        })
        .toList();

    final cursoItems = <Map>[];
    for (var i = 0; i < cursos.length && i < 9; i++) {
      final doc = cursos[i];
      final data = doc.data();
      final progresoCurso = (progresoCursos[doc.id] as Map?) ?? {};
      final finalScore = (progresoCurso['final_score'] as num?)?.toInt() ?? 0;
      final aprobado = progresoCurso['final_aprobado'] == true && finalScore >= 7;
      final numeroCurso = i + 1;
      cursoItems.add({
        'titulo': 'Curso $numeroCurso',
        'asset': 'assets/images/medallas/curso$numeroCurso.png',
        'color': cursoColors[i % cursoColors.length],
        'categoria': 'cursos',
        'desc': 'Completa el curso $numeroCurso.',
        'cursoNombre': (data['nombre'] ?? '').toString(),
        'locked': !aprobado,
      });
    }

    final coleccion = [
      {
        'titulo': 'Rey',
        'asset': 'assets/images/medallas/rey.png',
        'color': '#FFC107',
        'categoria': 'coleccion',
        'desc': 'Colecciona todas las medallas clave.',
        'locked': cursoItems.any((m) => m['locked'] == true),
      },
    ];

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
            items: cursoItems,
          ),
          const SizedBox(height: 12),
          _CategoryGrid(
            titulo: 'Coleccionista',
            items: coleccion,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
              color: accent.withOpacity(0.12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
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
            letterSpacing: 0.2,
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
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            const palettes = [
              [Color(0xFFF3A45C), Color(0xFFFECF9C)],
              [Color(0xFF6CC5B8), Color(0xFFB5F2E2)],
              [Color(0xFF7D8BFF), Color(0xFFB6C3FF)],
              [Color(0xFFE57373), Color(0xFFF6B1B1)],
              [Color(0xFFF4C95D), Color(0xFFFFE4A1)],
            ];
            final paleta = palettes[index % palettes.length];
            final logro = (items[index]) as Map;
            final titulo = (logro['titulo'] ?? 'Logro').toString();
            final desc = (logro['desc'] ?? '').toString();
            final icono = (logro['icono'] ?? 'star').toString();
            final asset = (logro['asset'] ?? '').toString();
            final colorHex = (logro['color'] ?? '#0E6BA8').toString();
            final color = _hexToColor(colorHex);
            final locked = logro['locked'] == true;
            final cursoNombre = (logro['cursoNombre'] ?? '').toString();

            void _showMedalDetail() {
              final frase = locked
                  ? 'Practica y vuelve: esta medalla te espera.'
                  : 'Sigue avanzando, cada logro te acerca a tu meta.';
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                barrierColor: Colors.black54,
                backgroundColor: Colors.transparent,
                builder: (ctx) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.45,
                    maxChildSize: 0.78,
                    expand: false,
                    builder: (_, controller) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              paleta.first.withOpacity(0.35),
                              paleta.last.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          boxShadow: [
                            BoxShadow(
                              color: paleta.first.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: paleta.first.withOpacity(0.25)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        paleta.first.withOpacity(0.6),
                                        paleta.last.withOpacity(0.75),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(color: paleta.first.withOpacity(0.75), width: 1.6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: paleta.first.withOpacity(0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: locked
                                        ? Icon(Icons.lock_outline_rounded, color: paleta.first, size: 54)
                                        : ClipOval(
                                            child: Image.asset(
                                              asset,
                                              width: 112,
                                              height: 112,
                                              cacheWidth: 224,
                                              cacheHeight: 224,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  titulo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18.5,
                                    color: Color(0xFF0F1A2A),
                                  ),
                                ),
                                if (cursoNombre.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    cursoNombre,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                if (desc.isNotEmpty)
                                  Text(
                                    locked ? 'Aún no la ganas. $desc' : desc,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.2,
                                      height: 1.4,
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: paleta.first.withOpacity(0.18)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: paleta.first.withOpacity(0.18),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          locked ? Icons.hourglass_bottom_rounded : Icons.celebration_rounded,
                                          color: paleta.first,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: paleta.last.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                locked ? 'Pendiente' : '¡Conseguida!',
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              frase,
                                              style: const TextStyle(
                                                color: Color(0xFF2C2F38),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
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
                    },
                  );
                },
              );
            }

            return Stack(
              children: [
                GestureDetector(
                  onTap: _showMedalDetail,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: locked
                            ? [paleta.first.withOpacity(0.25), paleta.last.withOpacity(0.25)]
                            : paleta,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: locked ? Colors.black12 : paleta.first.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: locked ? Colors.black.withOpacity(0.05) : paleta.first.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            border: Border.all(
                              color: locked ? Colors.black12 : color.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: !locked && asset.isNotEmpty
                                ? ClipOval(
                                    child: Image.asset(
                                      asset,
                                      width: 76,
                                      height: 76,
                                      cacheWidth: 152,
                                      cacheHeight: 152,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                  locked ? Icons.lock_outline_rounded : _iconFromString(icono),
                                  color: color,
                                  size: 32,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: locked ? const Color(0xFF3E434F) : const Color(0xFF111827),
                            fontSize: 11.2,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
