// lib/data/models/pregunta_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Pregunta {
  final String id;
  final String cursoId;
  final String dificultad;
  final String enunciado;
  final String tipo;
  final DateTime fechaCreacion;
  final String archivoUrl;        // JSON STRING ORIGINAL

  // Parsed JSON (opcional)
  final Map<String, dynamic>? dataParsed;

  Pregunta({
    required this.id,
    required this.cursoId,
    required this.dificultad,
    required this.enunciado,
    required this.tipo,
    required this.fechaCreacion,
    required this.archivoUrl,
    this.dataParsed,
  });

  factory Pregunta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final archivo = data["archivo_url"] ?? "";
    Map<String, dynamic>? parse;

    try {
      parse = jsonDecode(archivo);
    } catch (_) {
      parse = null;
    }

    return Pregunta(
      id: doc.id,
      cursoId: data["cursoId"] ?? "",
      dificultad: data["dificultad"] ?? "",
      enunciado: data["enunciado"] ?? "",
      tipo: data["tipo"] ?? "",
      fechaCreacion:
          (data["fecha_creacion"] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      archivoUrl: archivo,
      dataParsed: parse,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "cursoId": cursoId,
      "dificultad": dificultad,
      "enunciado": enunciado,
      "tipo": tipo,
      "fecha_creacion": Timestamp.fromDate(fechaCreacion),
      "archivo_url": archivoUrl,
    };
  }
}
