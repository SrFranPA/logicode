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

      /// PRETEST: seleccionar 10 preguntas solo de nivel medio,
  /// asegurando al menos 1 por curso cuando exista.
  Future<List<Pregunta>> cargarPreguntasPretest() async {
    final snap = await db
        .collection("banco_preguntas")
        .orderBy("fecha_creacion", descending: true)
        .limit(400)
        .get();

    final all = snap.docs.map((e) => Pregunta.fromDoc(e)).toList();
    if (all.isEmpty) return [];

    String _normalize(String text) {
      return text
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');
    }

    bool _esMedio(String? dif) {
      final d = _normalize(dif ?? "");
      return d.contains("medio") || d.contains("media") || d.contains("intermedio");
    }

    final medio = all.where((p) => _esMedio(p.dificultad)).toList();
    if (medio.isEmpty) return [];

    final byCurso = <String, List<Pregunta>>{};
    for (final p in medio) {
      byCurso.putIfAbsent(p.cursoId, () => []).add(p);
    }

    final seleccion = <Pregunta>[];
    final cursos = byCurso.keys.toList();
    cursos.shuffle();
    final cursosSeleccionados = cursos.take(10).toList();

    // Tomar una por curso (nivel medio) cuando exista
    for (final cursoId in cursosSeleccionados) {
      final list = byCurso[cursoId] ?? [];
      if (list.isEmpty) continue;
      list.shuffle();
      seleccion.add(list.first);
    }

    if (seleccion.length < 10) {
      // Rellenar hasta 10 con el resto de nivel medio
      final resto = medio.where((p) => !seleccion.any((s) => s.id == p.id)).toList();
      resto.shuffle();
      for (final p in resto) {
        if (seleccion.length >= 10) break;
        seleccion.add(p);
      }
    }

    seleccion.shuffle();
    return seleccion;
  }
}


