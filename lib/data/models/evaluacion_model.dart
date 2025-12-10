import 'package:cloud_firestore/cloud_firestore.dart';

class Evaluacion {
  final String id;
  final String uid;
  final String tipo; // 'pre' | 'post'
  final int puntajeObtenido;
  final int puntajeMinimo;
  final int puntajeMaximo;
  final double porcentaje;
  final DateTime fecha;
  final int numPreguntas;
  final List<String> bancoPreguntasIds;
  final Map<String, dynamic>? detalle;

  Evaluacion({
    required this.id,
    required this.uid,
    required this.tipo,
    required this.puntajeObtenido,
    required this.puntajeMinimo,
    required this.puntajeMaximo,
    required this.porcentaje,
    required this.fecha,
    required this.numPreguntas,
    required this.bancoPreguntasIds,
    this.detalle,
  });

  factory Evaluacion.fromFirestore(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Evaluacion(
      id: doc.id,
      uid: uid,
      tipo: (data['tipo'] ?? 'pre').toString(),
      puntajeObtenido: (data['puntaje_obtenido'] as num?)?.toInt() ?? 0,
      puntajeMinimo: (data['puntaje_minimo'] as num?)?.toInt() ?? 0,
      puntajeMaximo: (data['puntaje_maximo'] as num?)?.toInt() ?? 0,
      porcentaje: (data['porcentaje'] as num?)?.toDouble() ?? 0,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numPreguntas: (data['num_preguntas'] as num?)?.toInt() ?? 0,
      bancoPreguntasIds:
          (data['banco_preguntas_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      detalle: (data['detalle'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'puntaje_obtenido': puntajeObtenido,
      'puntaje_minimo': puntajeMinimo,
      'puntaje_maximo': puntajeMaximo,
      'porcentaje': porcentaje,
      'fecha': Timestamp.fromDate(fecha),
      'num_preguntas': numPreguntas,
      'banco_preguntas_ids': bancoPreguntasIds,
      if (detalle != null) 'detalle': detalle,
    };
  }
}
