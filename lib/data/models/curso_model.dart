// lib/data/models/curso_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CursoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final int orden;

  CursoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.orden,
  });

  factory CursoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CursoModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      orden: data['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "descripcion": descripcion,
      "orden": orden,
    };
  }
}
