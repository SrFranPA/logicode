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

  /// PRETEST: obtener 10 preguntas MUY DIFÍCILES de TODOS los cursos
  Future<List<Pregunta>> cargarPreguntasPretest() async {
    final snap = await db
        .collection("banco_preguntas")
        .where("dificultad", isEqualTo: "Muy difícil")
        .limit(10)
        .get();

    return snap.docs.map((e) => Pregunta.fromDoc(e)).toList();
  }
}
