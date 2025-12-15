import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pregunta_model.dart';

class PreguntaRepository {
  final FirebaseFirestore db;

  PreguntaRepository(this.db);

  Stream<List<Pregunta>> watchPreguntas() {
    return db
        .collection("banco_preguntas")
        .orderBy("fecha_creacion", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Pregunta.fromDoc(doc)).toList(),
        );
  }

  Future<String> createPregunta({
    required String cursoId,
    required String tipo,
    required String dificultad,
  }) async {
    final now = DateTime.now();

    final ref = await db.collection("banco_preguntas").add({
      "cursoId": cursoId,
      "tipo": tipo,
      "dificultad": dificultad,
      "enunciado": "",
      "fecha_creacion": now,
      "archivo_url": "",
    });

    return ref.id;
  }

  Future<void> deletePregunta(String id) async {
    await db.collection("banco_preguntas").doc(id).delete();
  }

  /// PRETEST: seleccionar hasta 10 preguntas aleatorias priorizando 1 por curso (si existe)
  Future<List<Pregunta>> cargarPreguntasPretest() async {
    final snap = await db
        .collection("banco_preguntas")
        .orderBy("fecha_creacion", descending: true)
        .limit(400)
        .get();

    final all = snap.docs.map((e) => Pregunta.fromDoc(e)).toList();
    if (all.isEmpty) return [];

    int _score(String? dif) {
      final d = (dif ?? "").toLowerCase();
      if (d.contains("muy dificil")) return 5;
      if (d.contains("dificil")) return 4;
      if (d.contains("medio")) return 3;
      if (d.contains("facil")) return 2;
      return 1;
    }

    final byCurso = <String, List<Pregunta>>{};
    for (final p in all) {
      byCurso.putIfAbsent(p.cursoId, () => []).add(p);
    }

    final seleccion = <Pregunta>[];

    // Tomar una por curso, priorizando dificultad alta y variando orden
    for (final list in byCurso.values) {
      list.sort((a, b) => _score(b.dificultad).compareTo(_score(a.dificultad)));
      list.shuffle();
      list.sort((a, b) => _score(b.dificultad).compareTo(_score(a.dificultad)));
      seleccion.add(list.first);
      if (seleccion.length >= 10) break; // si hay más de 10 cursos, cortamos en 10
    }

    // Rellenar hasta 10 con el resto más difíciles
    final resto = all.where((p) => !seleccion.any((s) => s.id == p.id)).toList();
    resto.sort((a, b) => _score(b.dificultad).compareTo(_score(a.dificultad)));
    resto.shuffle();
    for (final p in resto) {
      if (seleccion.length >= 10) break;
      seleccion.add(p);
    }

    seleccion.shuffle();
    return seleccion;
  }
}
