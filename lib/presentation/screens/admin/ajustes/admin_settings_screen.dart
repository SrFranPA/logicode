import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _db = FirebaseFirestore.instance;

  bool _loadingSheet = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reportCard(),
              const SizedBox(height: 14),
              _globalAveragesCard(),
              const SizedBox(height: 14),
              _logoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D2034), Color(0xFF2E3050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Administra reportes y estilos de cursos desde un solo lugar.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD4B1).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB35C).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.table_chart, color: Color(0xFFCC6B1E)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Reportes de tests',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF3A2A1D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Diagnostico / Final',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF3A2A1D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Abre la tabla con los resultados de test diagnostico y finales de curso para revisar el desempeño.',
            style: TextStyle(
              color: Color(0xFF4B4F56),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<_DiagStats?>(
            future: _loadDiagStats(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(minHeight: 4),
                );
              }
              final stats = snap.data;
              if (stats == null) {
                return const SizedBox(height: 0);
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD4B1).withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    _statChip('Intentos', '${stats.count}'),
                    const SizedBox(width: 8),
                    _statChip('Promedio', '${stats.promedio.toStringAsFixed(1)}%'),
                    const SizedBox(width: 8),
                    _statChip('Mejor', '${stats.max.toStringAsFixed(1)}%'),
                    const SizedBox(width: 8),
                    _statChip('Peor', '${stats.min.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingSheet ? null : _openResultsScreen,
              icon: _loadingSheet
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.insights_rounded),
              label: const Text(
                'Detalle',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA200),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          'Cerrar sesion',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE57373),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openResultsScreen() async {
    setState(() => _loadingSheet = true);
    final cursosFuture = _db.collection('cursos').orderBy('orden').get();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdminTestResultsScreen(
          cursosFuture: cursosFuture,
          loadEvaluaciones: _loadEvaluaciones,
          loadPostVectorReport: _loadPostVectorReport,
        ),
      ),
    );
    if (mounted) setState(() => _loadingSheet = false);
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<List<_EvalRow>> _loadEvaluaciones({
    required String tipo,
    String? search,
    String? cursoFiltro,
    Map<String, String>? courseNames,
    Map<String, int>? courseOrders,
    bool includeNdForCurso = false,
  }) async {
    final List<_EvalRow> rows = [];
    final usersSnap = await _db.collection('usuarios').get();

    final searchTrim = search?.trim().toLowerCase() ?? '';

    for (final userDoc in usersSnap.docs) {
      final uid = userDoc.id;
      final userData = userDoc.data();
      final nombre = (userData['nombre'] ?? uid).toString();
      if (searchTrim.isNotEmpty && !nombre.toLowerCase().contains(searchTrim)) continue;

      final tipos = tipo == 'pre'
          ? ['pre', 'pretest']
          : ['post', 'postest', 'posttest'];
      final evalsSnap = await _db
          .collection('usuarios')
          .doc(uid)
          .collection('evaluaciones')
          .where('tipo', whereIn: tipos)
          .get();

      bool addedForCourse = false;
      for (final doc in evalsSnap.docs) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
        final obtenido = (data['puntaje_obtenido'] as num?)?.toInt() ?? 0;
        final maximo = (data['puntaje_maximo'] as num?)?.toInt() ?? 0;
        final porcentaje = (data['porcentaje'] as num?)?.toDouble() ?? 0.0;
        final detalle = (data['detalle'] as Map?)?.cast<String, dynamic>();
        final curso = (detalle?['cursoId'] ??
                detalle?['curso_id'] ??
                detalle?['curso'] ??
                detalle?['cursoNombre'] ??
                '')
            .toString();

        if (cursoFiltro != null && cursoFiltro.isNotEmpty && curso != cursoFiltro) {
          continue;
        }

        rows.add(_EvalRow(
          nombre: nombre,
          uid: uid,
          fecha: fecha,
          puntaje: obtenido,
          puntajeMax: maximo,
          porcentaje: porcentaje,
          curso: curso,
          isNd: false,
        ));
        addedForCourse = true;
      }

      if (tipo == 'pre' && evalsSnap.docs.isEmpty) {
        final pct = (userData['pretest_calificacion'] as num?)?.toDouble();
        if (pct != null) {
          rows.add(_EvalRow(
            nombre: nombre,
            uid: uid,
            fecha: DateTime.now(),
            puntaje: 0,
            puntajeMax: 0,
            porcentaje: pct,
            curso: '',
            puntajeTexto: 'N/D',
            porcentajeTexto: '${pct.toStringAsFixed(1)}%',
          ));
        }
      }

      if (tipo == 'post' &&
          includeNdForCurso &&
          cursoFiltro != null &&
          cursoFiltro.isNotEmpty &&
          !addedForCourse) {
        final orden = courseOrders?[cursoFiltro] ?? 0;
        final vector = (userData['postest_calificaciones'] as List?)
                ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
                .toList() ??
            [];
        final index = orden > 0 ? orden - 1 : -1;
        final valor = (index >= 0 && index < vector.length) ? vector[index] : 0.0;
        if (valor > 0) {
          rows.add(_EvalRow(
            nombre: nombre,
            uid: uid,
            fecha: DateTime.now(),
            puntaje: 0,
            puntajeMax: 0,
            porcentaje: valor,
            curso: cursoFiltro,
            cursoNombre: courseNames?[cursoFiltro],
            puntajeTexto: 'N/D',
            porcentajeTexto: '${valor.toStringAsFixed(1)}%',
          ));
        } else {
          rows.add(_EvalRow(
            nombre: nombre,
            uid: uid,
            fecha: DateTime.now(),
            puntaje: 0,
            puntajeMax: 0,
            porcentaje: -1,
            curso: cursoFiltro,
            isNd: true,
            cursoNombre: courseNames?[cursoFiltro],
          ));
        }
      }
    }

    rows.sort((a, b) => b.fecha.compareTo(a.fecha));
    return rows;
  }

  Future<List<_PostVectorRow>> _loadPostVectorReport({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos,
    String? search,
  }) async {
    final usersSnap = await _db.collection('usuarios').get();
    final searchTrim = search?.trim().toLowerCase() ?? '';
    final totalCursos = cursos.length;
    final List<_PostVectorRow> rows = [];

    for (final userDoc in usersSnap.docs) {
      final data = userDoc.data();
      final nombre = (data['nombre'] ?? userDoc.id).toString();
      if (searchTrim.isNotEmpty && !nombre.toLowerCase().contains(searchTrim)) continue;

      final pretestCompletado = data['pretest_completado'] != null;
      final pretestCal = (data['pretest_calificacion'] as num?)?.toDouble() ?? 0.0;
      if (!pretestCompletado && pretestCal <= 0) {
        continue;
      }

      final vector = (data['postest_calificaciones'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
              .toList() ??
          [];
      final List<double?> grades = List<double?>.filled(totalCursos, null);

      for (var i = 0; i < totalCursos; i++) {
        if (i < vector.length && vector[i] > 0) {
          grades[i] = vector[i];
        }
      }

      final valid = grades.whereType<double>().toList();
      final avg = valid.isEmpty ? null : valid.reduce((a, b) => a + b) / valid.length;

      rows.add(_PostVectorRow(
        nombre: nombre,
        grades: grades,
        promedio: avg,
      ));
    }

    rows.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return rows;
  }

  Future<_DiagStats?> _loadDiagStats() async {
    final usersSnap = await _db.collection('usuarios').get();
    int count = 0;
    double sum = 0;
    double max = -1;
    double min = 101;

    for (final userDoc in usersSnap.docs) {
      final uid = userDoc.id;
      final evalsSnap = await _db
          .collection('usuarios')
          .doc(uid)
          .collection('evaluaciones')
          .where('tipo', isEqualTo: 'pre')
          .get();

      for (final doc in evalsSnap.docs) {
        final data = doc.data();
        double pct = (data['porcentaje'] as num?)?.toDouble() ?? -1;
        if (pct < 0) {
          final obtenido = (data['puntaje_obtenido'] as num?)?.toDouble() ?? 0;
          final maximo = (data['puntaje_maximo'] as num?)?.toDouble() ?? 0;
          pct = maximo > 0 ? (obtenido * 100 / maximo) : 0;
        }
        count++;
        sum += pct;
        if (pct > max) max = pct;
        if (pct < min) min = pct;
      }
    }

    if (count == 0) return null;
    return _DiagStats(
      count: count,
      promedio: sum / count,
      max: max < 0 ? 0 : max,
      min: min > 100 ? 0 : min,
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4B1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B5E1A),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2A44),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<_GlobalAverages?> _loadGlobalAverages() async {
    final usersSnap = await _db.collection('usuarios').get();
    double sumPre = 0;
    int countPre = 0;
    double sumPost = 0;
    int countPost = 0;

    for (final doc in usersSnap.docs) {
      final data = doc.data();
      final pre = (data['pretest_calificacion'] as num?)?.toDouble();
      if (pre != null && pre > 0) {
        sumPre += pre;
        countPre++;
      }

      final vector = (data['postest_calificaciones'] as List?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
              .toList() ??
          [];
      for (final v in vector) {
        if (v > 0) {
          sumPost += v;
          countPost++;
        }
      }
    }

    if (countPre == 0 && countPost == 0) return null;
    return _GlobalAverages(
      promedioPre: countPre > 0 ? sumPre / countPre : null,
      promedioPost: countPost > 0 ? sumPost / countPost : null,
    );
  }

  Widget _globalAveragesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD4B1).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FutureBuilder<_GlobalAverages?>(
        future: _loadGlobalAverages(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator(minHeight: 4);
          }
          final avg = snap.data;
          if (avg == null) {
            return const SizedBox(height: 0);
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip(
                'Promedio diagnostico',
                avg.promedioPre == null ? '' : '${avg.promedioPre!.toStringAsFixed(1)}%',
              ),
              _statChip(
                'Promedio test final',
                avg.promedioPost == null ? '' : '${avg.promedioPost!.toStringAsFixed(1)}%',
              ),
            ],
          );
        },
      ),
    );
  }

}

class _EvalRow {
  final String nombre;
  final String uid;
  final DateTime fecha;
  final int puntaje;
  final int puntajeMax;
  final double porcentaje;
  final String curso;
  final bool isNd;
  final String? cursoNombre;
  final String? puntajeTexto;
  final String? porcentajeTexto;

  _EvalRow({
    required this.nombre,
    required this.uid,
    required this.fecha,
    required this.puntaje,
    required this.puntajeMax,
    required this.porcentaje,
    this.curso = '',
    this.isNd = false,
    this.cursoNombre,
    this.puntajeTexto,
    this.porcentajeTexto,
  });
}

class _EvaluacionesTable extends StatefulWidget {
  final Future<List<_EvalRow>> futureRows;
  final String emptyText;
  final bool showCurso;
  final Map<String, String>? courseNames;

  const _EvaluacionesTable({
    required this.futureRows,
    required this.emptyText,
    this.showCurso = false,
    this.courseNames,
  });

  @override
  State<_EvaluacionesTable> createState() => _EvaluacionesTableState();
}

class _EvaluacionesTableState extends State<_EvaluacionesTable>
    with AutomaticKeepAliveClientMixin<_EvaluacionesTable> {
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();
  Future<List<_EvalRow>>? _cachedFuture;

  @override
  void didUpdateWidget(covariant _EvaluacionesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureRows != widget.futureRows) {
      _cachedFuture = widget.futureRows;
    }
  }

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _cachedFuture ??= widget.futureRows;

    return FutureBuilder<List<_EvalRow>>(
      future: _cachedFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error al cargar reportes: ${snap.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          );
        }
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return Center(
            child: Text(
              widget.emptyText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          );
        }

        const nameWidth = 240.0;
        const noteWidth = 90.0;
        final totalWidth = nameWidth + noteWidth;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              controller: _hController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _hController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _diagHeaderRow(nameWidth, noteWidth),
                      const Divider(height: 1),
                      Expanded(
                        child: Scrollbar(
                          controller: _vController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _vController,
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final r = rows[index];
                              return _diagDataRow(r, nameWidth, noteWidth);
                            },
                          ),
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

  Widget _diagHeaderRow(double nameWidth, double noteWidth) {
    return Container(
      color: const Color(0xFFF4F6FB),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('Nombre', nameWidth, isHeader: true),
          _cell('Nota', noteWidth, isHeader: true),
        ],
      ),
    );
  }

  Widget _diagDataRow(_EvalRow r, double nameWidth, double noteWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: nameWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateStatic(r.fecha),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2026),
                  ),
                ),
              ],
            ),
          ),
          _cell(
            r.porcentajeTexto ?? (r.isNd ? 'N/D' : '${r.porcentaje.toStringAsFixed(1)}%'),
            noteWidth,
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, double width, {bool isHeader = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          color: const Color(0xFF1E2026),
        ),
      ),
    );
  }

  static String _formatDateStatic(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  @override
  bool get wantKeepAlive => true;
}

class _DiagStats {
  final int count;
  final double promedio;
  final double max;
  final double min;

  _DiagStats({
    required this.count,
    required this.promedio,
    required this.max,
    required this.min,
  });
}

class _GlobalAverages {
  final double? promedioPre;
  final double? promedioPost;

  _GlobalAverages({this.promedioPre, this.promedioPost});
}

class _PostVectorRow {
  final String nombre;
  final List<double?> grades;
  final double? promedio;

  _PostVectorRow({
    required this.nombre,
    required this.grades,
    required this.promedio,
  });
}

class _PostVectorTable extends StatefulWidget {
  final Future<List<_PostVectorRow>> futureRows;
  final String emptyText;
  final int totalCursos;

  const _PostVectorTable({
    required this.futureRows,
    required this.emptyText,
    required this.totalCursos,
  });

  @override
  State<_PostVectorTable> createState() => _PostVectorTableState();
}

class _PostVectorTableState extends State<_PostVectorTable>
    with AutomaticKeepAliveClientMixin<_PostVectorTable> {
  Future<List<_PostVectorRow>>? _cachedFuture;
  final ScrollController _hController = ScrollController();
  final ScrollController _vController = ScrollController();

  @override
  void didUpdateWidget(covariant _PostVectorTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureRows != widget.futureRows) {
      _cachedFuture = widget.futureRows;
    }
  }

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _cachedFuture ??= widget.futureRows;

    return FutureBuilder<List<_PostVectorRow>>(
      future: _cachedFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error al cargar reportes: ${snap.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          );
        }
        final rows = snap.data ?? [];
        if (rows.isEmpty) {
          return Center(
            child: Text(
              widget.emptyText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          );
        }

        const nameWidth = 180.0;
        const noteWidth = 90.0;
        const avgWidth = 110.0;
        final totalWidth = nameWidth + (widget.totalCursos * noteWidth) + avgWidth;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              controller: _hController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _hController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _postHeaderRow(nameWidth, noteWidth, avgWidth),
                      const Divider(height: 1),
                      Expanded(
                        child: Scrollbar(
                          controller: _vController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _vController,
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final r = rows[index];
                              return _postDataRow(
                                r,
                                nameWidth,
                                noteWidth,
                                avgWidth,
                              );
                            },
                          ),
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

  @override
  bool get wantKeepAlive => true;

  Widget _postHeaderRow(double nameWidth, double noteWidth, double avgWidth) {
    return Container(
      color: const Color(0xFFF4F6FB),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _cell('Nombre', nameWidth, isHeader: true),
          for (var i = 0; i < widget.totalCursos; i++)
            _cell('Nota ${i + 1}', noteWidth, isHeader: true),
          _cell('Promedio', avgWidth, isHeader: true),
        ],
      ),
    );
  }

  Widget _postDataRow(
    _PostVectorRow row,
    double nameWidth,
    double noteWidth,
    double avgWidth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _cell(row.nombre, nameWidth),
          ...row.grades.map(
            (g) => _cell(g == null ? '' : g.toStringAsFixed(1), noteWidth),
          ),
          _cell(row.promedio == null ? '' : row.promedio!.toStringAsFixed(1), avgWidth),
        ],
      ),
    );
  }

  Widget _cell(String text, double width, {bool isHeader = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          color: const Color(0xFF1E2026),
        ),
      ),
    );
  }
}

class _AdminTestResultsScreen extends StatefulWidget {
  final Future<QuerySnapshot<Map<String, dynamic>>> cursosFuture;
  final Future<List<_EvalRow>> Function({
    required String tipo,
    String? search,
    String? cursoFiltro,
    Map<String, String>? courseNames,
    Map<String, int>? courseOrders,
    bool includeNdForCurso,
  }) loadEvaluaciones;
  final Future<List<_PostVectorRow>> Function({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos,
    String? search,
  }) loadPostVectorReport;

  const _AdminTestResultsScreen({
    required this.cursosFuture,
    required this.loadEvaluaciones,
    required this.loadPostVectorReport,
  });

  @override
  State<_AdminTestResultsScreen> createState() => _AdminTestResultsScreenState();
}

class _AdminTestResultsScreenState extends State<_AdminTestResultsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  late final TabController _tabController;
  Future<List<_EvalRow>>? _diagFuture;
  Future<List<_PostVectorRow>>? _postFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2034),
        title: const Text('Detalle de reportes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: widget.cursosFuture,
        builder: (context, cursoSnap) {
          final cursos = cursoSnap.data?.docs ?? [];
          final cursoOrders = <String, int>{
            for (final c in cursos)
              c.id: (c.data()['orden'] as num?)?.toInt() ?? 0,
          };

          _ensureActiveFuture(cursos, cursoOrders);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar estudiante...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _onSearchChanged(v, cursos, cursoOrders),
                      ),
                      const SizedBox(height: 12),
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1E2026),
                        unselectedLabelColor: const Color(0xFF7C8391),
                        indicatorColor: const Color(0xFF6A7FDB),
                        tabs: const [
                          Tab(text: 'Diagnostico'),
                          Tab(text: 'Test final'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EvaluacionesTable(
                          futureRows: _diagFuture ?? Future.value([]),
                          emptyText: 'No hay resultados de diagnostico.',
                        ),
                        _PostVectorTable(
                          futureRows: _postFuture ?? Future.value([]),
                          emptyText: 'No hay resultados de test final.',
                          totalCursos: cursos.length,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ensureActiveFuture(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos,
    Map<String, int> cursoOrders,
  ) {
    if (_tabController.index == 0) {
      _diagFuture ??= widget.loadEvaluaciones(
        tipo: 'pre',
        search: _search,
        cursoFiltro: null,
        courseOrders: cursoOrders,
      );
    } else {
      _postFuture ??= widget.loadPostVectorReport(
        cursos: cursos,
        search: _search,
      );
    }
  }

  void _onSearchChanged(
    String value,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> cursos,
    Map<String, int> cursoOrders,
  ) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim().toLowerCase();
        _diagFuture = null;
        _postFuture = null;
      });
    });
  }
}
