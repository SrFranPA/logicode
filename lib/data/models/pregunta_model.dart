// lib/data/models/pregunta_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Pregunta {
  final String id;
  final String cursoId;
  final String tipo;        // chip_select, drag_drop, fill_blank
  final String dificultad;  // Muy fácil, Fácil, ...
  final String enunciado;
  final Map<String, dynamic> contenido;
  final DateTime fechaCreacion;
  final String? archivoUrl;

  Pregunta({
    required this.id,
    required this.cursoId,
    required this.tipo,
    required this.dificultad,
    required this.enunciado,
    required this.contenido,
    required this.fechaCreacion,
    this.archivoUrl,
  });

  factory Pregunta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pregunta(
      id: doc.id,
      cursoId: data['cursoId'] ?? '',
      tipo: data['tipo'] ?? '',
      dificultad: data['dificultad'] ?? '',
      enunciado: data['enunciado'] ?? '',
      contenido: Map<String, dynamic>.from(data['contenido'] ?? {}),
      fechaCreacion: (data['fecha_creacion'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      archivoUrl: data['archivo_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cursoId': cursoId,
      'tipo': tipo,
      'dificultad': dificultad,
      'enunciado': enunciado,
      'contenido': contenido,
      'fecha_creacion': Timestamp.fromDate(fechaCreacion),
      'archivo_url': archivoUrl,
    };
  }
}
