import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'minitest.dart';

class StudentPracticasScreen extends StatefulWidget {
  const StudentPracticasScreen({super.key});

  @override
  State<StudentPracticasScreen> createState() => _StudentPracticasScreenState();
}

class _StudentPracticasScreenState extends State<StudentPracticasScreen> {
  bool _miniCompletada = false;
  bool _miniDesbloqueada = false;
  int _intentosRestantes = 3;
  bool _desafioCompletado = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const accent = Color(0xFFFFA451);

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tu refuerzo')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: null,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final data = snap.data!.data() ?? {};
          final errores = (data['errores'] as List?)?.cast<Map?>() ?? [];
          final vidas = (data['vidas'] as num?)?.toInt() ?? 5;
          final sinVidas = vidas <= 0;

          final placeholders = [
            {'pregunta': '¿Cuál es la salida al recorrer un arreglo?', 'curso': 'Estructuras'},
            {'pregunta': 'Completa el if/else de validación.', 'curso': 'Condicionales'},
            {'pregunta': 'Ordena los pasos de un while con contador.', 'curso': 'Bucles'},
          ];

          final ultimoError = errores.isNotEmpty ? errores.last : null;
          final cursoFallback = (data['curso_actual'] ?? '').toString();
          final rawCurso = ultimoError?['cursoId'] ?? ultimoError?['curso'];
          final ultimoCursoId = (rawCurso != null && rawCurso.toString().isNotEmpty) ? rawCurso.toString() : cursoFallback;
          final rawCursoNombre = ultimoError?['curso'];
          final ultimoCursoNombre = (rawCursoNombre != null && rawCursoNombre.toString().isNotEmpty)
              ? rawCursoNombre.toString()
              : (cursoFallback.isNotEmpty ? 'Curso actual' : '');

          if (sinVidas && !_miniDesbloqueada) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _miniDesbloqueada = true);
            });
          }

          final puedeGenerarMini = _miniDesbloqueada && !_miniCompletada && _intentosRestantes > 0 && ultimoCursoId.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeroCard(
                accent: accent,
                titulo: 'Prácticas dirigidas',
                subtitulo:
                    'Refuerza lo que fallaste con una mini lección de 5 preguntas. Si terminas correctamente el curso recibirás recompensas <3',
                intentosRestantes: _intentosRestantes,
                enabled: puedeGenerarMini,
                miniCompletada: _miniCompletada,
                showAttempts: true,
                onTap: (!puedeGenerarMini || _miniCompletada)
                    ? null
                    : () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => MiniTestScreen(
                              cursoId: ultimoCursoId,
                              cursoNombre: ultimoCursoNombre,
                              leccionNombre: (ultimoError?['leccion'] ?? '').toString(),
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (result == true) {
                          setState(() => _miniCompletada = true);
                        } else {
                          setState(() => _intentosRestantes = (_intentosRestantes - 1).clamp(0, 3));
                        }
                      },
              ),
              const SizedBox(height: 14),
              _HeroCard(
                accent: accent,
                titulo: 'Desafíos',
                subtitulo:
                    'Supera retos extra del curso con 5 preguntas difíciles. Si terminas correctamente el curso recibirás recompensas <3',
                intentosRestantes: 0,
                enabled: ultimoCursoId.isNotEmpty && !_desafioCompletado,
                miniCompletada: _desafioCompletado,
                showAttempts: false,
                onTap: ultimoCursoId.isEmpty
                    ? null
                    : () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => MiniTestScreen(
                              cursoId: ultimoCursoId,
                              cursoNombre: ultimoCursoNombre,
                              leccionNombre: (ultimoError?['leccion'] ?? '').toString(),
                              dificultades: const ['Dificil', 'Muy dificil'],
                            ),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {
                          _desafioCompletado = true;
                        });
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color accent;
  final String titulo;
  final String subtitulo;
  final bool enabled;
  final bool miniCompletada;
  final int intentosRestantes;
  final bool showAttempts;
  final VoidCallback? onTap;

  const _HeroCard({
    required this.accent,
    required this.titulo,
    required this.subtitulo,
    this.enabled = false,
    this.miniCompletada = false,
    this.intentosRestantes = 0,
    this.showAttempts = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const images = [
      'assets/images/mascota/refuerzo1.png',
      'assets/images/mascota/refuerzo2.png',
      'assets/images/mascota/refuerzo3.png',
    ];
    final imgPath = images[(titulo.hashCode.abs() % images.length)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    imgPath,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Color(0xFF1E2433),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showAttempts) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  miniCompletada
                      ? Icons.emoji_events_rounded
                      : (enabled ? Icons.timer_outlined : Icons.lock_clock),
                  size: 18,
                  color: enabled ? accent : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  miniCompletada
                      ? 'Mini lección completada'
                      : enabled
                          ? 'Intentos restantes: $intentosRestantes'
                          : 'Vuelve luego',
                  style: TextStyle(
                    color: enabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                showAttempts ? Icons.bolt : Icons.flag,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? accent : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: (!enabled || miniCompletada) ? null : onTap,
              label: Text(
                miniCompletada
                    ? 'Completado'
                    : (!enabled
                        ? 'Vuelve luego'
                        : (showAttempts
                            ? 'Prácticas dirigidas (${intentosRestantes} intentos)'
                            : 'Comenzar desafío')),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
