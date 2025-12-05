import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso_model.dart';

class CursoRepository {
  final FirebaseFirestore db;
  CursoRepository(this.db);

  Stream<List<CursoModel>> watchCursos() {
    return db
        .collection("cursos")
        .orderBy("orden")
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CursoModel.fromFirestore(d)).toList());
  }

  Future<void> createCurso(CursoModel curso) async {
    await db.collection("cursos").doc(curso.id).set(
      curso.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> updateCurso(CursoModel curso) async {
    await db.collection("cursos").doc(curso.id).set(
      curso.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCurso(String id) async {
    await db.collection("cursos").doc(id).delete();
  }
}
