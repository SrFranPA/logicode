import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evaluacion_model.dart';

class EvaluacionesRepository {
  final FirebaseFirestore _db;

  EvaluacionesRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Registra el resultado de una evaluación (pre o post) para un usuario.
  ///
  /// - Crea un documento en usuarios/{uid}/evaluaciones
  /// - Actualiza los campos resumen en usuarios/{uid}:
  ///   pretest_estado, pretest_calificacion, ultima_evaluacion_pre
  ///   postest_estado, postest_calificacion, ultima_evaluacion_post
  Future<void> registrarEvaluacion({
    required String uid,
    required String tipo, // 'pre' | 'post'
    required int puntajeObtenido,
    required int puntajeMinimo,
    required int puntajeMaximo,
    required int numPreguntas,
    required List<String> bancoPreguntasIds,
    Map<String, dynamic>? detalle,
  }) async {
    final porcentaje = puntajeMaximo > 0
        ? (puntajeObtenido * 100.0 / puntajeMaximo)
        : 0.0;

    final ahora = DateTime.now();

    final evaluacion = Evaluacion(
      id: '',
      uid: uid,
      tipo: tipo,
      puntajeObtenido: puntajeObtenido,
      puntajeMinimo: puntajeMinimo,
      puntajeMaximo: puntajeMaximo,
      porcentaje: porcentaje,
      fecha: ahora,
      numPreguntas: numPreguntas,
      bancoPreguntasIds: bancoPreguntasIds,
      detalle: detalle,
    );

    final userRef = _db.collection('usuarios').doc(uid);
    final evalsRef = userRef.collection('evaluaciones').doc();

    final estado = porcentaje >= 70 ? 'aprobado' : 'reprobado'; // umbral ejemplo

    await _db.runTransaction((tx) async {
      tx.set(evalsRef, evaluacion.toJson());

      final resumen = <String, dynamic>{};

      if (tipo == 'pre') {
        resumen['pretest_estado'] = estado;
        resumen['pretest_calificacion'] = porcentaje;
        resumen['ultima_evaluacion_pre'] = Timestamp.fromDate(ahora);
      } else {
        resumen['postest_estado'] = estado;
        resumen['postest_calificacion'] = porcentaje;
        resumen['ultima_evaluacion_post'] = Timestamp.fromDate(ahora);
      }

      tx.update(userRef, resumen);
    });
  }
}
