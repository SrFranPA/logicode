// lib/data/repositories/pregunta_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pregunta_model.dart';

class PreguntaRepository {
  final FirebaseFirestore _db;

  PreguntaRepository(this._db);

  Stream<List<Pregunta>> watchPreguntas() {
    return _db
        .collection('banco_preguntas')
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Pregunta.fromDoc(d)).toList());
  }

  Future<String> createPregunta({
    required String cursoId,
    required String tipo,
    required String dificultad,
  }) async {
    final ref = await _db.collection('banco_preguntas').add({
      'cursoId': cursoId,
      'tipo': tipo,
      'dificultad': dificultad,
      'enunciado': '',
      'contenido': {},
      'fecha_creacion': DateTime.now(),
      'archivo_url': null,
    });

    return ref.id;
  }

  Future<void> deletePregunta(String id) async {
    await _db.collection('banco_preguntas').doc(id).delete();
  }
}
