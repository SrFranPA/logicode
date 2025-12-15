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

  /// PRETEST: obtener hasta 10 preguntas; si hay muy difíciles las prioriza, si no, toma cualquieras
  Future<List<Pregunta>> cargarPreguntasPretest() async {
    // Intentar traer preguntas "Muy dificil" (texto normalizado)
    final snapDificil = await db
        .collection("banco_preguntas")
        .where("dificultad", isEqualTo: "Muy dificil")
        .limit(50)
        .get();

    List<Pregunta> candidatas = snapDificil.docs.map((e) => Pregunta.fromDoc(e)).toList();

    // Si no hay suficientes, traer otras cualquiera para rellenar
    if (candidatas.length < 10) {
      final snapTodas = await db
          .collection("banco_preguntas")
          .orderBy("fecha_creacion", descending: true)
          .limit(200)
          .get();
      final todas = snapTodas.docs.map((e) => Pregunta.fromDoc(e)).toList();
      // evitar duplicados por id
      final ids = candidatas.map((p) => p.id).toSet();
      for (final p in todas) {
        if (ids.contains(p.id)) continue;
        candidatas.add(p);
      }
    }

    candidatas.shuffle();
    if (candidatas.length > 10) {
      return candidatas.sublist(0, 10);
    }
    return candidatas;
  }
}
