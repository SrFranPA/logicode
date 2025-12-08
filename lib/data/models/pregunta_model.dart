// lib/data/models/pregunta_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pregunta {
  final String id;
  final String cursoId;
  final String tipo;
  final String dificultad;
  final String enunciado;
  final String? archivoUrl;
  final DateTime fechaCreacion;

  Pregunta({
    required this.id,
    required this.cursoId,
    required this.tipo,
    required this.dificultad,
    required this.enunciado,
    required this.fechaCreacion,
    required this.archivoUrl,
  });

  factory Pregunta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Pregunta(
      id: doc.id,
      cursoId: data['cursoId'] ?? '',
      tipo: data['tipo'] ?? '',
      dificultad: data['dificultad'] ?? '',
      enunciado: data['enunciado'] ?? '',
      archivoUrl: data['archivo_url'],
      fechaCreacion:
          (data['fecha_creacion'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cursoId': cursoId,
      'tipo': tipo,
      'dificultad': dificultad,
      'enunciado': enunciado,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'archivo_url': archivoUrl,
    };
  }
}
